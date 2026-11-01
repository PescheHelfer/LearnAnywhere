import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_ui_kit/src/speech/ssip_client.dart';

import 'support/fake_speech_dispatcher.dart';

void main() {
  late FakeSpeechDispatcher daemon;
  late SsipClient client;

  setUp(() async {
    daemon = await FakeSpeechDispatcher.start();
    client = await SsipClient.open(daemon.connect);
  });

  tearDown(() async {
    client.close();
    await daemon.close();
  });

  group('opening a connection', () {
    test('introduces the client, asks for end reports and queues politely', () {
      expect(daemon.commands, <String>[
        'SET self CLIENT_NAME learner:learn-anywhere:speech',
        'SET self NOTIFICATION end on',
        'SET self NOTIFICATION cancel on',
        'SET self PRIORITY message',
      ]);
    });

    test('fails when the daemon refuses part of the handshake', () async {
      final FakeSpeechDispatcher refusing = await FakeSpeechDispatcher.start();
      addTearDown(refusing.close);
      refusing.replyTo('SET self PRIORITY', '409 ERR PARAMETER INVALID\r\n');

      await expectLater(
        SsipClient.open(refusing.connect),
        throwsA(isA<SsipException>()),
      );
    });

    test('fails when the daemon says nothing at all', () async {
      final FakeSpeechDispatcher silent = await FakeSpeechDispatcher.start();
      addTearDown(silent.close);
      silent.ignore('SET self CLIENT_NAME');

      await expectLater(
        SsipClient.open(
          silent.connect,
          commandTimeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<SsipException>()),
      );
    });
  });

  group('replies', () {
    test('a multi-line reply carries its data lines in order', () async {
      daemon.replyTo(
        'LIST OUTPUT_MODULES',
        '250-espeak-ng\r\n250-pico\r\n250 OK MODULE LIST SENT\r\n',
      );

      final SsipReply reply = await client.command('LIST OUTPUT_MODULES');

      expect(reply.code, 250);
      expect(reply.lines, <String>['espeak-ng', 'pico']);
      expect(reply.text, 'OK MODULE LIST SENT');
    });

    test('a reply split inside a line and inside a letter is whole', () async {
      daemon.ignore('LIST');
      final Future<SsipReply> pending = client.command('LIST VOICES');
      await daemon.untilReceived('LIST VOICES');

      final List<int> wire = utf8.encode('250-Grüezi\r\n250 OK\r\n');
      await daemon.sendPieces(<List<int>>[
        for (final int byte in wire) <int>[byte],
      ]);

      final SsipReply reply = await pending;
      expect(reply.lines, <String>['Grüezi']);
      expect(reply.text, 'OK');
    });

    test('a reply and an event merged into one chunk both arrive', () async {
      daemon.replyTo('PING', '200 OK\r\n702-7\r\n702-1\r\n702 END\r\n');
      final Future<SsipEvent> event = client.events.first;

      final SsipReply reply = await client.command('PING');

      expect(reply.code, 200);
      expect((await event).messageId, 7);
    });

    test('success is the 2xx class, not any one code', () async {
      Future<bool> succeeds(String code) async {
        daemon.replyTo('TRY $code', '$code SOMETHING\r\n');
        return (await client.command('TRY $code')).isSuccess;
      }

      expect(await succeeds('200'), isTrue);
      expect(await succeeds('299'), isTrue);
      expect(await succeeds('199'), isFalse);
      expect(await succeeds('300'), isFalse);
      expect(await succeeds('410'), isFalse);
    });
  });

  group('serialising commands', () {
    test('a command waits for the one before it to be answered', () async {
      daemon.ignore('FIRST');
      final Future<SsipReply> first = client.command('FIRST');
      final Future<SsipReply> second = client.command('SECOND');
      await daemon.untilReceived('FIRST');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(daemon.commands, isNot(contains('SECOND')));

      daemon.send('200 OK\r\n');

      expect((await first).code, 200);
      await daemon.untilReceived('SECOND');
      expect((await second).code, 300);
    });

    test('a silent daemon fails the command by timeout', () async {
      final SsipClient impatient = await SsipClient.open(
        daemon.connect,
        commandTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(impatient.close);
      daemon.ignore('HANG');

      await expectLater(
        impatient.command('HANG'),
        throwsA(isA<SsipException>()),
      );
    });

    test('nothing after a timeout can pick up the late reply', () async {
      // SSIP replies carry no id, so an unanswered command leaves the stream
      // unattributable; the next reply could only be mistaken for this one's.
      final SsipClient impatient = await SsipClient.open(
        daemon.connect,
        commandTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(impatient.close);
      daemon.ignore('HANG');
      await expectLater(impatient.command('HANG'), throwsA(anything));

      await expectLater(
        impatient.command('LATER'),
        throwsA(isA<SsipException>()),
      );
    });

    test('a daemon going away fails what is waiting on it', () async {
      daemon.ignore('HANG');
      final Future<SsipReply> pending = client.command('HANG');
      await daemon.untilReceived('HANG');

      await daemon.close();

      await expectLater(pending, throwsA(isA<SsipException>()));
    });
  });

  group('events', () {
    test('an end report carries its message id', () async {
      final Future<SsipEvent> event = client.events.first;

      daemon.sendEnd(21);

      expect(
        await event,
        isA<SsipEvent>()
            .having((SsipEvent e) => e.messageId, 'id', 21)
            .having((SsipEvent e) => e.kind, 'kind', SsipEventKind.ended),
      );
    });

    test('a cancel report carries its message id', () async {
      final Future<SsipEvent> event = client.events.first;

      daemon.sendCanceled(22);

      expect(
        await event,
        isA<SsipEvent>()
            .having((SsipEvent e) => e.messageId, 'id', 22)
            .having((SsipEvent e) => e.kind, 'kind', SsipEventKind.canceled),
      );
    });

    test('an event inside a multi-line reply disturbs neither', () async {
      daemon.ignore('LIST');
      final Future<SsipEvent> event = client.events.first;
      final Future<SsipReply> pending = client.command('LIST');
      await daemon.untilReceived('LIST');

      daemon.send(
        '250-one\r\n702-9\r\n702-1\r\n702 END\r\n250-two\r\n250 OK\r\n',
      );

      expect((await pending).lines, <String>['one', 'two']);
      expect((await event).messageId, 9);
    });

    test('reports other than end and cancel are not published', () async {
      final List<SsipEvent> events = <SsipEvent>[];
      final StreamSubscription<SsipEvent> subscription = client.events.listen(
        events.add,
      );
      addTearDown(subscription.cancel);

      daemon.send('701-3\r\n701-1\r\n701 BEGIN\r\n');
      daemon.sendEnd(3);
      await pumpUntil(() => events.isNotEmpty);

      expect(events.single.kind, SsipEventKind.ended);
    });
  });

  group('speaking', () {
    test('sends the text after the go-ahead and returns the id', () async {
      final int id = await client.speak('hello');

      expect(id, daemon.queuedMessages.single);
      expect(daemon.received.skip(4), <String>['SPEAK', 'hello', '.']);
    });

    test('line breaks of every kind go out as CRLF', () async {
      await client.speak('one\ntwo\r\nthree\rfour');

      expect(
        utf8.decode(daemon.bytes),
        endsWith('SPEAK\r\none\r\ntwo\r\nthree\r\nfour\r\n.\r\n'),
      );
    });

    test('a line starting with a dot is stuffed', () async {
      await client.speak('.hidden\nplain\n.\n..');

      expect(daemon.received.skip(5), <String>[
        '..hidden',
        'plain',
        '..',
        '...',
        '.',
      ]);
    });

    test('a dot anywhere else is left alone', () async {
      await client.speak('etc. and so on.');

      expect(daemon.received, contains('etc. and so on.'));
    });

    test('accents survive the round trip as UTF-8', () async {
      await client.speak('Grüezi');
      await client.speak('français');
      await client.speak('perché');

      expect(
        daemon.received,
        containsAllInOrder(<String>['Grüezi', 'français', 'perché']),
      );
      expect(
        daemon.bytes,
        containsAllInOrder(<int>[0x47, 0x72, 0xC3, 0xBC, 0x65, 0x7A, 0x69]),
      );
    });

    test('no command can slip in between SPEAK and its text', () async {
      final Future<int> speaking = client.speak('hello');
      final Future<SsipReply> next = client.command('PING');

      await speaking;
      await next;

      expect(daemon.received.skip(4), <String>['SPEAK', 'hello', '.', 'PING']);
    });

    test('a refused SPEAK fails and leaves the connection usable', () async {
      daemon.replyTo('SPEAK', '401 ERR NOT ALLOWED\r\n');

      await expectLater(client.speak('hello'), throwsA(isA<SsipException>()));

      expect(daemon.received, isNot(contains('hello')));
      expect((await client.command('CANCEL self')).code, 210);
    });
  });
}
