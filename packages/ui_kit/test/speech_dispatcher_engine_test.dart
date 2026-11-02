import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'support/fake_speech_dispatcher.dart';

const SpeechVoice _french = SpeechVoice(
  id: 'espeak-ng:French (France)',
  name: 'espeak-ng: French (France)',
  language: 'fr',
);

SpeechUtterance _say(
  String text, {
  SpeechVoice? voice = _french,
  double rate = kDefaultSpeechRate,
  bool leadIn = false,
}) => SpeechUtterance(
  fieldId: 0,
  text: text,
  language: 'fr-FR',
  voice: voice,
  rate: rate,
  leadIn: leadIn,
);

void main() {
  late FakeSpeechDispatcher daemon;
  late SpeechDispatcherEngine engine;

  /// What the daemon received after the handshake and the question for its
  /// default module.
  List<String> commandsAfterHandshake() => daemon.commands.skip(5).toList();

  /// Whether [future] has finished, after giving it a moment to.
  Future<bool> isOver(Future<void> future) async {
    bool over = false;
    unawaited(future.then<void>((_) => over = true));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return over;
  }

  setUp(() async {
    daemon = await FakeSpeechDispatcher.start();
    engine = SpeechDispatcherEngine(connect: daemon.connect);
  });

  tearDown(() => daemon.close());

  test('the utterance limit is one minute', () {
    expect(
      SpeechDispatcherEngine.defaultUtteranceLimit,
      const Duration(seconds: 60),
    );
  });

  group('what is not said', () {
    test('a null voice returns at once and touches nothing', () async {
      await engine.speak(_say('maison', voice: null));

      expect(daemon.received, isEmpty);
    });

    test('empty text returns at once and touches nothing', () async {
      await engine.speak(_say(''));

      expect(daemon.received, isEmpty);
    });

    test('a daemon that cannot be reached is silence', () async {
      final SpeechDispatcherEngine alone = SpeechDispatcherEngine(
        connect: () => throw const SocketException('nobody home'),
      );

      await alone.speak(_say('maison'));
      await alone.stop();

      expect(alone.isAvailable, isTrue);
    });

    test('a refused setting is silence, not a word in the wrong voice', () {
      daemon.replyTo('SET self SYNTHESIS_VOICE', '407 ERR COULDNT SET\r\n');

      return expectLater(
        engine.speak(_say('maison')).then((_) => daemon.received),
        completion(isNot(contains('maison'))),
      );
    });
  });

  group('saying a word', () {
    test('cancels, then sets everything in the required order', () async {
      unawaited(engine.speak(_say('maison')));
      await daemon.untilQueued(1);

      expect(commandsAfterHandshake(), <String>[
        'CANCEL self',
        'SET self OUTPUT_MODULE espeak-ng',
        'SET self LANGUAGE fr',
        'SET self SYNTHESIS_VOICE French (France)',
        'SET self RATE 0',
        'SPEAK',
      ]);
    });

    test('splits the voice id on its first colon only', () async {
      const SpeechVoice voice = SpeechVoice(
        id: 'generic:piper:thorsten',
        name: 'generic: piper:thorsten',
        language: 'de',
      );

      unawaited(engine.speak(_say('Haus', voice: voice)));
      await daemon.untilQueued(1);

      expect(
        commandsAfterHandshake(),
        containsAllInOrder(<String>[
          'SET self OUTPUT_MODULE generic',
          'SET self SYNTHESIS_VOICE piper:thorsten',
        ]),
      );
    });

    test('completes on the END of its own message, and not before', () async {
      final Future<void> speaking = engine.speak(_say('maison'));
      final int id = await daemon.untilQueued(1);

      daemon.sendEnd(id + 1000);
      expect(await isOver(speaking), isFalse);

      daemon.sendEnd(id);
      await speaking;
    });

    test('completes on the CANCELED of its own message', () async {
      final Future<void> speaking = engine.speak(_say('maison'));
      final int id = await daemon.untilQueued(1);

      daemon.sendCanceled(id);

      await speaking;
    });

    test('an END arriving with the queued reply is not missed', () async {
      daemon.sentWithQueuedReply = FakeSpeechDispatcher.endReport;

      await engine.speak(_say('maison'));
    });

    test('completes at the limit when no report ever comes', () async {
      final SpeechDispatcherEngine limited = SpeechDispatcherEngine(
        connect: daemon.connect,
        utteranceLimit: const Duration(milliseconds: 50),
      );

      await limited.speak(_say('maison'));

      expect(daemon.received, contains('maison'));
    });

    test('awaited utterances are said in order', () async {
      final Future<void> sequence = () async {
        await engine.speak(_say('une'));
        await engine.speak(_say('maison'));
      }();
      final int first = await daemon.untilQueued(1);
      expect(daemon.received, isNot(contains('maison')));

      daemon.sendEnd(first);
      final int second = await daemon.untilQueued(2);
      expect(daemon.received, contains('maison'));

      daemon.sendEnd(second);
      await sequence;
    });

    test('a lead-in changes nothing on the wire', () async {
      final FakeSpeechDispatcher other = await FakeSpeechDispatcher.start();
      addTearDown(other.close);
      final SpeechDispatcherEngine withLeadIn = SpeechDispatcherEngine(
        connect: other.connect,
      );

      unawaited(engine.speak(_say('maison')));
      unawaited(withLeadIn.speak(_say('maison', leadIn: true)));
      await daemon.untilQueued(1);
      await other.untilQueued(1);

      expect(other.received, daemon.received);
    });
  });

  group('rate', () {
    Future<String> rateFor(double rate) async {
      final int queued = daemon.queuedMessages.length;
      unawaited(engine.speak(_say('maison', rate: rate)));
      await daemon.untilQueued(queued + 1);
      return daemon.commands.lastWhere(
        (String command) => command.startsWith('SET self RATE'),
      );
    }

    test('the app range maps onto half the SSIP range', () async {
      expect(await rateFor(0.5), 'SET self RATE -50');
      expect(await rateFor(1.0), 'SET self RATE 0');
      expect(await rateFor(1.5), 'SET self RATE 50');
    });

    test('a rate between the marks lands between them', () async {
      expect(await rateFor(0.75), 'SET self RATE -25');
    });

    test('a rate out of range is held to it', () async {
      expect(await rateFor(9), 'SET self RATE 50');
    });
  });

  group('replacing', () {
    test('a new request ends the old wait and cuts it off', () async {
      final Future<void> first = engine.speak(_say('une'));
      await daemon.untilQueued(1);

      final Future<void> second = engine.speak(_say('maison'));

      await first;
      final int id = await daemon.untilQueued(2);
      expect(
        daemon.commands.where((String c) => c == 'CANCEL self'),
        hasLength(2),
      );
      daemon.sendEnd(id);
      await second;
    });

    test('a late report for the old message does not end the new', () async {
      final Future<void> first = engine.speak(_say('une'));
      final int oldId = await daemon.untilQueued(1);
      final Future<void> second = engine.speak(_say('maison'));
      await first;
      final int newId = await daemon.untilQueued(2);

      daemon.sendCanceled(oldId);
      daemon.sendEnd(oldId);
      expect(await isOver(second), isFalse);

      daemon.sendEnd(newId);
      await second;
    });

    test('a report for the old message during set-up is ignored', () async {
      daemon.ignore('SET self RATE');
      final Future<void> first = engine.speak(_say('une'));
      await daemon.untilReceived('SET self RATE 0');
      daemon.send('203 OK RATE SET\r\n');
      final int oldId = await daemon.untilQueued(1);

      final Future<void> second = engine.speak(_say('maison'));
      await first;
      daemon.sendCanceled(oldId);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // The successor's own RATE is the ignored command now.
      await daemon.untilCommands('SET self RATE', 2);
      daemon.send('203 OK RATE SET\r\n');
      final int newId = await daemon.untilQueued(2);

      expect(await isOver(second), isFalse);
      daemon.sendEnd(newId);
      await second;
    });

    test('a request replaced during set-up is never spoken', () async {
      daemon.ignore('SET self LANGUAGE');
      final Future<void> first = engine.speak(_say('une'));
      await daemon.untilReceived('SET self LANGUAGE fr');

      final Future<void> second = engine.speak(_say('maison'));
      daemon.send('201 OK LANGUAGE SET\r\n');
      await first;
      await daemon.untilCommands('SET self LANGUAGE', 2);
      daemon.send('201 OK LANGUAGE SET\r\n');
      final int id = await daemon.untilQueued(1);

      expect(daemon.received, isNot(contains('une')));
      daemon.sendEnd(id);
      await second;
    });
  });

  group('voices', () {
    setUp(() {
      daemon.modules['espeak-ng'] = <String>[
        'French (France)\tfr\tnone',
        'German\tde\tnone',
      ];
      daemon.modules['rhvoice'] = <String>['Anna\tru\tnone'];
      daemon.defaultModule = 'rhvoice';
    });

    test('lists the default module first, then every other', () async {
      expect(await engine.voices(), const <SpeechVoice>[
        SpeechVoice(id: 'rhvoice:Anna', name: 'rhvoice: Anna', language: 'ru'),
        SpeechVoice(
          id: 'espeak-ng:French (France)',
          name: 'espeak-ng: French (France)',
          language: 'fr',
        ),
        SpeechVoice(
          id: 'espeak-ng:German',
          name: 'espeak-ng: German',
          language: 'de',
        ),
      ]);
    });

    test('a voice name holding a colon round-trips', () async {
      daemon.modules['generic'] = <String>['piper:thorsten\tde-DE\tnone'];

      final SpeechVoice voice = (await engine.voices()).singleWhere(
        (SpeechVoice v) => v.language == 'de-DE',
      );
      expect(voice.name, 'generic: piper:thorsten');
      unawaited(engine.speak(_say('Haus', voice: voice)));
      await daemon.untilQueued(1);

      expect(
        daemon.commands,
        containsAllInOrder(<String>[
          'SET self OUTPUT_MODULE generic',
          'SET self LANGUAGE de-DE',
          'SET self SYNTHESIS_VOICE piper:thorsten',
          'SPEAK',
        ]),
      );
    });

    test('a failing module is skipped and the others are listed', () async {
      daemon.failingModules.add('rhvoice');

      expect((await engine.voices()).map((SpeechVoice v) => v.id), <String>[
        'espeak-ng:French (France)',
        'espeak-ng:German',
      ]);
    });

    test('a module that cannot be selected is skipped', () async {
      daemon.replyTo(
        'SET self OUTPUT_MODULE espeak-ng',
        '305 ERR COULDNT SET OUTPUT MODULE\r\n',
      );

      expect((await engine.voices()).map((SpeechVoice v) => v.id), <String>[
        'rhvoice:Anna',
      ]);
    });

    test('an unanswered default module keeps the reported order', () async {
      daemon.replyTo('GET OUTPUT_MODULE', '300 ERR UNKNOWN COMMAND\r\n');

      expect((await engine.voices()).map((SpeechVoice v) => v.id), <String>[
        'espeak-ng:French (France)',
        'espeak-ng:German',
        'rhvoice:Anna',
      ]);
    });

    test('the default is the one before anything was said', () async {
      // Saying a word sets a module, and from then on the daemon reports
      // that one when asked for the default.
      final Future<void> speaking = engine.speak(_say('maison'));
      daemon.sendEnd(await daemon.untilQueued(1));
      await speaking;

      expect((await engine.voices()).first.id, 'rhvoice:Anna');
    });

    test('empty list replies give an empty list', () async {
      daemon.modules
        ..clear()
        ..['dummy'] = <String>[];

      expect(await engine.voices(), isEmpty);

      daemon.modules.clear();
      expect(await engine.voices(), isEmpty);
    });

    test('a voice reporting no language is left out', () async {
      daemon.modules['espeak-ng'] = <String>[
        'Mystery\t\tnone',
        'Unknown\tnone\tnone',
        'Nameless',
        'German\tde\tnone',
      ];

      expect((await engine.voices()).map((SpeechVoice v) => v.id), <String>[
        'rhvoice:Anna',
        'espeak-ng:German',
      ]);
    });

    test('no daemon gives no voices', () async {
      final SpeechDispatcherEngine alone = SpeechDispatcherEngine(
        connect: () => throw const SocketException('nobody home'),
      );

      expect(await alone.voices(), isEmpty);
    });

    test('a reported language serves a regional field', () async {
      final List<SpeechVoice> voices = await engine.voices();

      expect(
        resolveSpeechVoice('fr-FR', voices)?.id,
        'espeak-ng:French (France)',
      );
    });

    test('Automatic prefers the default module', () async {
      daemon.modules['rhvoice']!.add('Natalie\tfr\tnone');

      expect(
        resolveSpeechVoice('fr', await engine.voices())?.id,
        'rhvoice:Natalie',
      );
    });

    test('a listing never lands among a word\'s settings', () async {
      daemon.ignore('SET self LANGUAGE');
      final Future<void> speaking = engine.speak(_say('maison'));
      await daemon.untilReceived('SET self LANGUAGE fr');

      final Future<List<SpeechVoice>> listing = engine.voices();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      daemon.send('201 OK LANGUAGE SET\r\n');
      final int id = await daemon.untilQueued(1);
      daemon.sendEnd(id);
      await speaking;
      expect(await listing, hasLength(3));

      final List<String> commands = commandsAfterHandshake();
      expect(
        commands.sublist(0, commands.indexOf('SPEAK') + 1),
        everyElement(isNot(startsWith('LIST'))),
      );
    });

    test(
      'a new word cuts off the old at once, even during a listing',
      () async {
        final Future<void> first = engine.speak(_say('une'));
        await daemon.untilQueued(1);
        daemon.ignore('LIST SYNTHESIS_VOICES');
        final Future<List<SpeechVoice>> listing = engine.voices();
        await daemon.untilReceived('LIST SYNTHESIS_VOICES');

        final Future<void> second = engine.speak(_say('maison'));
        daemon.send('249-Anna\tru\tnone\r\n249 OK VOICE LIST SENT\r\n');

        await first;
        await daemon.untilCommands('LIST SYNTHESIS_VOICES', 2);
        daemon.send('249 OK VOICE LIST SENT\r\n');
        await listing;
        daemon.sendEnd(await daemon.untilQueued(2));
        await second;

        // The cancel went out behind the pending list, not behind the
        // whole listing.
        final List<String> commands = daemon.commands;
        expect(
          commands.lastIndexOf('CANCEL self'),
          lessThan(commands.lastIndexOf('LIST SYNTHESIS_VOICES')),
        );
      },
    );

    test('a word never lands inside a listing', () async {
      // A voice list is the current module's, so a word setting another
      // module in between would have one module's voices listed as another's.
      const SpeechVoice anna = SpeechVoice(
        id: 'rhvoice:Anna',
        name: 'rhvoice: Anna',
        language: 'ru',
      );
      daemon.ignore('LIST SYNTHESIS_VOICES');
      final Future<List<SpeechVoice>> listing = engine.voices();
      await daemon.untilReceived('LIST SYNTHESIS_VOICES');

      final Future<void> speaking = engine.speak(_say('da', voice: anna));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      daemon.send('249-Anna\tru\tnone\r\n249 OK VOICE LIST SENT\r\n');
      await daemon.untilCommands('LIST SYNTHESIS_VOICES', 2);
      daemon.send('249 OK VOICE LIST SENT\r\n');
      await listing;
      daemon.sendEnd(await daemon.untilQueued(1));
      await speaking;

      final List<String> commands = daemon.commands;
      expect(
        <String>[
          for (int i = 1; i < commands.length; i++)
            if (commands[i] == 'LIST SYNTHESIS_VOICES') commands[i - 1],
        ],
        <String>[
          'SET self OUTPUT_MODULE rhvoice',
          'SET self OUTPUT_MODULE espeak-ng',
        ],
      );
    });
  });

  group('stopping', () {
    test('sends CANCEL self and ends the wait', () async {
      final Future<void> speaking = engine.speak(_say('maison'));
      await daemon.untilQueued(1);

      await engine.stop();
      await speaking;

      expect(daemon.commands.last, 'CANCEL self');
    });

    test('ends the wait even if no report ever comes', () async {
      final Future<void> speaking = engine.speak(_say('maison'));
      await daemon.untilQueued(1);

      await engine.stop();

      expect(await isOver(speaking), isTrue);
    });

    test('with nothing ever said it opens no connection', () async {
      await engine.stop();

      expect(daemon.received, isEmpty);
    });

    test('never cancels anything but its own speech', () async {
      final Future<void> first = engine.speak(_say('une'));
      await daemon.untilQueued(1);
      final Future<void> second = engine.speak(_say('maison'));
      await first;
      await daemon.untilQueued(2);
      await engine.stop();
      await second;

      final Iterable<String> cancels = daemon.commands.where(
        (String command) => command.startsWith('CANCEL'),
      );
      expect(cancels, isNotEmpty);
      expect(cancels, everyElement('CANCEL self'));
    });
  });
}
