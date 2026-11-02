import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:learn_anywhere_core/core.dart';

/// Opens a socket to Speech Dispatcher. Injected, so tests can reach a fake
/// daemon over loopback TCP where the real one is on a Unix socket.
typedef SsipConnector = Future<Socket> Function();

/// Connects to the service of the user running this program.
///
/// Throws when there is nothing to connect to, which on a host without Unix
/// sockets is every time.
Future<Socket> connectToSpeechDispatcher() {
  final String? path = speechDispatcherSocketPath(Platform.environment);
  if (path == null) {
    throw const SsipException('The environment names no socket directory');
  }
  return Socket.connect(
    InternetAddress(path, type: InternetAddressType.unix),
    0,
  );
}

/// Speech Dispatcher could not be reached, or did not do what was asked.
final class SsipException implements Exception {
  /// Creates an exception saying what went wrong.
  const SsipException(this.message);

  /// What went wrong, for the diagnostic's log.
  final String message;

  @override
  String toString() => 'SsipException: $message';
}

/// How a message left the daemon's queue.
enum SsipEventKind {
  /// Said to its end.
  ended,

  /// Stopped, or dropped before it was said.
  canceled,
}

/// The daemon reporting, on its own initiative, what became of a message.
final class SsipEvent {
  /// Creates an event.
  const SsipEvent(this.messageId, this.kind);

  /// The id the daemon gave the message when it was queued.
  final int messageId;

  /// What became of it.
  final SsipEventKind kind;

  @override
  String toString() => 'SsipEvent($messageId, ${kind.name})';
}

/// The daemon's answer to one command.
final class SsipReply {
  /// Creates a reply.
  const SsipReply(this.code, this.lines, this.text);

  /// The three-digit status code.
  final int code;

  /// The data of every `ddd-data` line, in order.
  final List<String> lines;

  /// The text of the final `ddd text` line.
  final String text;

  /// Whether the command worked. Judged by class because the exact code
  /// differs from command to command.
  bool get isSuccess => code >= 200 && code < 300;

  @override
  String toString() => '$code $text';
}

/// A connection to Speech Dispatcher, speaking SSIP over a socket.
///
/// The protocol and nothing else: it knows nothing of voices, utterances or
/// what any of it is for, and needs no Flutter, so a plain `dart run` tool can
/// drive it. SSIP answers one command at a time, and a reply carries nothing
/// saying which command it belongs to, so commands are sent strictly one after
/// another and a command that goes unanswered ends the connection: its late
/// reply could otherwise only be taken for the next command's.
final class SsipClient {
  SsipClient._(this._socket, this._commandTimeout, this._onTraffic) {
    _socket
        .cast<List<int>>()
        // A name the daemon spells badly must not end the conversation.
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          _lineArrived,
          onError: (Object _) => _shutDown('The connection failed'),
          onDone: () => _shutDown('The daemon closed the connection'),
        );
    // A write to a socket the daemon has just closed fails here, and the
    // stream above has already reported that.
    unawaited(_socket.done.then<void>((_) {}, onError: (Object _) {}));
  }

  /// Connects through [connect] and runs the handshake.
  ///
  /// Throws an [SsipException] if the daemon refuses any of it: a client the
  /// daemon will not report message ends to could never tell when a word is
  /// over. [onTraffic] receives every line sent and received, for the
  /// diagnostic.
  static Future<SsipClient> open(
    SsipConnector connect, {
    Duration commandTimeout = defaultCommandTimeout,
    void Function(String line)? onTraffic,
  }) async {
    final SsipClient client = SsipClient._(
      await connect(),
      commandTimeout,
      onTraffic,
    );
    try {
      for (final String command in _handshake) {
        await client.require(command);
      }
    } on SsipException {
      client.close();
      rethrow;
    }
    return client;
  }

  /// How long a command may go unanswered. Long, because a daemon may be
  /// loading a speech module, and nothing waits on it but the word itself.
  static const Duration defaultCommandTimeout = Duration(seconds: 10);

  /// Who this client is, what it wants reported, and that its speech queues
  /// behind other applications' rather than interrupting them.
  static const List<String> _handshake = <String>[
    'SET self CLIENT_NAME learner:learn-anywhere:speech',
    'SET self NOTIFICATION end on',
    'SET self NOTIFICATION cancel on',
    'SET self PRIORITY message',
  ];

  /// A line of a reply: three digits, `-` when more follow or a space on the
  /// last one, and the text.
  static final RegExp _replyLine = RegExp(r'^(\d{3})([- ])(.*)$');

  static const int _eventEnded = 702;
  static const int _eventCanceled = 703;

  final Socket _socket;
  final Duration _commandTimeout;
  final void Function(String line)? _onTraffic;
  final StreamController<SsipEvent> _events =
      StreamController<SsipEvent>.broadcast(sync: true);

  /// The end of the queue of commands, which the next one waits for.
  Future<void> _lastCommand = Future<void>.value();

  /// The answer being waited for, if any.
  Completer<SsipReply>? _pending;

  /// Data lines of the reply being received.
  final List<String> _replyData = <String>[];

  /// Data lines of the event being received. Kept apart from [_replyData]
  /// because the daemon reports events from another thread than it answers
  /// commands, so nothing says the two arrive in separate blocks.
  final List<String> _eventData = <String>[];

  /// Why this client can no longer be used, once it cannot.
  String? _closedBecause;

  /// What became of each message, as the daemon reports it.
  ///
  /// Ends when the connection does, however it ends: dropped by the daemon,
  /// closed after a command went unanswered, or closed by [close].
  Stream<SsipEvent> get events => _events.stream;

  /// Sends [command] and waits for the reply, however it reads.
  ///
  /// A refusal is an ordinary reply, for the caller to judge through
  /// [SsipReply.isSuccess]. Throws an [SsipException] only when no reply came:
  /// the daemon stayed silent past the timeout, or the connection is gone.
  Future<SsipReply> command(String command) {
    return _inTurn(() => _exchange('$command\r\n'));
  }

  /// Sends [command], for when a refusal is as much a failure as no reply:
  /// throws an [SsipException] for either.
  Future<void> require(String command) async {
    final SsipReply reply = await this.command(command);
    if (!reply.isSuccess) {
      throw SsipException('"$command" was refused: $reply');
    }
  }

  /// Queues [text] and returns the id the daemon gave it.
  ///
  /// One turn from `SPEAK` to the reply, since any command sent in between
  /// would be read as part of the text. Throws an [SsipException] if the
  /// daemon does not take the text.
  Future<int> speak(String text) {
    return _inTurn(() async {
      final SsipReply goAhead = await _exchange('SPEAK\r\n');
      if (!goAhead.isSuccess) {
        throw SsipException('SPEAK was refused: $goAhead');
      }
      final SsipReply queued = await _exchange(_framed(text));
      final int? id = queued.isSuccess && queued.lines.isNotEmpty
          ? int.tryParse(queued.lines.first)
          : null;
      if (id == null) {
        throw SsipException('The text was not queued: $queued');
      }
      return id;
    });
  }

  /// Ends the connection. Whatever is still waiting fails.
  void close() => _shutDown('The connection was closed');

  /// Runs [step] once everything before it is over, however that went.
  Future<T> _inTurn<T>(Future<T> Function() step) {
    final Future<T> result = _lastCommand.then((_) => step());
    _lastCommand = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<SsipReply> _exchange(String wire) async {
    final String? closedBecause = _closedBecause;
    if (closedBecause != null) {
      throw SsipException(closedBecause);
    }
    final Completer<SsipReply> pending = Completer<SsipReply>();
    _pending = pending;
    _onTraffic?.call('> ${wire.trimRight()}');
    _socket.add(utf8.encode(wire));
    try {
      return await pending.future.timeout(_commandTimeout);
    } on TimeoutException {
      final String reason = 'No reply to "${wire.trimRight()}"';
      _shutDown(reason);
      throw SsipException(reason);
    }
  }

  /// [text] as SSIP wants it: line breaks as CRLF, a dot doubled where it
  /// starts a line, and a lone dot to end it.
  static String _framed(String text) {
    final StringBuffer framed = StringBuffer();
    for (final String line in const LineSplitter().convert(text)) {
      framed.write(line.startsWith('.') ? '.$line\r\n' : '$line\r\n');
    }
    framed.write('.\r\n');
    return framed.toString();
  }

  void _lineArrived(String line) {
    _onTraffic?.call('< $line');
    final Match? match = _replyLine.firstMatch(line);
    if (match == null) {
      return;
    }
    final int code = int.parse(match[1]!);
    final bool last = match[2] == ' ';
    final String text = match[3]!;
    final bool event = code >= 700 && code < 800;
    final List<String> data = event ? _eventData : _replyData;
    if (!last) {
      data.add(text);
      return;
    }
    final List<String> lines = List<String>.of(data);
    data.clear();
    if (event) {
      _publishEvent(code, lines);
    } else {
      final Completer<SsipReply>? pending = _pending;
      _pending = null;
      pending?.complete(SsipReply(code, lines, text));
    }
  }

  /// Passes on the two reports anything here listens for. The first data line
  /// of an event is the message id.
  void _publishEvent(int code, List<String> lines) {
    final SsipEventKind? kind = switch (code) {
      _eventEnded => SsipEventKind.ended,
      _eventCanceled => SsipEventKind.canceled,
      _ => null,
    };
    final int? id = lines.isEmpty ? null : int.tryParse(lines.first);
    if (kind != null && id != null && _closedBecause == null) {
      _events.add(SsipEvent(id, kind));
    }
  }

  void _shutDown(String reason) {
    if (_closedBecause != null) {
      return;
    }
    _closedBecause = reason;
    _socket.destroy();
    final Completer<SsipReply>? pending = _pending;
    _pending = null;
    pending?.completeError(SsipException(reason));
    unawaited(_events.close());
  }
}
