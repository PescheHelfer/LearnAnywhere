import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/ssip_diagnostic.dart';
import 'support/fake_speech_dispatcher.dart';

void main() {
  late FakeSpeechDispatcher daemon;
  final List<String> log = <String>[];

  setUp(() async {
    log.clear();
    daemon = await FakeSpeechDispatcher.start();
    daemon.sentWithQueuedReply = FakeSpeechDispatcher.endReport;
  });

  tearDown(() => daemon.close());

  test('speaks every sample in its own language', () async {
    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isTrue);
    expect(
      daemon.commands.where((String c) => c.contains('LANGUAGE')),
      <String>[
        'SET self LANGUAGE en',
        'SET self LANGUAGE de',
        'SET self LANGUAGE fr',
        'SET self LANGUAGE it',
      ],
    );
    expect(daemon.queuedMessages, hasLength(4));
    for (final String accent in <String>['ü', 'ç', 'é']) {
      expect(daemon.received.join(), contains(accent));
    }
  });

  test('logs every command, reply and event', () async {
    await runSsipDiagnostic(daemon.connect, log.add);

    expect(log, contains('> SET self LANGUAGE de'));
    expect(log, contains('< 201 OK LANGUAGE SET'));
    expect(log, contains('< 702 END'));
  });

  test('a daemon that never reports an end does not hang it', () async {
    daemon.sentWithQueuedReply = null;

    final bool worked = await runSsipDiagnostic(
      daemon.connect,
      log.add,
      sampleLimit: const Duration(milliseconds: 20),
    );

    expect(worked, isFalse);
    expect(daemon.queuedMessages, hasLength(4));
  });

  test('a refused language counts against the run', () async {
    daemon.replyTo('SET self LANGUAGE it', '404 ERR COULDNT SET LANGUAGE\r\n');

    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isFalse);
    expect(log.join('\n'), contains('Language it was refused'));
  });

  test('no daemon is a report, not an exception', () async {
    final bool worked = await runSsipDiagnostic(
      () => throw const SocketException('nobody home'),
      log.add,
    );

    expect(worked, isFalse);
    expect(log.last, contains('nobody home'));
  });

  test('a refused handshake is a report, not an exception', () async {
    daemon.replyTo('SET self PRIORITY', '409 ERR PARAMETER INVALID\r\n');

    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isFalse);
    expect(log.last, contains('PRIORITY'));
  });
}
