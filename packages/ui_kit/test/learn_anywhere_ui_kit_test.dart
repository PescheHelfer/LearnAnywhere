import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  group('menu accelerator markers', () {
    test('displayTextOf strips the & a bare Text would otherwise show', () {
      // Every catalog entry that names a desktop menu carries the marker; a
      // touch screen has no ALT key, so anything rendering one as plain text
      // has to strip it or the "&" reaches the user.
      expect(MenuAcceleratorDisplayLabel.displayTextOf('&Theme'), 'Theme');
      expect(
        MenuAcceleratorDisplayLabel.displayTextOf('&Darstellung'),
        'Darstellung',
      );
      expect(
        MenuAcceleratorDisplayLabel.displayTextOf('&Language'),
        'Language',
      );
      expect(MenuAcceleratorDisplayLabel.displayTextOf('&Sprache'), 'Sprache');
    });

    test('displayTextOf leaves an unmarked label and an escaped && alone', () {
      expect(MenuAcceleratorDisplayLabel.displayTextOf('Settings'), 'Settings');
      expect(MenuAcceleratorDisplayLabel.displayTextOf('Fish && Chips'),
          'Fish & Chips');
    });
  });

  group('themes', () {
    test('shared themes expose light and dark color schemes', () {
      expect(LearnAnywhereTheme.light().brightness, Brightness.light);
      expect(LearnAnywhereTheme.dark().brightness, Brightness.dark);
    });

    test('tokens name the BUNDLED monospace family, not a system font', () {
      // The fixed-width containers must not depend on host fonts, so the
      // family has to be the ui_kit-bundled one; the system list stays only as
      // a fallback.
      expect(
        LearnAnywhereTokens.monospaceFamily,
        'packages/learn_anywhere_ui_kit/LabMono',
      );
      expect(
        LearnAnywhereTokens.monospace(const TextStyle(fontSize: 13)).fontFamily,
        LearnAnywhereTokens.monospaceFamily,
      );
      expect(
        LearnAnywhereTokens.monospace(
          const TextStyle(fontSize: 13),
        ).fontFamilyFallback,
        LearnAnywhereTokens.monospaceFallback,
      );
      // The caller's own properties survive.
      expect(
        LearnAnywhereTokens.monospace(const TextStyle(fontSize: 13)).fontSize,
        13,
      );
    });

    test('tokens expose fixed learning typography fallback', () {
      expect(LearnAnywhereTokens.monospaceFallback, contains('Cascadia Mono'));
      expect(
        LearnAnywhereTokens.smallRadius,
        const BorderRadius.all(Radius.circular(8)),
      );
    });
  });

  group('zoom levels', () {
    test('the offered levels are the six discrete ones, ascending', () {
      expect(LearnAnywhereZoom.levels, <int>[75, 100, 125, 150, 175, 200]);
      expect(LearnAnywhereZoom.minimum, 75);
      expect(LearnAnywhereZoom.maximum, 200);
      // 100 is where the program starts and where Ctrl+zero returns to — it is
      // NOT the smallest level, and nothing may treat the two as the same.
      expect(LearnAnywhereZoom.normal, 100);
      expect(LearnAnywhereZoom.normal, isNot(LearnAnywhereZoom.minimum));
    });

    test('stepping moves between offered levels and stops at the ends', () {
      // The keys step through tested sizes; they never scale freely.
      expect(LearnAnywhereZoom.stepUp(75), 100);
      expect(LearnAnywhereZoom.stepUp(100), 125);
      expect(LearnAnywhereZoom.stepUp(175), 200);
      expect(LearnAnywhereZoom.stepUp(200), 200);
      expect(LearnAnywhereZoom.stepDown(200), 175);
      expect(LearnAnywhereZoom.stepDown(125), 100);
      // Below 100 there is now one more step, and then the floor.
      expect(LearnAnywhereZoom.stepDown(100), 75);
      expect(LearnAnywhereZoom.stepDown(75), 75);
    });

    test('a stored value that is not a level snaps onto the nearest one', () {
      // Anything can end up in the preferences store: a hand edit, or a level
      // some other build offered. Every caller wants a level back.
      expect(LearnAnywhereZoom.nearest(140), 150);
      expect(LearnAnywhereZoom.nearest(90), 100);
      expect(LearnAnywhereZoom.nearest(0), 75);
      expect(LearnAnywhereZoom.nearest(5000), 200);
      expect(LearnAnywhereZoom.isLevel(140), isFalse);
      expect(LearnAnywhereZoom.isLevel(75), isTrue);
      expect(LearnAnywhereZoom.isLevel(150), isTrue);
      // And stepping off a stray value lands on a level, not on a stray one.
      expect(LearnAnywhereZoom.stepUp(140), 175);
    });

    testWidgets('a key hint is a fixed size in text units, so it zooms too', (
      WidgetTester tester,
    ) async {
      // The caption naming the key under a pill is smaller than anything the
      // M3 scale offers, so it is written as a literal — but a literal that
      // follows the level, or it is unreadable beside text the learner
      // deliberately doubled.
      Future<double?> hintSizeAt(int zoomPercent) async {
        late TextStyle style;
        await tester.pumpWidget(
          MaterialApp(
            theme: LearnAnywhereTheme.light(zoomPercent: zoomPercent),
            home: Builder(
              builder: (BuildContext context) {
                style = LearnAnywhereTokens.keyHint(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        return style.fontSize;
      }

      expect(await hintSizeAt(100), LearnAnywhereTokens.keyHintFontSize);
      expect(await hintSizeAt(200), LearnAnywhereTokens.keyHintFontSize * 2);
      // A font size scales BOTH ways: below 100 the caption has to keep
      // shrinking with the label above it, or it stops being subordinate to it.
      expect(await hintSizeAt(75), LearnAnywhereTokens.keyHintFontSize * 0.75);
    });

    testWidgets('a box dimension grows with zoom but never shrinks', (
      WidgetTester tester,
    ) async {
      Future<double> boxAt(int zoomPercent) async {
        late double width;
        await tester.pumpWidget(
          MaterialApp(
            theme: LearnAnywhereTheme.light(zoomPercent: zoomPercent),
            home: Builder(
              builder: (BuildContext context) {
                width = LearnAnywhereZoom.scaleBox(context, 240);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        return width;
      }

      expect(await boxAt(100), 240);
      expect(await boxAt(200), 480);
      // Unlike a font size, a box holds fixed-size chrome as well as text — a
      // dropdown's arrow, the padding in an input decoration — and that does
      // not shrink. Scaling the box down to 180 for 75 per cent text overflowed
      // on exactly that, so below the normal level every box holds its ground.
      expect(await boxAt(75), 240);
    });

    test('the theme carries the zoom in its OWN font sizes', () {
      // This is the whole mechanism: the level is baked into the theme's text
      // styles, where the mask's character measurement can see it. A
      // TextScaler override would leave these numbers untouched and the field
      // boxes would be measured for text a size smaller than it renders.
      final ThemeData normal = LearnAnywhereTheme.darkBlue();
      final ThemeData zoomed = LearnAnywhereTheme.darkBlue(zoomPercent: 200);
      final double plain = normal.textTheme.bodyMedium!.fontSize!;
      final double large = zoomed.textTheme.bodyMedium!.fontSize!;
      expect(large, plain * 2);

      // And what the mask actually measures grows with it.
      final double plainChar = measureMonospaceCharWidth(
        LearnAnywhereTokens.monospace(normal.textTheme.bodyMedium),
      );
      final double largeChar = measureMonospaceCharWidth(
        LearnAnywhereTokens.monospace(zoomed.textTheme.bodyMedium),
      );
      expect(largeChar, greaterThan(plainChar * 1.9));
    });

    testWidgets('a field label column is bounded in zoomed units', (
      WidgetTester tester,
    ) async {
      // The bounds clamp a width measured in the ZOOMED style, so a fixed
      // ceiling would ellipsize, at 200 per cent, a name that fits in full at
      // 100 — truncation the learner would read as a bug in her mask.
      const LearningMask mask = LearningMask(
        maskId: 'm_zoom-label-fixture',
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
                // Long enough to reach the ceiling at either level.
                name: 'A very long field name indeed, and then some more',
                length: 40,
                equalGroup: 0,
                role1: FieldRole.question,
                role2: FieldRole.answer,
              ),
            ],
          ),
        ],
      );

      Future<double> labelWidthAt(int zoomPercent) async {
        late double width;
        await tester.pumpWidget(
          MaterialApp(
            theme: LearnAnywhereTheme.light(zoomPercent: zoomPercent),
            home: Builder(
              builder: (BuildContext context) {
                width = computeFieldLabelWidth(context, mask);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        return width;
      }

      expect(
        await labelWidthAt(100),
        LearnAnywhereTokens.fieldLabelMaxWidth,
      );
      expect(
        await labelWidthAt(200),
        LearnAnywhereTokens.fieldLabelMaxWidth * 2,
      );
    });

    test('every theme scales, and 100 per cent changes nothing', () {
      for (final ThemeData Function({int zoomPercent}) build
          in <ThemeData Function({int zoomPercent})>[
            LearnAnywhereTheme.light,
            LearnAnywhereTheme.dark,
            LearnAnywhereTheme.darkBlue,
            LearnAnywhereTheme.lightBlue,
          ]) {
        expect(
          build(zoomPercent: 100).textTheme.titleMedium!.fontSize,
          build().textTheme.titleMedium!.fontSize,
        );
        expect(
          build(zoomPercent: 150).textTheme.titleMedium!.fontSize,
          build().textTheme.titleMedium!.fontSize! * 1.5,
        );
      }
    });
  });

  group('localizations', () {
    testWidgets('resolves German messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('de'),
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          home: _LocalizationProbe(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frage'), findsOneWidget);
    });
  });

  group('help viewer', () {
    // `rootBundle` caches every asset it reads, and those cached futures were
    // created inside the previous test's async zone — reused from the next
    // test they never deliver, and the viewer renders its blank pre-load frame
    // forever. Purely an artefact of running many tests in one process; a real
    // app has one zone and wants the cache. Without this, only the first test
    // in this group can pass.
    //
    // Cleared on the way out as well as in, so the next asset-reading test
    // added to this file does not inherit this group's poisoned cache.
    setUp(rootBundle.clear);
    tearDown(rootBundle.clear);

    // The Android shell shows one chapter and nothing else: the rest of the
    // guide describes menus, F-keys, editors and Level Learning that the phone
    // does not have, so a contents list would be a list of dead ends.
    testWidgets('single-chapter mode shows only that chapter', (
      WidgetTester tester,
    ) async {
      await _pumpHelpViewer(
        tester,
        const HelpViewer(singleChapterFileName: '14-android-companion.md'),
      );

      expect(find.text('The Android companion'), findsOneWidget);
      // No contents list, no search box, and no other chapter's title.
      expect(find.text('Contents'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Getting started'), findsNothing);
    });

    testWidgets('the full viewer still lists every chapter', (
      WidgetTester tester,
    ) async {
      await _pumpHelpViewer(tester, const HelpViewer());

      expect(find.text('Contents'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      // findsWidgets, not findsOneWidget: the opening chapter is 00-index,
      // whose own table of chapters repeats the titles the contents list
      // beside it already shows.
      expect(find.text('Getting started'), findsWidgets);
      expect(find.text('The Android companion'), findsWidgets);
    });

    testWidgets('an unknown chapter name reports the guide as unavailable', (
      WidgetTester tester,
    ) async {
      await _pumpHelpViewer(
        tester,
        const HelpViewer(singleChapterFileName: 'no-such-chapter.md'),
      );

      expect(find.text('Contents'), findsNothing);
      expect(
        find.textContaining('user guide'),
        findsWidgets,
        reason: 'the viewer must say the guide is unavailable, not crash or '
            'silently fall back to an unrelated chapter',
      );
    });
  });

  group('rich text renderer', () {
    test('renders plain values as a single text span', () {
      final TextSpan span = LearnAnywhereRichTextRenderer.spanForFieldValue(
        const FieldValue.plain('plain'),
        baseStyle: const TextStyle(fontSize: 18),
      );

      expect(span.text, 'plain');
      expect(span.style?.fontSize, 18);
      expect(span.children, isNull);
    });

    test('maps rich runs to Flutter text span styles', () {
      final TextSpan span = LearnAnywhereRichTextRenderer.spanForFieldValue(
        FieldValue.rich(<RichTextRun>[
          const RichTextRun(
            text: 'lapin',
            bold: true,
            italic: true,
            underline: true,
            color: '#CC0000',
            highlight: '#FFFF00',
          ),
        ]),
      );
      final TextSpan child = span.children!.single as TextSpan;

      expect(child.text, 'lapin');
      expect(child.style?.fontWeight, FontWeight.bold);
      expect(child.style?.fontStyle, FontStyle.italic);
      expect(child.style?.decoration, TextDecoration.underline);
      expect(child.style?.color, const Color(0xFFCC0000));
      // decorationColor should match explicit text color so underline is visible.
      expect(child.style?.decorationColor, const Color(0xFFCC0000));
      expect(child.style?.backgroundColor, const Color(0xFFFFFF00));
    });

    test('underline without explicit color inherits fallback decoration color', () {
      final TextSpan span = LearnAnywhereRichTextRenderer.spanForRun(
        const RichTextRun(text: 'x', underline: true),
        fallbackDecorationColor: const Color(0xFFFFFFFF),
      );
      expect(span.style?.decorationColor, const Color(0xFFFFFFFF));
      expect(span.style?.color, isNull);
    });

    testWidgets('widget displays stored field text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LearnAnywhereRichText(value: FieldValue.plain('visible')),
        ),
      );

      final RichText richText = tester.widget(find.byType(RichText));
      expect(richText.text.toPlainText(), 'visible');
    });

    test('remaps legacy yellow highlight to a dark equivalent in dark mode', () {
      final TextSpan light = LearnAnywhereRichTextRenderer.spanForRun(
        const RichTextRun(text: 'x', highlight: '#FFFF00'),
      );
      expect(light.style?.backgroundColor, const Color(0xFFFFFF00));

      final TextSpan dark = LearnAnywhereRichTextRenderer.spanForRun(
        const RichTextRun(text: 'x', highlight: '#FFFF00'),
        brightness: Brightness.dark,
      );
      expect(dark.style?.backgroundColor, colorFromHex('#8D6E00'));
    });
  });

  group('highlight palette', () {
    test('selects a distinct palette per brightness', () {
      expect(
        LearnAnywherePalette.highlightsFor(Brightness.light),
        same(LearnAnywherePalette.lightHighlights),
      );
      expect(
        LearnAnywherePalette.highlightsFor(Brightness.dark),
        same(LearnAnywherePalette.darkHighlights),
      );
    });

    test('maps light highlights to dark equivalents only in dark mode', () {
      expect(
        LearnAnywherePalette.highlightForBrightness('#FFE066', Brightness.light),
        '#FFE066',
      );
      expect(
        LearnAnywherePalette.highlightForBrightness('#FFE066', Brightness.dark),
        '#8D6E00',
      );
      // Unknown (already dark) values pass through untouched.
      expect(
        LearnAnywherePalette.highlightForBrightness('#0D47A1', Brightness.dark),
        '#0D47A1',
      );
    });
  });

  group('rich text editing controller', () {
    test('formats only the selected range', () {
      final LearnAnywhereRichTextEditingController controller =
          LearnAnywhereRichTextEditingController(
            value: const FieldValue.plain('hello'),
          );
      addTearDown(controller.dispose);

      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
      controller.formatSelection((RunFormat f) => f.copyWith(bold: true));

      expect(
        controller.fieldValue,
        FieldValue.rich(<RichTextRun>[
          const RichTextRun(text: 'he', bold: true),
          const RichTextRun(text: 'llo'),
        ]),
      );
      expect(
        controller.selectionSatisfies((RunFormat f) => f.bold),
        isTrue,
        reason: 'the formatted selection now reports as bold',
      );
    });

    test('a collapsed caret arms the format for the next typed text', () {
      final LearnAnywhereRichTextEditingController controller =
          LearnAnywhereRichTextEditingController(
            value: const FieldValue.plain('ab'),
          );
      addTearDown(controller.dispose);

      controller.selection = const TextSelection.collapsed(offset: 2);
      controller.formatSelection((RunFormat f) => f.copyWith(italic: true));
      expect(controller.activeFormat.italic, isTrue);

      // Simulate typing "c" at the caret.
      controller.value = const TextEditingValue(
        text: 'abc',
        selection: TextSelection.collapsed(offset: 3),
      );

      expect(
        controller.fieldValue,
        FieldValue.rich(<RichTextRun>[
          const RichTextRun(text: 'ab'),
          const RichTextRun(text: 'c', italic: true),
        ]),
      );
    });

    test('applies and clears a text color across a partial selection', () {
      final LearnAnywhereRichTextEditingController controller =
          LearnAnywhereRichTextEditingController(
            value: const FieldValue.plain('hello'),
          );
      addTearDown(controller.dispose);

      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      controller.formatSelection((RunFormat f) => f.withColor('#1565C0'));

      expect(
        controller.fieldValue,
        FieldValue.rich(<RichTextRun>[
          const RichTextRun(text: 'h'),
          const RichTextRun(text: 'ell', color: '#1565C0'),
          const RichTextRun(text: 'o'),
        ]),
      );
    });

    test('preserves a loaded rich value as its field value', () {
      final FieldValue original = FieldValue.rich(<RichTextRun>[
        const RichTextRun(text: 'ab', bold: true),
        const RichTextRun(text: 'cd', highlight: '#FFE066'),
      ]);
      final LearnAnywhereRichTextEditingController controller =
          LearnAnywhereRichTextEditingController(value: original);
      addTearDown(controller.dispose);

      expect(controller.fieldValue, original);
    });
  });
}

/// Pumps [viewer] on a surface wide enough for the side-by-side layout.
///
/// ui_kit's own tests see the bundled chapters under their bare asset keys
/// (`assets/help/en/...`), so the real guide loads here — the viewer is
/// exercised against the chapters that actually ship, not a fixture.
Future<void> _pumpHelpViewer(WidgetTester tester, HelpViewer viewer) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      home: viewer,
    ),
  );

  // The viewer reads its chapters from the asset bundle, which is real file
  // I/O. A test body runs on a fake clock that such I/O does not advance, so
  // `pumpAndSettle` alone returns with the load still in flight and the viewer
  // rendering its blank pre-load frame. `runAsync` hands control back to the
  // real event loop so the reads can finish.
  //
  // Polled rather than given one fixed delay: reading fifteen chapters takes
  // as long as the host takes, and a delay tuned on a warm machine is a test
  // that fails on a cold or loaded one. The pre-load frame is the only state
  // with no text in it at all, so any Text means the load has landed.
  await _pumpUntil(tester, () => find.byType(Text).evaluate().isNotEmpty);
}

/// Pumps, yielding to real async work between frames, until [ready] holds.
///
/// Fails the test rather than hanging if the condition never becomes true.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() ready, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    if (ready()) {
      return;
    }
  }
  fail('timed out waiting for the help viewer to finish loading');
}

final class _LocalizationProbe extends StatelessWidget {
  const _LocalizationProbe();

  @override
  Widget build(BuildContext context) {
    return Text(
      LearnAnywhereLocalizations.of(
        context,
      ).message(LearnAnywhereMessage.learnPrompt),
    );
  }
}
