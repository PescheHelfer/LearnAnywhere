import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/settings/speech_settings_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The Options ▸ Speech screen: which languages it lists, which voices it
/// offers for each, what the test button says, and what it stores.
///
/// Driven against a recording engine, so no test makes a sound.
void main() {
  const SpeechVoice hortense = SpeechVoice(
    id: 'Microsoft Hortense',
    name: 'Microsoft Hortense',
    language: 'fr-FR',
  );
  const SpeechVoice claude = SpeechVoice(
    id: 'Microsoft Claude',
    name: 'Microsoft Claude',
    language: 'fr-CA',
  );
  const SpeechVoice hedda = SpeechVoice(
    id: 'Microsoft Hedda',
    name: 'Microsoft Hedda',
    language: 'de-DE',
  );

  const LearningDeck deck = LearningDeck(
    mask: LearningMask(
      maskId: 'm_new_speech-screen-fixture',
      name: 'Fixture',
      direction1Label: 'A',
      direction2Label: 'B',
      categories: <CategoryDefinition>[
        CategoryDefinition(
          id: 0,
          name: 'Cat',
          fields: <FieldDefinition>[
            FieldDefinition(
              id: 0,
              name: 'French',
              length: 20,
              equalGroup: 0,
              role1: FieldRole.question,
              role2: FieldRole.answer,
              language: 'fr-FR',
              speak: true,
            ),
            FieldDefinition(
              id: 1,
              name: 'Italian',
              length: 20,
              equalGroup: 0,
              role1: FieldRole.answer,
              role2: FieldRole.question,
              language: 'it-IT',
              speak: true,
            ),
          ],
        ),
      ],
    ),
    units: <LearningUnit>[],
  );

  /// Pumps the screen with its own settings state, so a change made on screen
  /// comes back to it exactly as the shell would hand it back.
  Future<SpeechSettings Function()> pumpScreen(
    WidgetTester tester, {
    required TtsEngine engine,
    LearningDeck? withDeck = deck,
    SpeechSettings initial = const SpeechSettings(),
    int zoomPercent = 100,
    Size surface = const Size(1400, 1000),
  }) async {
    SpeechSettings current = initial;
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        theme: LearnAnywhereTheme.light(zoomPercent: zoomPercent),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Scaffold(
              body: SpeechSettingsPage(
                engine: engine,
                deck: withDeck,
                settings: current,
                onChanged: (SpeechSettings value) {
                  setState(() => current = value);
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => current;
  }

  testWidgets('lists the open deck\'s languages and any already configured', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense, hedda]),
      initial: const SpeechSettings(
        voices: <String, VoiceChoice>{
          'de-DE': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Hedda',
          ),
        },
      ),
    );

    expect(find.byKey(const Key('speechRow-fr-FR')), findsOneWidget);
    expect(find.byKey(const Key('speechRow-it-IT')), findsOneWidget);
    // Configured elsewhere, unused by this deck, and still reachable.
    expect(find.byKey(const Key('speechRow-de-DE')), findsOneWidget);
  });

  testWidgets('lists only the configured languages with no deck open', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense, hedda]),
      withDeck: null,
      initial: const SpeechSettings(
        voices: <String, VoiceChoice>{
          'de-DE': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Hedda',
          ),
        },
      ),
    );

    expect(find.byKey(const Key('speechRow-de-DE')), findsOneWidget);
    expect(find.byKey(const Key('speechRow-fr-FR')), findsNothing);
  });

  testWidgets('says so plainly when a language has no installed voice', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
      withDeck: deck,
    );

    // French has a voice and so offers one; Italian has none, and says it
    // rather than offering an empty list.
    expect(find.byKey(const Key('speechVoice-fr-FR')), findsOneWidget);
    expect(find.byKey(const Key('speechVoice-it-IT')), findsNothing);
    expect(find.byKey(const Key('speechTest-it-IT')), findsNothing);
    expect(find.textContaining('no voice for it-IT'), findsOneWidget);
    // And points at the chapter that says how to add one.
    expect(find.textContaining('Speech'), findsWidgets);
  });

  testWidgets('stores a chosen voice as an engine plus a voice within it', (
    WidgetTester tester,
  ) async {
    final SpeechSettings Function() settings = await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense, claude]),
    );

    await tester.tap(find.byKey(const Key('speechVoice-fr-FR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Microsoft Claude').last);
    await tester.pumpAndSettle();

    expect(
      settings().voiceFor('fr-FR'),
      const VoiceChoice(
        engine: kSystemSpeechEngineId,
        voiceId: 'Microsoft Claude',
      ),
    );
  });

  testWidgets('a choice can be handed back to the program', (
    WidgetTester tester,
  ) async {
    final SpeechSettings Function() settings = await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense, claude]),
      initial: const SpeechSettings(
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Claude',
          ),
        },
      ),
    );

    await tester.tap(find.byKey(const Key('speechVoice-fr-FR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic').last);
    await tester.pumpAndSettle();

    expect(settings().voiceFor('fr-FR'), isNull);
  });

  testWidgets('a choice whose voice is gone shows as Automatic again', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      // Only the France voice is installed now; the chosen Canadian one was
      // uninstalled since it was picked.
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
      initial: const SpeechSettings(
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Claude',
          ),
        },
      ),
    );

    // Shown as Automatic, which is exactly what a session would do with it.
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Microsoft Claude'), findsNothing);
  });

  testWidgets('the test button speaks a sample in the row\'s chosen voice', (
    WidgetTester tester,
  ) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[hortense, claude, hedda],
    );
    await pumpScreen(
      tester,
      engine: engine,
      initial: const SpeechSettings(
        voices: <String, VoiceChoice>{
          'fr-FR': VoiceChoice(
            engine: kSystemSpeechEngineId,
            voiceId: 'Microsoft Claude',
          ),
        },
      ),
    );

    await tester.tap(find.byKey(const Key('speechTest-fr-FR')));
    await tester.pumpAndSettle();

    expect(engine.spoken.single.voice, claude);
    expect(engine.spoken.single.text, speechSampleFor('fr-FR'));
    expect(engine.spoken.single.rate, kDefaultSpeechRate);
  });

  testWidgets('the rate control changes what the test button is spoken at', (
    WidgetTester tester,
  ) async {
    final _RecordingTtsEngine engine = _RecordingTtsEngine(
      const <SpeechVoice>[hortense],
    );
    final SpeechSettings Function() settings = await pumpScreen(
      tester,
      engine: engine,
    );

    await tester.drag(find.byKey(const Key('speechRate')), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(settings().rate, lessThan(kDefaultSpeechRate));

    await tester.tap(find.byKey(const Key('speechTest-fr-FR')));
    await tester.pumpAndSettle();
    expect(engine.spoken.single.rate, settings().rate);
  });

  testWidgets('the automatic-speech switch starts on and is stored when it '
      'is turned off', (WidgetTester tester) async {
    final SpeechSettings Function() settings = await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
    );

    expect(settings().automatic, isTrue);
    expect(
      tester.widget<Checkbox>(find.byKey(const Key('speechAutomatic'))).value,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('speechAutomatic')));
    await tester.pumpAndSettle();
    expect(settings().automatic, isFalse);

    // And back on again, without disturbing anything else on the screen.
    await tester.tap(find.byKey(const Key('speechAutomatic')));
    await tester.pumpAndSettle();
    expect(settings().automatic, isTrue);
    expect(settings().rate, kDefaultSpeechRate);
  });

  testWidgets('choosing a voice leaves automatic speech switched on', (
    WidgetTester tester,
  ) async {
    final SpeechSettings Function() settings = await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
      initial: const SpeechSettings(automatic: true),
    );

    await tester.tap(find.byKey(const Key('speechVoice-fr-FR')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Microsoft Hortense').last);
    await tester.pumpAndSettle();

    expect(settings().voiceFor('fr-FR')?.voiceId, 'Microsoft Hortense');
    expect(settings().automatic, isTrue);
  });

  testWidgets('neither end of the zoom range runs off the edge', (
    WidgetTester tester,
  ) async {
    // The window the program opens at, where doubled text runs out of room
    // first, at both ends of the range. A layout overflow throws in a widget
    // test, so building the screen IS the assertion.
    for (final int level in <int>[
      LearnAnywhereZoom.minimum,
      LearnAnywhereZoom.maximum,
    ]) {
      await pumpScreen(
        tester,
        // Both kinds of row at once: French has voices to choose between,
        // Italian has none and carries the longer sentence instead.
        engine: _RecordingTtsEngine(const <SpeechVoice>[hortense, claude]),
        zoomPercent: level,
        surface: const Size(1280, 720),
      );
      expect(tester.takeException(), isNull, reason: 'at $level%');
    }
  });

  testWidgets('an empty screen explains itself instead of showing nothing', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      engine: _RecordingTtsEngine(const <SpeechVoice>[hortense]),
      withDeck: null,
    );

    expect(find.byKey(const Key('speechRow-fr-FR')), findsNothing);
    expect(find.textContaining('No language to set a voice for'), findsOneWidget);
  });
}

/// A [TtsEngine] that records what it was asked to say instead of saying it.
final class _RecordingTtsEngine implements TtsEngine {
  _RecordingTtsEngine(this._voices);

  final List<SpeechVoice> _voices;

  /// Every utterance handed to [speak], in order.
  final List<SpeechUtterance> spoken = <SpeechUtterance>[];

  @override
  bool get isAvailable => true;

  @override
  Future<List<SpeechVoice>> voices() async => _voices;

  @override
  Future<void> speak(SpeechUtterance utterance) async {
    spoken.add(utterance);
  }

  @override
  Future<void> stop() async {}
}
