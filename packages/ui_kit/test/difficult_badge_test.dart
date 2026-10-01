import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

const DifficultFlags _manual = DifficultFlags(manual: true);
const DifficultFlags _automatic = DifficultFlags(automatic: true);
const DifficultFlags _both = DifficultFlags(manual: true, automatic: true);

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
    supportedLocales: LearnAnywhereLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

/// Pumps [app] and lets its localizations load.
Future<void> pumpApp(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  group('the badge', () {
    for (final (DifficultFlags flags, String tooltip, List<IconData> icons)
        in <(DifficultFlags, String, List<IconData>)>[
          (_manual, 'Manual flag', <IconData>[Icons.flag]),
          (_automatic, 'Automatic flag', <IconData>[Icons.auto_awesome]),
          (
            _both,
            'Manual and automatic flag',
            <IconData>[Icons.flag, Icons.auto_awesome],
          ),
        ]) {
      testWidgets('shows the icons of $flags, then "Difficult", and says '
          'which flag on hover', (WidgetTester tester) async {
        await pumpApp(tester, _app(DifficultBadge(flags: flags)));
        expect(find.text('Difficult'), findsOneWidget);
        expect(find.byTooltip(tooltip), findsOneWidget);
        expect(<IconData>[
          for (final Icon icon in tester.widgetList<Icon>(find.byType(Icon)))
            icon.icon!,
        ], icons);
      });
    }

    testWidgets('is absent for a direction without flags', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _app(const DifficultBadge(flags: DifficultFlags.none)),
      );
      expect(find.byKey(const Key('learnDifficultBadge')), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('speaks German', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _app(const DifficultBadge(flags: _both), locale: const Locale('de')),
      );
      expect(find.text('Schwierig'), findsOneWidget);
      expect(
        find.byTooltip('Manuelle und automatische Kennzeichnung'),
        findsOneWidget,
      );
    });
  });
}
