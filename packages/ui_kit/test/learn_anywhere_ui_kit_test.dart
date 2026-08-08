import 'package:flutter/material.dart';
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
