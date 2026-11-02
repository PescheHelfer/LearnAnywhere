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
    daemon.modules['espeak-ng'] = <String>[
      'English (Great Britain)\ten-GB\tnone',
      'German\tde\tnone',
      'French (France)\tfr-FR\tnone',
    ];
    daemon.modules['generic'] = <String>['piper:paola\tit\tnone'];
    daemon.defaultModule = 'espeak-ng';
  });

  tearDown(() => daemon.close());

  test('speaks every sample in its own language', () async {
    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isTrue);
    expect(
      daemon.commands.where((String c) => c.contains('LANGUAGE')),
      <String>[
        'SET self LANGUAGE en-GB',
        'SET self LANGUAGE de',
        'SET self LANGUAGE fr-FR',
        'SET self LANGUAGE it',
      ],
    );
    expect(daemon.queuedMessages, hasLength(4));
    for (final String accent in <String>['ü', 'ç', 'é']) {
      expect(daemon.received.join(), contains(accent));
    }
  });

  test('speaks each sample in the voice Automatic would pick', () async {
    await runSsipDiagnostic(daemon.connect, log.add);

    final List<String> spoken = daemon.commands
        .skipWhile((String c) => c != 'LIST OUTPUT_MODULES')
        .where((String c) => c.contains('SYNTHESIS_VOICE '))
        .toList();
    expect(spoken, <String>[
      'SET self SYNTHESIS_VOICE English (Great Britain)',
      'SET self SYNTHESIS_VOICE German',
      'SET self SYNTHESIS_VOICE French (France)',
      'SET self SYNTHESIS_VOICE piper:paola',
    ]);
    expect(
      daemon.commands,
      containsAllInOrder(<String>[
        'SET self OUTPUT_MODULE generic',
        'SET self LANGUAGE it',
        'SET self SYNTHESIS_VOICE piper:paola',
        'SPEAK',
      ]),
    );
  });

  test('prints the modules, default first, and voices per language', () async {
    await runSsipDiagnostic(daemon.connect, log.add);

    expect(
      log,
      containsAllInOrder(<String>[
        'Default module: espeak-ng',
        'Module espeak-ng: 3 voices',
        'Module generic: 1 voice',
        'Voices for de:',
        '  espeak-ng: German',
        'Voices for en-GB:',
        '  espeak-ng: English (Great Britain)',
        'Voices for fr-FR:',
        'Voices for it:',
        '  generic: piper:paola',
      ]),
    );
  });

  test('a failing module is reported, the others still used', () async {
    daemon.failingModules.add('rhvoice');

    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isTrue);
    expect(
      log,
      contains('Module rhvoice: no voices, 411 ERR CANT REPORT VOICES'),
    );
  });

  test('an unknown default module is reported', () async {
    daemon.replyTo('GET OUTPUT_MODULE', '300 ERR UNKNOWN COMMAND\r\n');

    await runSsipDiagnostic(daemon.connect, log.add);

    expect(log, contains('Default module: not reported'));
  });

  test('a language with no voice counts against the run, and is still '
      'spoken', () async {
    daemon.modules.remove('generic');

    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isFalse);
    expect(
      log,
      contains(
        'No voice for it, said by the module set last, only the language set',
      ),
    );
    expect(daemon.commands, contains('SET self LANGUAGE it'));
    expect(daemon.queuedMessages, hasLength(4));
  });

  test('a refused voice counts against the run', () async {
    daemon.replyTo('SET self SYNTHESIS_VOICE German', '407 ERR NO VOICE\r\n');

    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isFalse);
    expect(
      log.join('\n'),
      contains('Refused "SET self SYNTHESIS_VOICE German": 407 ERR NO VOICE'),
    );
  });

  test('logs every command, reply and event', () async {
    await runSsipDiagnostic(daemon.connect, log.add);

    expect(log, contains('> LIST SYNTHESIS_VOICES'));
    expect(log, contains('< 249-German\tde\tnone'));
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
    expect(log.join('\n'), contains('Refused "SET self LANGUAGE it"'));
  });

  test('no daemon is a report, not an exception', () async {
    final bool worked = await runSsipDiagnostic(
      () => throw const SocketException('nobody home'),
      log.add,
      start: () async {},
    );

    expect(worked, isFalse);
    expect(log.last, contains('nobody home'));
  });

  test('a service not running is started, as the program does', () async {
    bool started = false;

    final bool worked = await runSsipDiagnostic(
      () => started
          ? daemon.connect()
          : throw const SocketException('nobody home'),
      log.add,
      start: () async => started = true,
    );

    expect(worked, isTrue);
    expect(log.first, 'Nothing answered, starting speech-dispatcher');
  });

  test('a refused handshake is a report, not an exception', () async {
    daemon.replyTo('SET self PRIORITY', '409 ERR PARAMETER INVALID\r\n');

    final bool worked = await runSsipDiagnostic(daemon.connect, log.add);

    expect(worked, isFalse);
    expect(log.last, contains('PRIORITY'));
  });
}
