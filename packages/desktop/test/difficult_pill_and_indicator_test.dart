import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/widgets/difficult_pill_and_indicator.dart';
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

LearningUnit _unit({
  DifficultFlags d1 = DifficultFlags.none,
  DifficultFlags d2 = DifficultFlags.none,
}) {
  return LearningUnit(
    categoryId: 1,
    fields: const <int, FieldValue>{},
    direction1Flags: d1,
    direction2Flags: d2,
  );
}

void main() {
  group('the indicator', () {
    testWidgets('with one direction in view shows only its flags, named as '
        'the badge names them', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _app(
          DifficultFlagIndicator(
            unit: _unit(d1: _manual, d2: _automatic),
            directions: const <QueryDirection>{QueryDirection.direction2},
          ),
        ),
      );
      expect(find.byTooltip('Automatic flag'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsNothing);
    });

    testWidgets('is empty when the unit is difficult only outside the view', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _app(
          DifficultFlagIndicator(
            unit: _unit(d2: _manual),
            directions: const <QueryDirection>{QueryDirection.direction1},
          ),
        ),
      );
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('with both directions in view shows every flag and names '
        'where each one sits', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _app(
          DifficultFlagIndicator(
            unit: _unit(d1: _both, d2: _automatic),
            directions: QueryDirection.values.toSet(),
          ),
        ),
      );
      expect(
        find.byTooltip(
          'Manual flag: Direction 1 · Automatic flag: Direction 1 and 2',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.flag), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('names the directions in German with the View\'s labels', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _app(
          DifficultFlagIndicator(
            unit: _unit(d1: _both, d2: _automatic),
            directions: QueryDirection.values.toSet(),
          ),
          locale: const Locale('de'),
        ),
      );
      expect(
        find.byTooltip(
          'Manuelle Kennzeichnung: Abfragerichtung 1 · '
          'Automatische Kennzeichnung: Abfragerichtung 1 und 2',
        ),
        findsOneWidget,
      );
    });
  });
}
