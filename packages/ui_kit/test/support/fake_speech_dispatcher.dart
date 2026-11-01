import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Waits for [condition], letting real socket traffic arrive in the meantime.
Future<void> pumpUntil(bool Function() condition) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition never held');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

/// A scripted Speech Dispatcher on loopback TCP, speaking real SSIP bytes.
///
/// TCP rather than the real Unix socket because Dart has no Unix sockets on
/// Windows, and the suite has to run there. Everything above the socket is the
/// genuine article, so what a test asserts is what a daemon would receive.
///
/// Out of the box it answers the way the SSIP manual documents. A test changes
/// that with [replyTo] and [ignore], and plays the daemon's own initiative
/// (a word ending, a reply arriving in pieces) with [send] and [sendPieces].
final class FakeSpeechDispatcher {
  FakeSpeechDispatcher._(this._server) {
    _server.listen(_accept);
  }

  /// Starts a daemon on a free loopback port.
  static Future<FakeSpeechDispatcher> start() async {
    return FakeSpeechDispatcher._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
  }

  final ServerSocket _server;
  final List<Socket> _connections = <Socket>[];
  final Map<String, String> _scriptedReplies = <String, String>{};
  final Set<String> _ignored = <String>{};

  /// Every line received, in order: commands, text lines and the closing dot.
  final List<String> received = <String>[];

  /// The ids of the messages queued so far, oldest first.
  final List<int> queuedMessages = <int>[];

  /// Sent with the "message queued" reply in the same write, as a daemon whose
  /// word was over at once could. Takes the message id.
  String Function(int id)? sentWithQueuedReply;

  int _nextMessageId = 41;
  bool _readingText = false;

  /// What the client under test passes as its connector.
  Future<Socket> connect() {
    return Socket.connect(InternetAddress.loopbackIPv4, _server.port);
  }

  /// Every byte received, exactly as it came off the socket.
  Uint8List get bytes => _bytes.toBytes();
  final BytesBuilder _bytes = BytesBuilder(copy: true);

  /// The commands received, without the text lines of any message.
  List<String> get commands => List<String>.unmodifiable(_commands);
  final List<String> _commands = <String>[];

  /// Answers commands starting with [prefix] with [rawReply] instead of the
  /// documented reply. [rawReply] is sent as it stands, line ends included.
  void replyTo(String prefix, String rawReply) {
    _scriptedReplies[prefix] = rawReply;
  }

  /// Never answers commands starting with [prefix].
  void ignore(String prefix) {
    _ignored.add(prefix);
  }

  /// Sends [raw] on the newest connection, as one write.
  void send(String raw) {
    _connections.last.add(utf8.encode(raw));
  }

  /// Sends [pieces] on the newest connection, each one reaching the client
  /// before the next leaves.
  Future<void> sendPieces(List<List<int>> pieces) async {
    for (final List<int> piece in pieces) {
      _connections.last.add(piece);
      await _connections.last.flush();
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// The bytes of a report that message [id] was said to its end.
  static String endReport(int id) => '702-$id\r\n702-1\r\n702 END\r\n';

  /// Reports that message [id] was said to its end.
  void sendEnd(int id) => send(endReport(id));

  /// Reports that message [id] was cancelled.
  void sendCanceled(int id) => send('703-$id\r\n703-1\r\n703 CANCELED\r\n');

  /// Completes once a line equal to [line] has been received.
  Future<void> untilReceived(String line) {
    return pumpUntil(() => received.contains(line));
  }

  /// Completes once [count] commands starting with [prefix] have been
  /// received.
  Future<void> untilCommands(String prefix, int count) {
    return pumpUntil(() {
      return commands.where((String c) => c.startsWith(prefix)).length >= count;
    });
  }

  /// Completes once [count] messages have been queued, returning the newest.
  Future<int> untilQueued(int count) async {
    await pumpUntil(() => queuedMessages.length >= count);
    return queuedMessages[count - 1];
  }

  /// Shuts the daemon down and drops every connection.
  Future<void> close() async {
    for (final Socket connection in _connections) {
      connection.destroy();
    }
    await _server.close();
  }

  void _accept(Socket connection) {
    _connections.add(connection);
    final List<int> line = <int>[];
    connection.listen((Uint8List chunk) {
      _bytes.add(chunk);
      for (final int byte in chunk) {
        line.add(byte);
        final int end = line.length;
        if (end >= 2 && line[end - 2] == 13 && line[end - 1] == 10) {
          // Strict on purpose: bytes that are not UTF-8 fail the test here.
          _handle(connection, utf8.decode(line.sublist(0, end - 2)));
          line.clear();
        }
      }
    }, onError: (Object _) {});
    unawaited(connection.done.then<void>((_) {}, onError: (Object _) {}));
  }

  void _handle(Socket connection, String line) {
    received.add(line);
    if (_readingText) {
      if (line == '.') {
        _readingText = false;
        final int id = _nextMessageId++;
        queuedMessages.add(id);
        final String extra = sentWithQueuedReply?.call(id) ?? '';
        connection.add(
          utf8.encode('225-$id\r\n225 OK MESSAGE QUEUED\r\n$extra'),
        );
      }
    } else {
      _commands.add(line);
      _answer(connection, line);
    }
  }

  void _answer(Socket connection, String command) {
    if (_ignored.any(command.startsWith)) {
      return;
    }
    for (final MapEntry<String, String> scripted in _scriptedReplies.entries) {
      if (command.startsWith(scripted.key)) {
        connection.add(utf8.encode(scripted.value));
        return;
      }
    }
    if (command == 'SPEAK') {
      _readingText = true;
    }
    connection.add(utf8.encode(_documentedReply(command)));
  }

  static String _documentedReply(String command) {
    final List<String> words = command.split(' ');
    return switch ((words.first, words.length > 2 ? words[2] : '')) {
      ('SPEAK', _) => '230 OK RECEIVING DATA\r\n',
      ('CANCEL', _) => '210 OK CANCELED\r\n',
      ('SET', 'CLIENT_NAME') => '208 OK CLIENT NAME SET\r\n',
      ('SET', 'NOTIFICATION') => '220 OK NOTIFICATION SET\r\n',
      ('SET', 'PRIORITY') => '202 OK PRIORITY SET\r\n',
      ('SET', 'OUTPUT_MODULE') => '216 OK OUTPUT MODULE SET\r\n',
      ('SET', 'LANGUAGE') => '201 OK LANGUAGE SET\r\n',
      ('SET', 'SYNTHESIS_VOICE') => '209 OK VOICE SET\r\n',
      ('SET', 'RATE') => '203 OK RATE SET\r\n',
      _ => '300 ERROR UNKNOWN COMMAND\r\n',
    };
  }
}
