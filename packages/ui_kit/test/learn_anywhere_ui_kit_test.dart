import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  group('themes', () {
    test('shared themes expose light and dark color schemes', () {
      expect(LearnAnywhereTheme.light().brightness, Brightness.light);
      expect(LearnAnywhereTheme.dark().brightness, Brightness.dark);
    });

    test('tokens expose fixed learning typography fallback', () {
      expect(LearnAnywhereTokens.monospaceFallback, contains('Cascadia Mono'));
      expect(
        LearnAnywhereTokens.smallRadius,
        const BorderRadius.all(Radius.circular(8)),
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
      expect(child.style?.backgroundColor, const Color(0xFFFFFF00));
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
  });
}
