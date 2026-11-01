import 'dart:async';
import 'dart:io';

import 'package:learn_anywhere_core/core.dart';

import 'ssip_client.dart';

/// Speaks through Speech Dispatcher, the Linux desktop's own speech service.
///
/// Shaped after `FlutterTtsEngine`: one current request, a new one replaces
/// it, and [speak] does not return before the word is over, which is what lets
/// a caller say two answer fields in order. What to say and in which voice was
/// already decided by the pure policy in core.
///
/// [SpeechUtterance.leadIn] is ignored: nothing has shown that a Linux output
/// needs waking.
final class SpeechDispatcherEngine implements TtsEngine {
  /// Creates an engine that reaches the service through [connect].
  ///
  /// Nothing connects until the first word. [utteranceLimit] exists for tests;
  /// anything else leaves it at [defaultUtteranceLimit].
  SpeechDispatcherEngine({
    SsipConnector connect = connectToSpeechDispatcher,
    Duration utteranceLimit = defaultUtteranceLimit,
  }) : _connect = connect,
       _utteranceLimit = utteranceLimit;

  /// How long an utterance may run before it is given up on.
  ///
  /// Purely insurance: a daemon that never reports an end would otherwise
  /// leave the rest of a multi-field answer unsaid until something else stops
  /// speech. Longer than any single field read at the slowest rate.
  static const Duration defaultUtteranceLimit = Duration(seconds: 60);

  final SsipConnector _connect;
  final Duration _utteranceLimit;

  /// The connection, once one was asked for. Held as a future so that two
  /// words arriving together share one connection.
  Future<SsipClient?>? _connection;

  /// The utterance being said, or null when it is saying nothing.
  _SpokenRequest? _current;

  @override
  bool get isAvailable => true;

  // Listing voices is the next ticket; until then there is nothing to choose.
  @override
  Future<List<SpeechVoice>> voices() async => const <SpeechVoice>[];

  @override
  Future<void> speak(SpeechUtterance utterance) async {
    final SpeechVoice? voice = utterance.voice;
    if (voice == null || utterance.text.isEmpty) {
      return;
    }
    // Claimed before the first await, so a request arriving while this one is
    // still being set up wins and this one gives up. Whoever was waiting on
    // the utterance being replaced stops waiting here.
    final _SpokenRequest request = _SpokenRequest();
    _current?.finish();
    _current = request;
    try {
      if (await _queue(request, utterance, voice)) {
        await request.done.timeout(_utteranceLimit);
      }
    } on TimeoutException {
      // A daemon that reported no end. Nothing is broken and nothing is said
      // about it; the next utterance simply goes ahead.
    } on SsipException {
      // Speech is presentation and nothing else: a failing service must leave
      // the learner in a working session, and the worst case is silence.
    } finally {
      if (identical(_current, request)) {
        _current = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    final _SpokenRequest? request = _current;
    _current = null;
    try {
      // Never opens one: without a connection there is nothing to stop. Only
      // ever `self`, since `all` would silence a screen reader as well.
      final SsipClient? client = await _connection;
      await client?.command(_cancelOwnSpeech);
    } on SsipException {
      // Nothing left to stop, then.
    } finally {
      // Not left to the daemon's own cancel report: with nothing queued there
      // is none, and a caller would be left waiting on silence.
      request?.finish();
    }
  }

  static const String _cancelOwnSpeech = 'CANCEL self';

  /// Hands [utterance] to the daemon, returning whether it took it.
  ///
  /// False when there is no service, or when a newer request took over. The
  /// message that newer request may find already queued is cut off by its own
  /// cancel, which the client sends after anything sent here.
  Future<bool> _queue(
    _SpokenRequest request,
    SpeechUtterance utterance,
    SpeechVoice voice,
  ) async {
    final SsipClient? client = await (_connection ??= _open());
    if (client == null) {
      return false;
    }
    final int colon = voice.id.indexOf(':');
    // Voices are always reported as `module:voice`.
    if (colon < 0) {
      return false;
    }
    // In this order, because setting a language can change the voice. The name
    // is sent bare: the daemon takes the rest of the line as the name, spaces
    // included, and quotes would become part of it.
    final List<String> setup = <String>[
      _cancelOwnSpeech,
      'SET self OUTPUT_MODULE ${voice.id.substring(0, colon)}',
      'SET self LANGUAGE ${voice.language}',
      'SET self SYNTHESIS_VOICE ${voice.id.substring(colon + 1)}',
      'SET self RATE ${_ssipRate(utterance.rate)}',
    ];
    for (final String command in setup) {
      if (!identical(_current, request)) {
        return false;
      }
      await client.require(command);
    }
    if (!identical(_current, request)) {
      return false;
    }
    request.queuedAs(await client.speak(utterance.text));
    return true;
  }

  Future<SsipClient?> _open() async {
    try {
      final SsipClient client = await SsipClient.open(_connect);
      client.events.listen((SsipEvent event) {
        _current?.messageOver(event.messageId);
      });
      return client;
    } on IOException {
      _connection = null;
    } on SsipException {
      _connection = null;
    }
    return null;
  }

  /// Translates an app speech rate into SSIP's, whose zero is the voice's
  /// normal speed: 0.5..1.5 becomes -50..+50.
  static int _ssipRate(double rate) =>
      ((clampSpeechRate(rate) - kDefaultSpeechRate) * 100).round();
}

/// One utterance handed to the daemon, and the wait for it to be over.
///
/// The message id arrives in a reply, and the report that the message is over
/// arrives on its own, in no fixed order: a word can be over before the code
/// waiting for its id has run. So reports arriving before the id are kept.
/// They all belong to older messages, or to this one, whose id then matches.
final class _SpokenRequest {
  final Completer<void> _done = Completer<void>();
  final Set<int> _overBeforeQueued = <int>{};
  int? _messageId;

  /// Completes when the utterance is over, cancelled or replaced.
  Future<void> get done => _done.future;

  /// Notes the id the daemon gave this utterance.
  void queuedAs(int id) {
    _messageId = id;
    if (_overBeforeQueued.contains(id)) {
      finish();
    }
  }

  /// Notes that message [id] is over, which may not be this one's.
  void messageOver(int id) {
    if (_messageId == null) {
      _overBeforeQueued.add(id);
    } else if (_messageId == id) {
      finish();
    }
  }

  /// Ends the wait, once.
  void finish() {
    if (!_done.isCompleted) {
      _done.complete();
    }
  }
}
