import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

    test(
      'the muted foreground clears WCAG text contrast on every theme',
      () {
        // Resolved exactly the way the mask sync dialog resolves it: the
        // theme's own opt-in color first, `onSurfaceVariant` otherwise — so
        // this fails the moment either drifts back under the floor.
        for (final ThemeData theme in <ThemeData>[
          LearnAnywhereTheme.light(),
          LearnAnywhereTheme.dark(),
          LearnAnywhereTheme.darkBlue(),
          LearnAnywhereTheme.lightBlue(),
        ]) {
          final Color foreground = LearnAnywhereChromeTheme.mutedForegroundOf(
            theme,
          );
          final double ratio = _contrastRatio(
            foreground,
            theme.colorScheme.surfaceContainerHigh,
          );
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'muted foreground vs surfaceContainerHigh in the theme whose '
                'surface is ${theme.colorScheme.surface}',
          );
        }
      },
    );

    test('text colour 1 is legible on every background a formatted value sits '
        'on, stands out from the normal text, and never shares the correction '
        'colour\'s hue', () {
      for (final (String name, ThemeData theme) in <(String, ThemeData)>[
        ('Light', LearnAnywhereTheme.light()),
        ('Dark', LearnAnywhereTheme.dark()),
        ('Dark Blue', LearnAnywhereTheme.darkBlue()),
        ('Light Blue', LearnAnywhereTheme.lightBlue()),
      ]) {
        final LearnAnywhereFormatColours colours = theme
            .extension<LearnAnywhereFormatColours>()!;
        for (final (String background, Color colour)
            in _formattedValueBackgrounds(theme)) {
          final double ratio = _contrastRatio(colours.text1, colour);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$name: text colour 1 on $background is '
                '${ratio.toStringAsFixed(2)}:1',
          );
        }
        // Small dark text loses its colour, so a light theme needs more
        // separation than a dark one to show it: Light's #0D47A1 (0.25) and
        // Light Blue's #6A1B9A (0.22) read as the normal text, while Dark
        // Blue's mint (0.20) stands out clearly.
        final double fromText = _oklabDistance(
          colours.text1,
          theme.colorScheme.onSurface,
        );
        expect(
          fromText,
          greaterThanOrEqualTo(
            theme.brightness == Brightness.light ? 0.30 : 0.18,
          ),
          reason:
              '$name: text colour 1 is only ${fromText.toStringAsFixed(3)} '
              'from the normal text in OKLab',
        );
        // Only a guard against the very same hue: a field with mistakes never
        // shows its own formatting, so the two are not drawn side by side.
        expect(
          _hueDistance(colours.text1, colours.correction),
          greaterThanOrEqualTo(20),
          reason: '$name: text colour 1 vs the correction colour',
        );
      }
    });

    test('highlight 1 keeps the theme\'s default text legible and stands '
        'out in lightness and hue from every background a formatted value '
        'sits on', () {
      for (final (String name, ThemeData theme) in <(String, ThemeData)>[
        ('Light', LearnAnywhereTheme.light()),
        ('Dark', LearnAnywhereTheme.dark()),
        ('Dark Blue', LearnAnywhereTheme.darkBlue()),
        ('Light Blue', LearnAnywhereTheme.lightBlue()),
      ]) {
        final LearnAnywhereFormatColours colours = theme
            .extension<LearnAnywhereFormatColours>()!;
        final double onHighlight = _contrastRatio(
          theme.colorScheme.onSurface,
          colours.highlight1,
        );
        expect(
          onHighlight,
          greaterThanOrEqualTo(4.5),
          reason:
              '$name: onSurface on highlight 1 is '
              '${onHighlight.toStringAsFixed(2)}:1',
        );
        for (final (String background, Color colour)
            in _formattedValueBackgrounds(theme)) {
          final double ratio = _contrastRatio(colours.highlight1, colour);
          expect(
            ratio,
            greaterThanOrEqualTo(1.5),
            reason:
                '$name: highlight 1 on $background is '
                '${ratio.toStringAsFixed(2)}:1',
          );
          expect(
            _hueDistance(colours.highlight1, colour),
            greaterThanOrEqualTo(60),
            reason: '$name: highlight 1 vs $background in hue',
          );
        }
      }
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

  group('content frame', () {
    const Key childKey = Key('framedChild');

    /// Pumps a frame on a [surface]-wide window.
    ///
    /// The surface is the window rather than an inner box, because the frames
    /// under test are wider than the suite's 800-wide default — and the rule
    /// is to widen the surface, never to shrink the interface to fit it.
    Future<void> pumpFrame(
      WidgetTester tester, {
      required double surface,
      required double maxWidth,
      bool enabled = true,
    }) async {
      tester.view.physicalSize = Size(surface, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentFrame(
              maxWidth: maxWidth,
              enabled: enabled,
              // A child that takes everything it is offered, so its rect IS
              // the frame's rect and the margins are what is left over.
              child: const SizedBox.expand(
                child: ColoredBox(color: Color(0xFF000000), key: childKey),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('centres horizontally and anchors to the top on a wide surface',
        (WidgetTester tester) async {
      await pumpFrame(tester, surface: 1600, maxWidth: 900);

      final Rect child = tester.getRect(find.byKey(childKey));
      expect(child.width, 900);
      // Equal margins either side of an 1600-wide surface.
      expect(child.left, closeTo(350, 0.01));
      expect(child.right, closeTo(1250, 0.01));
      // Full height, starting at the top: the frame must not centre
      // vertically, or the mask would jump every time the feedback line
      // appears under it.
      expect(child.top, 0);
      expect(child.height, 400);
    });

    testWidgets('becomes the viewport once the surface is narrower than it',
        (WidgetTester tester) async {
      await pumpFrame(tester, surface: 700, maxWidth: 900);

      final Rect child = tester.getRect(find.byKey(childKey));
      expect(child.left, 0);
      expect(child.width, 700);
    });

    testWidgets('never exceeds the window, at any window width',
        (WidgetTester tester) async {
      // The structural half of "no horizontal scrollbar on the page itself":
      // the frame clamps rather than scrolls, so as long as it never grows
      // past the window nothing can be pushed off the side of the page.
      for (final double surface in <double>[320, 700, 900, 901, 1600, 3000]) {
        await pumpFrame(tester, surface: surface, maxWidth: 900);
        expect(
          tester.getRect(find.byKey(childKey)).width,
          lessThanOrEqualTo(surface),
          reason: 'on a $surface-wide window',
        );
        expect(tester.takeException(), isNull, reason: 'on a $surface window');
      }
    });

    testWidgets('takes the whole surface when switched off',
        (WidgetTester tester) async {
      await pumpFrame(tester, surface: 1600, maxWidth: 900, enabled: false);

      final Rect child = tester.getRect(find.byKey(childKey));
      expect(child.left, 0);
      expect(child.width, 1600);
    });
  });

  group('content frame width', () {
    LearningMask maskOfFieldLength(int length) => LearningMask(
      maskId: 'm_new_frame-width',
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
              name: 'Question',
              length: length,
              equalGroup: 0,
              role1: FieldRole.question,
              role2: FieldRole.answer,
            ),
          ],
        ),
      ],
    );

    Future<BuildContext> pumpProbe(WidgetTester tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return captured;
    }

    testWidgets('follows the deck once the mask outgrows the floor',
        (WidgetTester tester) async {
      final BuildContext context = await pumpProbe(tester);

      final double narrow = deckContentFrameWidth(
        context,
        maskOfFieldLength(10),
        minimumWidth: 600,
      );
      final double wide = deckContentFrameWidth(
        context,
        maskOfFieldLength(200),
        minimumWidth: 600,
      );
      expect(wide, greaterThan(narrow));
    });

    testWidgets('never falls below the floor its control rows need',
        (WidgetTester tester) async {
      final BuildContext context = await pumpProbe(tester);

      // A deck of very short fields: the mask alone would derive a frame far
      // narrower than any button row, which is the case the floor exists for.
      expect(
        deckContentFrameWidth(context, maskOfFieldLength(1), minimumWidth: 600),
        greaterThanOrEqualTo(600),
      );
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
        theme: LearnAnywhereTheme.light(),
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
            color: TextColourToken.text1,
            highlight: HighlightToken.highlight1,
          ),
        ]),
        theme: LearnAnywhereTheme.light(),
      );
      final TextSpan child = span.children!.single as TextSpan;
      final LearnAnywhereFormatColours colours = LearnAnywhereTheme.light()
          .extension<LearnAnywhereFormatColours>()!;
      final Color text1 = colours.text1;

      expect(child.text, 'lapin');
      expect(child.style?.fontWeight, FontWeight.bold);
      expect(child.style?.fontStyle, FontStyle.italic);
      expect(child.style?.decoration, TextDecoration.underline);
      expect(child.style?.color, text1);
      // decorationColor should match explicit text color so underline is visible.
      expect(child.style?.decorationColor, text1);
      expect(child.style?.backgroundColor, colours.highlight1);
    });

    test('underline without explicit color inherits fallback decoration color', () {
      final TextSpan span = LearnAnywhereRichTextRenderer.spanForRun(
        const RichTextRun(text: 'x', underline: true),
        theme: LearnAnywhereTheme.light(),
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

    final Map<String, ThemeData Function()> themeBuilders =
        <String, ThemeData Function()>{
          'Light': LearnAnywhereTheme.light,
          'Dark': LearnAnywhereTheme.dark,
          'Dark Blue': LearnAnywhereTheme.darkBlue,
          'Light Blue': LearnAnywhereTheme.lightBlue,
        };

    for (final MapEntry<String, ThemeData Function()> entry
        in themeBuilders.entries) {
      test('a text1 run resolves to ${entry.key}\'s text colour 1', () {
        final ThemeData theme = entry.value();
        final LearnAnywhereFormatColours? colours = theme
            .extension<LearnAnywhereFormatColours>();
        expect(colours, isNotNull);

        final TextSpan span = LearnAnywhereRichTextRenderer.spanForRun(
          const RichTextRun(
            text: 'x',
            underline: true,
            color: TextColourToken.text1,
          ),
          theme: theme,
          fallbackDecorationColor: const Color(0xFF000000),
        );
        expect(span.style?.color, colours!.text1);
        expect(span.style?.decorationColor, colours.text1);
      });

      test('a highlight1 run resolves to ${entry.key}\'s highlight 1', () {
        final ThemeData theme = entry.value();
        final LearnAnywhereFormatColours? colours = theme
            .extension<LearnAnywhereFormatColours>();
        expect(colours, isNotNull);

        final TextSpan span = LearnAnywhereRichTextRenderer.spanForRun(
          const RichTextRun(text: 'x', highlight: HighlightToken.highlight1),
          theme: theme,
        );
        expect(span.style?.backgroundColor, colours!.highlight1);
        // The highlight changes the ground only; the text keeps the theme's.
        expect(span.style?.color, isNull);
      });

      test('a correction mark resolves to ${entry.key}\'s correction colour', () {
        final ThemeData theme = entry.value();
        final LearnAnywhereFormatColours? colours = theme
            .extension<LearnAnywhereFormatColours>();
        expect(colours, isNotNull);

        final TextSpan span = LearnAnywhereRichTextRenderer.spanForRun(
          // A stored colour under the mark must not win over the mark.
          const RichTextRun(
            text: 'x',
            underline: true,
            color: TextColourToken.text1,
            correctionMark: true,
          ),
          theme: theme,
        );
        expect(span.style?.color, colours!.correction);
        // The missing-character underline is drawn in the mark's colour too.
        expect(span.style?.decorationColor, colours.correction);
      });
    }

    test('Dark Blue\'s correction colour is not its yellow primary', () {
      // Dark Blue's primary (#FFC600) is almost the old dark-theme amber, so a
      // mark in that amber would read as ordinary accented chrome.
      final ThemeData theme = LearnAnywhereTheme.darkBlue();
      final Color correction = theme
          .extension<LearnAnywhereFormatColours>()!
          .correction;
      expect(
        _hueDistance(correction, theme.colorScheme.primary),
        greaterThan(30),
      );
    });

    testWidgets('the widget draws a correction mark from the ambient theme', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = LearnAnywhereTheme.darkBlue();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: LearnAnywhereRichText(
            value: FieldValue.rich(<RichTextRun>[
              const RichTextRun(text: 'ok'),
              const RichTextRun(text: 'x', correctionMark: true),
            ]),
          ),
        ),
      );

      final RichText richText = tester.widget(find.byType(RichText));
      final TextSpan mark =
          (richText.text as TextSpan).children!.last as TextSpan;
      expect(
        mark.style?.color,
        theme.extension<LearnAnywhereFormatColours>()!.correction,
      );
    });
  });

  group('speaking through the host', () {
    const SpeechVoice french = SpeechVoice(
      id: 'Microsoft Hortense',
      name: 'Microsoft Hortense',
      language: 'fr-FR',
    );
    const SpeechUtterance first = SpeechUtterance(
      fieldId: 0,
      text: 'anniversaire',
      language: 'fr-FR',
      voice: french,
    );
    const SpeechUtterance second = SpeechUtterance(
      fieldId: 1,
      text: 'maison',
      language: 'fr-FR',
      voice: french,
    );

    test('a second utterance waits for the first to be over', () async {
      final _FakeFlutterTts host = _FakeFlutterTts();
      final FlutterTtsEngine engine = FlutterTtsEngine(tts: host);

      // What reading a two-field answer does: one after the other, awaited.
      final Future<void> sequence = Future<void>(() async {
        await engine.speak(first);
        await engine.speak(second);
      });
      await pumpEventQueue();
      // The second has not started: without this the first would be cut off
      // and only the last field of an answer would ever be heard.
      expect(host.spoken, <String>['anniversaire']);

      host.reportComplete();
      await pumpEventQueue();
      expect(host.spoken, <String>['anniversaire', 'maison']);

      host.reportComplete();
      await sequence;
    });

    test('an utterance the host refuses does not stall the next one', () async {
      // The plugin answers 0 when it will not speak. No completion is ever
      // reported for one of those, so waiting on it would wedge the sequence.
      final _FakeFlutterTts host = _FakeFlutterTts()..accepts = 0;
      final FlutterTtsEngine engine = FlutterTtsEngine(tts: host);

      await Future<void>(() async {
        await engine.speak(first);
        await engine.speak(second);
      }).timeout(const Duration(seconds: 5));
      expect(host.spoken, <String>['anniversaire', 'maison']);
    });

    test('stop ends the wait for what was being said', () async {
      final _FakeFlutterTts host = _FakeFlutterTts();
      final FlutterTtsEngine engine = FlutterTtsEngine(tts: host);

      final Future<void> speaking = engine.speak(first);
      await pumpEventQueue();
      // A host that reports no cancel of its own must not leave the caller
      // waiting on a word that is no longer being said.
      await engine.stop();
      await speaking.timeout(const Duration(seconds: 5));
    });

    test('a cancel report from the utterance being replaced does not end its '
        'successor', () async {
      final _FakeFlutterTts host = _FakeFlutterTts();
      final FlutterTtsEngine engine = FlutterTtsEngine(tts: host);

      final Future<void> speaking = engine.speak(first);
      await pumpEventQueue();

      // The next request stops the host on its way in, and the host reports
      // that cancel while the new utterance is still being set up.
      host.onSetVoice = host.reportCancel;
      final Future<void> next = engine.speak(second);
      await pumpEventQueue();
      await speaking;

      bool ended = false;
      unawaited(next.then((_) => ended = true));
      await pumpEventQueue();
      expect(
        ended,
        isFalse,
        reason: 'the cancel belonged to the utterance being replaced',
      );

      host.reportComplete();
      await next.timeout(const Duration(seconds: 5));
    });
  });

  group('the lead-in that wakes the audio output', () {
    const SpeechVoice french = SpeechVoice(
      id: 'Microsoft Hortense',
      name: 'Microsoft Hortense',
      language: 'fr-FR',
    );
    SpeechUtterance say(String text, {bool leadIn = true}) => SpeechUtterance(
      fieldId: 0,
      text: text,
      language: 'fr-FR',
      voice: french,
      leadIn: leadIn,
    );

    group('on Windows, a muted filler', () {
      test('is said at volume 0 and cut off before the word, which is said '
          'at full volume', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.windows,
        );

        final Future<void> speaking = engine.speak(say('chat'));
        await Future<void>.delayed(
          FlutterTtsEngine.windowsLeadIn + const Duration(milliseconds: 100),
        );
        // The filler is the word's own text, so it is in the same voice and
        // language, repeated so it outlasts the lead-in and is always cut.
        final String filler = host.spoken.first;
        expect(filler, startsWith('chat chat'));
        expect(host.log, <String>[
          'stop', // whatever was being said before
          'volume 0.0',
          'speak $filler',
          'stop', // the filler, cut once the output is awake
          'volume 1.0',
          'speak chat',
        ]);

        host.reportComplete();
        await speaking.timeout(const Duration(seconds: 5));
      });

      test('is not played for an utterance that carries no lead-in, whose '
          'volume is still set to full', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.windows,
        );

        final Future<void> speaking = engine.speak(
          say('maison', leadIn: false),
        );
        await pumpEventQueue();
        // Volume is host-wide state: never trust an earlier word to have
        // restored it.
        expect(host.log, <String>['stop', 'volume 1.0', 'speak maison']);

        host.reportComplete();
        await speaking.timeout(const Duration(seconds: 5));
      });

      test('is replaced, word and all, by a newer utterance', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.windows,
        );

        final Future<void> first = engine.speak(say('chat'));
        await pumpEventQueue();
        final Future<void> second = engine.speak(say('chien'));
        await first.timeout(const Duration(seconds: 5));
        await Future<void>.delayed(
          FlutterTtsEngine.windowsLeadIn + const Duration(milliseconds: 100),
        );
        expect(host.spoken, isNot(contains('chat')));
        expect(host.spoken.last, 'chien');

        host.reportComplete();
        await second.timeout(const Duration(seconds: 5));
      });

      test('is never handed over once a newer utterance arrived while it was '
          'being set up', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.windows,
        );
        Future<void>? second;
        host.onSetVolume = (double volume) {
          if (volume == 0.0 && second == null) {
            second = engine.speak(say('chien', leadIn: false));
          }
        };

        final Future<void> first = engine.speak(say('chat'));
        await first.timeout(const Duration(seconds: 5));
        await pumpEventQueue();
        // A filler handed over now would play among the newer word's setup,
        // and nothing would ever cut it.
        expect(host.spoken, <String>['chien']);

        host.reportComplete();
        await second!.timeout(const Duration(seconds: 5));
      });

      test('ends with stop, which says no word and stops the host', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.windows,
        );

        final Future<void> speaking = engine.speak(say('chat'));
        await pumpEventQueue();
        host.log.clear();
        await engine.stop();
        await speaking.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(
          FlutterTtsEngine.windowsLeadIn + const Duration(milliseconds: 100),
        );
        expect(host.log, <String>['stop']);
        expect(host.spoken, isNot(contains('chat')));
      });

      test('that the host refuses is skipped, and the word is still '
          'said', () async {
        final _FakeFlutterTts host = _FakeFlutterTts()
          ..acceptsFor = (String text) => text == 'chat' ? 1 : 0;
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.windows,
        );

        final Future<void> speaking = engine.speak(say('chat'));
        await pumpEventQueue();
        expect(host.spoken.last, 'chat');
        expect(host.log.last, 'speak chat');
        expect(host.log, contains('volume 1.0'));

        host.reportComplete();
        await speaking.timeout(const Duration(seconds: 5));
      });
    });

    group('on Android, an SSML break', () {
      test('goes in front of the word, in the same utterance', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.android,
        );

        final Future<void> speaking = engine.speak(say('chat'));
        await pumpEventQueue();
        // One utterance, no filler and no volume change: a separate stream
        // does nothing for Android's fade-in, silence inside this one does.
        expect(host.log, <String>[
          'stop',
          'speak <speak><break time="300ms"/>chat</speak>',
        ]);

        host.reportComplete();
        await speaking.timeout(const Duration(seconds: 5));
      });

      test('escapes the text, so a field can never break the markup', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.android,
        );

        final Future<void> speaking = engine.speak(say('Tom & <Jerry>'));
        await pumpEventQueue();
        expect(
          host.spoken.single,
          '<speak><break time="300ms"/>Tom &amp; &lt;Jerry&gt;</speak>',
        );

        host.reportComplete();
        await speaking.timeout(const Duration(seconds: 5));
      });

      test('is not added when the utterance carries no lead-in', () async {
        final _FakeFlutterTts host = _FakeFlutterTts();
        final FlutterTtsEngine engine = FlutterTtsEngine(
          tts: host,
          platform: TargetPlatform.android,
        );

        final Future<void> speaking = engine.speak(
          say('Tom & Jerry', leadIn: false),
        );
        await pumpEventQueue();
        expect(host.spoken.single, 'Tom & Jerry');

        host.reportComplete();
        await speaking.timeout(const Duration(seconds: 5));
      });
    });
  });

  group('speech rate', () {
    test('normal speed lands on the plugin scale\'s own normal', () {
      // The plugin takes 0.0..1.0 and treats 0.5 as the voice's normal speed
      // on both platforms that speak here.
      expect(FlutterTtsEngine.pluginSpeechRate(kDefaultSpeechRate), 0.5);
    });

    test('slower is below it and faster above it, never outside the scale', () {
      expect(
        FlutterTtsEngine.pluginSpeechRate(kMinSpeechRate),
        lessThan(FlutterTtsEngine.pluginSpeechRate(kDefaultSpeechRate)),
      );
      expect(
        FlutterTtsEngine.pluginSpeechRate(kMaxSpeechRate),
        greaterThan(FlutterTtsEngine.pluginSpeechRate(kDefaultSpeechRate)),
      );
      // A rate from a hand-edited settings file cannot push it off the scale.
      expect(FlutterTtsEngine.pluginSpeechRate(99), inInclusiveRange(0.0, 1.0));
      expect(FlutterTtsEngine.pluginSpeechRate(-99), inInclusiveRange(0.0, 1.0));
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

    test('applies a text color across a partial selection', () {
      final LearnAnywhereRichTextEditingController controller =
          LearnAnywhereRichTextEditingController(
            value: const FieldValue.plain('hello'),
          );
      addTearDown(controller.dispose);

      controller.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      controller.formatSelection(
        (RunFormat f) => f.withColor(TextColourToken.text1),
      );

      expect(
        controller.fieldValue,
        FieldValue.rich(<RichTextRun>[
          const RichTextRun(text: 'h'),
          const RichTextRun(text: 'ell', color: TextColourToken.text1),
          const RichTextRun(text: 'o'),
        ]),
      );
    });

    test('preserves a loaded rich value as its field value', () {
      final FieldValue original = FieldValue.rich(<RichTextRun>[
        const RichTextRun(text: 'ab', bold: true),
        const RichTextRun(text: 'cd', highlight: HighlightToken.highlight1),
      ]);
      final LearnAnywhereRichTextEditingController controller =
          LearnAnywhereRichTextEditingController(value: original);
      addTearDown(controller.dispose);

      expect(controller.fieldValue, original);
    });
  });
}

/// WCAG contrast ratio between two colors, from their relative luminances.
///
/// `(L1 + 0.05) / (L2 + 0.05)` with `L1` the lighter of the two, per the
/// WCAG 2.x definition — the same formula the ticket's measured ratios
/// (1.11:1, 1.29:1) came from.
double _contrastRatio(Color a, Color b) {
  final double lumA = _relativeLuminance(a);
  final double lumB = _relativeLuminance(b);
  final double lighter = lumA > lumB ? lumA : lumB;
  final double darker = lumA > lumB ? lumB : lumA;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Every background a formatted value is drawn on in [theme], by name.
///
/// The desktop learn session and unit editor paint each field's accent tint
/// over `surface`; the Android session paints its panels on
/// `surfaceContainerHighest` or, when highlighted, `primaryContainer`.
List<(String, Color)> _formattedValueBackgrounds(ThemeData theme) {
  final ColorScheme colors = theme.colorScheme;
  return <(String, Color)>[
    for (final FieldRole role in FieldRole.values)
      (
        'the desktop ${role.name} field tint',
        Color.alphaBlend(
          LearnAnywhereFieldAccents.backgroundFor(role, theme.brightness),
          colors.surface,
        ),
      ),
    ('the mobile surfaceContainerHighest panel', colors.surfaceContainerHighest),
    ('the mobile primaryContainer panel', colors.primaryContainer),
  ];
}

/// The angle between two colours' hues on the colour wheel, 0–180 degrees.
double _hueDistance(Color a, Color b) {
  final double gap = (HSVColor.fromColor(a).hue - HSVColor.fromColor(b).hue)
      .abs();
  return math.min(gap, 360 - gap);
}

/// Euclidean distance between two colours in OKLab, a perceptual colour space
/// where equal distances look roughly equally different.
double _oklabDistance(Color first, Color second) {
  final (double l1, double a1, double b1) = _oklab(first);
  final (double l2, double a2, double b2) = _oklab(second);
  return math.sqrt(
    math.pow(l1 - l2, 2) + math.pow(a1 - a2, 2) + math.pow(b1 - b2, 2),
  );
}

/// OKLab coordinates (lightness, a, b) of an sRGB colour.
(double, double, double) _oklab(Color color) {
  double linear(double srgb) {
    return srgb <= 0.04045
        ? srgb / 12.92
        : math.pow((srgb + 0.055) / 1.055, 2.4).toDouble();
  }

  final double r = linear(color.r);
  final double g = linear(color.g);
  final double b = linear(color.b);
  final double l = math
      .pow(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b, 1 / 3)
      .toDouble();
  final double m = math
      .pow(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b, 1 / 3)
      .toDouble();
  final double s = math
      .pow(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b, 1 / 3)
      .toDouble();
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
}

/// WCAG relative luminance of an sRGB color.
double _relativeLuminance(Color color) {
  double channel(double srgb) {
    return srgb <= 0.03928
        ? srgb / 12.92
        : math.pow((srgb + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
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

/// A `FlutterTts` that answers the way the plugin does, with no host behind it.
///
/// The completion, cancel and error reports arrive when a test says they do,
/// which is what makes the engine's timing — one utterance at a time, in mask
/// order — testable with no audio.
final class _FakeFlutterTts extends FlutterTts {
  /// What [speak] answers: 1 takes the utterance on, anything else refuses it.
  Object accepts = 1;

  /// Run while the voice is being set, to report something mid-setup.
  VoidCallback? onSetVoice;

  /// Every text handed over, in order.
  final List<String> spoken = <String>[];

  /// Every speak, stop and volume change, in the order the host saw them.
  final List<String> log = <String>[];

  /// What [speak] answers for a given text, overriding [accepts] when set.
  Object Function(String text)? acceptsFor;

  /// Run while the volume is being set, to make something happen mid-setup.
  void Function(double volume)? onSetVolume;

  VoidCallback? _completion;
  VoidCallback? _cancel;

  /// The host reporting that the utterance is over.
  void reportComplete() => _completion?.call();

  /// The host reporting that the utterance was cut off.
  void reportCancel() => _cancel?.call();

  @override
  void setCompletionHandler(VoidCallback callback) => _completion = callback;

  @override
  void setCancelHandler(VoidCallback callback) => _cancel = callback;

  @override
  void setErrorHandler(ErrorHandler handler) {}

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    onSetVoice?.call();
    return 1;
  }

  @override
  Future<dynamic> setVolume(double volume) async {
    log.add('volume $volume');
    onSetVolume?.call(volume);
    return 1;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    log.add('speak $text');
    return acceptsFor?.call(text) ?? accepts;
  }

  @override
  Future<dynamic> stop() async {
    log.add('stop');
    return 1;
  }
}
