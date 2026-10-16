import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/learn/query_options_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

// The Advanced Learning Options page's time group: one heading over the four
// time options and the time limit, and a tooltip on each saying what it shows.

void main() {
  Future<List<DesktopQueryOptions>> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    int zoomPercent = LearnAnywhereZoom.normal,
  }) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final List<DesktopQueryOptions> changes = <DesktopQueryOptions>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: LearnAnywhereTheme.light(zoomPercent: zoomPercent),
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: QueryOptionsPage(
            options: const DesktopQueryOptions(),
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return changes;
  }

  testWidgets('the time options and the time limit sit under one Time display '
      'heading, in order', (WidgetTester tester) async {
    await open(tester);
    final List<String> labels = <String>[
      'Time display',
      'Unit time',
      'Sitting time',
      'Statistics time',
      'Total time',
      'Time limit (seconds)',
    ];
    final List<double> tops = <double>[
      for (final String label in labels)
        tester.getTopLeft(find.text(label)).dy,
    ];
    for (var i = 1; i < tops.length; i += 1) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: labels[i]);
    }
    expect(
      tester.getTopLeft(find.text('Minimum-attempts guard')).dy,
      greaterThan(tops.last),
    );
  });

  testWidgets('each time option says what it shows, and only Unit time is '
      'uncapped', (WidgetTester tester) async {
    await open(tester);
    for (final String tooltip in <String>[
      ('Shows how long the current unit has been on screen: the real time, '
          'with no cap. The time limit below applies to it.'),
      ("Shows this sitting's learning time: the time of every unit you rate, "
          'each counted at most five minutes.'),
      ('Shows the learning time held by the current statistics since they '
          'were last cleared: the time of every unit you rate, each counted at '
          'most five minutes.'),
      ('Shows the learning time held by the all-time statistics: the time of '
          'every unit you rate, each counted at most five minutes. It counts '
          'only from the program version that began keeping it.'),
      ("When one unit's time reaches this many seconds, a tone sounds and the "
          'Unit time pill is highlighted; the session goes on. 0 means no '
          'limit. Needs Unit time on.'),
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }
  });

  testWidgets('a time option still switches through its tooltip', (
    WidgetTester tester,
  ) async {
    final List<DesktopQueryOptions> changes = await open(tester);
    await tester.tap(find.text('Total time'));
    await tester.pump();
    expect(changes.single.showTotalTime, isTrue);
  });

  testWidgets('the German page names the group Zeitanzeige, without overflow '
      'at the widest zoom', (WidgetTester tester) async {
    await open(
      tester,
      locale: const Locale('de'),
      zoomPercent: LearnAnywhereZoom.maximum,
    );
    await tester.scrollUntilVisible(
      find.text('Zeitlimit (Sekunden)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Zeitanzeige'), findsOneWidget);
    expect(find.text('Allzeit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
