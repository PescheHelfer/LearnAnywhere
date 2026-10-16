import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/learn/learn_session_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

// The Sitting and Statistics time pills, driven by the fake clock: every step
// below pumps without advancing time unless a test says how long the learner
// took, so a pill's reading is exactly the seconds the test let pass.

const DesktopQueryOptions _bothClocks = DesktopQueryOptions(
  showUnitTime: true,
  showSittingTime: true,
);

const SessionParameters _thinkOnly = SessionParameters(
  withInput: false,
  mode: SessionMode.onceThrough,
  directionSelection: DirectionSelection.direction1,
  shuffle: false,
);

void main() {
  Future<void> open(
    WidgetTester tester, {
    DesktopQueryOptions options = _bothClocks,
    SessionParameters parameters = _thinkOnly,
    int statisticsSeconds = 0,
    int totalSeconds = 0,
    Size size = const Size(1400, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      // A fresh key, so a second open starts a new page rather than updating
      // the running one.
      _Harness(
        key: UniqueKey(),
        deck: _deck,
        options: options,
        parameters: parameters,
        statisticsSeconds: statisticsSeconds,
        totalSeconds: totalSeconds,
      ),
    );
    await tester.pump();
  }

  /// Lets the frame and its post-frame work run without moving the clock.
  Future<void> step(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('Start session'));
    await step(tester);
    expect(find.textContaining('Unit 1/2'), findsOneWidget);
  }

  /// Reveals a think-only card and picks [rating]. Nothing is recorded until
  /// [continueToNext].
  Future<void> rateThinkOnly(WidgetTester tester, String rating) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await step(tester);
    await tester.tap(find.text(rating));
    await step(tester);
  }

  Future<void> continueToNext(WidgetTester tester) async {
    await tester.tap(find.text('Continue'));
    await step(tester);
  }

  testWidgets('the Sitting time pill appears exactly when its option is on', (
    WidgetTester tester,
  ) async {
    await open(tester, options: const DesktopQueryOptions());
    await start(tester);
    expect(find.textContaining('Sitting time'), findsNothing);

    await open(tester, options: const DesktopQueryOptions(showSittingTime: true));
    await start(tester);
    expect(find.text('Sitting time: 0:00'), findsOneWidget);
    // Shown on its own: the unit clock is a separate option.
    expect(find.textContaining('Unit time'), findsNothing);
    expect(
      find.byTooltip(
        "This sitting's learning time: the time of every unit you rated, "
        'each counted at most five minutes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'the Sitting time pill ticks with the unit clock and does not jump when '
    'the unit is rated',
    (WidgetTester tester) async {
      await open(tester);
      await start(tester);
      expect(find.text('Sitting time: 0:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Unit time: 0:07'), findsOneWidget);
      expect(find.text('Sitting time: 0:07'), findsOneWidget);

      await rateThinkOnly(tester, 'Knew it');
      await continueToNext(tester);
      expect(find.textContaining('Unit 2/2'), findsOneWidget);
      // The unit clock starts afresh; the sitting keeps what it showed.
      expect(find.text('Unit time: 0:00'), findsOneWidget);
      expect(find.text('Sitting time: 0:07'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Unit time: 0:03'), findsOneWidget);
      expect(find.text('Sitting time: 0:10'), findsOneWidget);
    },
  );

  testWidgets(
    'a unit rated after six minutes adds five to the sitting time, while the '
    'Unit time pill still shows six',
    (WidgetTester tester) async {
      await open(tester);
      await start(tester);

      await tester.pump(const Duration(minutes: 6));
      expect(find.text('Unit time: 6:00'), findsOneWidget);
      // Capped live as well, so rating it cannot make the pill jump back.
      expect(find.text('Sitting time: 5:00'), findsOneWidget);

      await rateThinkOnly(tester, 'Knew it');
      await continueToNext(tester);
      expect(find.text('Sitting time: 5:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Sitting time: 5:10'), findsOneWidget);
    },
  );

  testWidgets('a No count rating still adds its time', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await start(tester);

    await tester.pump(const Duration(seconds: 20));
    await rateThinkOnly(tester, 'No count');
    await continueToNext(tester);
    expect(find.text('Sitting time: 0:20'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Sitting time: 0:25'), findsOneWidget);
  });

  testWidgets('a typed answer adds its time', (WidgetTester tester) async {
    await open(
      tester,
      parameters: const SessionParameters(
        mode: SessionMode.onceThrough,
        directionSelection: DirectionSelection.direction1,
        shuffle: false,
      ),
    );
    await start(tester);

    await tester.pump(const Duration(seconds: 12));
    await tester.enterText(find.byType(TextField), 'one');
    await tester.tap(find.text('Check'));
    await step(tester);
    await continueToNext(tester);
    expect(find.text('Sitting time: 0:12'), findsOneWidget);
  });

  testWidgets('a Level-Learning sitting counts as well', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      parameters: const SessionParameters(
        mode: SessionMode.levelLearning,
        directionSelection: DirectionSelection.direction1,
        // The ladder draws at random; one unit makes the draw known.
        startIndex: 1,
        endIndex: 1,
        shuffle: false,
      ),
    );
    await start(tester);

    // A fresh deck starts at the top of the ladder: memorize, then type.
    await tester.pump(const Duration(seconds: 9));
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await step(tester);
    await tester.enterText(find.byType(TextField), 'one');
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await step(tester);
    await continueToNext(tester);
    expect(find.text('Sitting time: 0:09'), findsOneWidget);
  });

  /// Answers both units, 30 and 15 seconds, so the once-through session
  /// reaches its completion view with 0:45 of sitting time.
  Future<void> finishSession(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 30));
    await rateThinkOnly(tester, 'Knew it');
    await continueToNext(tester);
    await tester.pump(const Duration(seconds: 15));
    await rateThinkOnly(tester, 'Knew it');
    await continueToNext(tester);
    expect(find.text('Extend session'), findsOneWidget);
  }

  _HarnessState harness(WidgetTester tester) =>
      tester.state<_HarnessState>(find.byType(_Harness));

  testWidgets('Extend session continues the sitting', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await start(tester);
    await finishSession(tester);

    await tester.tap(find.text('Extend session'));
    await step(tester);
    await start(tester);
    expect(find.text('Sitting time: 0:45'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Sitting time: 0:50'), findsOneWidget);
  });

  testWidgets('Practice setup starts a new sitting at zero', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await start(tester);
    await tester.pump(const Duration(seconds: 20));
    await rateThinkOnly(tester, 'Knew it');
    await continueToNext(tester);

    // Mid-session.
    harness(tester).choosePracticeSetup();
    await step(tester);
    await start(tester);
    expect(find.text('Sitting time: 0:00'), findsOneWidget);

    // And after Extend session, which it overrides.
    await finishSession(tester);
    await tester.tap(find.text('Extend session'));
    await step(tester);
    harness(tester).choosePracticeSetup();
    await step(tester);
    await start(tester);
    expect(find.text('Sitting time: 0:00'), findsOneWidget);
  });

  testWidgets('Learn with last settings starts a new sitting at zero', (
    WidgetTester tester,
  ) async {
    await open(tester);
    await start(tester);
    await finishSession(tester);

    harness(tester).learnWithLastSettings();
    await step(tester);
    expect(find.textContaining('Unit 1/2'), findsOneWidget);
    expect(find.text('Sitting time: 0:00'), findsOneWidget);
  });

  group('Statistics time', () {
    const DesktopQueryOptions statisticsClock = DesktopQueryOptions(
      showUnitTime: true,
      showStatisticsTime: true,
    );

    testWidgets('the pill appears exactly when its option is on, showing what '
        'the current statistics hold', (WidgetTester tester) async {
      await open(
        tester,
        options: const DesktopQueryOptions(),
        statisticsSeconds: 3665,
      );
      await start(tester);
      expect(find.textContaining('Statistics time'), findsNothing);

      await open(
        tester,
        options: const DesktopQueryOptions(showStatisticsTime: true),
        statisticsSeconds: 3665,
      );
      await start(tester);
      expect(find.text('Statistics time: 1:01:05'), findsOneWidget);
      // Shown on its own: the other clocks are separate options.
      expect(find.textContaining('Unit time'), findsNothing);
      expect(find.textContaining('Sitting time'), findsNothing);
      expect(
        find.byTooltip(
          'The learning time held by the current statistics since they were '
          'last cleared: the time of every unit you rated, each counted at '
          'most five minutes.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the pill ticks with the unit clock, and rating the unit moves '
        'its seconds into the statistics without the pill jumping', (
      WidgetTester tester,
    ) async {
      await open(tester, options: statisticsClock, statisticsSeconds: 100);
      await start(tester);
      expect(find.text('Statistics time: 1:40'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Statistics time: 1:47'), findsOneWidget);

      await rateThinkOnly(tester, 'Knew it');
      await continueToNext(tester);
      expect(find.text('Unit time: 0:00'), findsOneWidget);
      expect(find.text('Statistics time: 1:47'), findsOneWidget);
      expect(harness(tester).statisticsSeconds, 107);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Statistics time: 1:50'), findsOneWidget);
    });

    testWidgets('a unit rated after six minutes adds five, a No count one its '
        'time as well', (WidgetTester tester) async {
      await open(tester, options: statisticsClock);
      await start(tester);

      await tester.pump(const Duration(minutes: 6));
      expect(find.text('Unit time: 6:00'), findsOneWidget);
      expect(find.text('Statistics time: 5:00'), findsOneWidget);
      await rateThinkOnly(tester, 'Knew it');
      await continueToNext(tester);
      expect(harness(tester).statisticsSeconds, 300);

      await tester.pump(const Duration(seconds: 20));
      await rateThinkOnly(tester, 'No count');
      await continueToNext(tester);
      expect(harness(tester).statisticsSeconds, 320);
    });

    testWidgets('ending the sitting with the unit unrated keeps none of the '
        'seconds the pill showed for it', (WidgetTester tester) async {
      await open(tester, options: statisticsClock, statisticsSeconds: 100);
      await start(tester);
      await tester.pump(const Duration(seconds: 20));
      await rateThinkOnly(tester, 'Knew it');
      await continueToNext(tester);
      expect(harness(tester).statisticsSeconds, 120);

      // Unit 2 runs half a minute, shown but never rated.
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Statistics time: 2:30'), findsOneWidget);
      harness(tester).choosePracticeSetup();
      await step(tester);
      expect(harness(tester).statisticsSeconds, 120);

      // Unlike the sitting, the statistics time outlives the sitting.
      await start(tester);
      expect(find.text('Statistics time: 2:00'), findsOneWidget);
    });
  });

  group('the time pills break as one group', () {
    const DesktopQueryOptions allClocks = DesktopQueryOptions(
      showUnitTime: true,
      showSittingTime: true,
      showStatisticsTime: true,
      showTotalTime: true,
    );
    const List<String> timeLabels = <String>[
      'Unit time',
      'Sitting time',
      'Statistics time',
      'Total time',
    ];

    double top(WidgetTester tester, String label) =>
        tester.getTopLeft(find.textContaining('$label: ')).dy;

    testWidgets('they stay beside the counters when everything fits', (
      WidgetTester tester,
    ) async {
      await open(tester, options: allClocks, size: const Size(2400, 1000));
      await start(tester);
      for (final String label in timeLabels) {
        expect(top(tester, label), top(tester, 'Attempts'), reason: label);
      }
    });

    testWidgets('they move to a line of their own together rather than split '
        'across two', (WidgetTester tester) async {
      // Wide enough for the four clocks on one line, not beside the counters.
      await open(tester, options: allClocks, size: const Size(1500, 1000));
      await start(tester);
      final double line = top(tester, 'Unit time');
      expect(line, greaterThan(top(tester, 'Attempts')));
      for (final String label in timeLabels) {
        expect(top(tester, label), line, reason: label);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('Total time', () {
    const DesktopQueryOptions totalClock = DesktopQueryOptions(
      showUnitTime: true,
      showTotalTime: true,
    );

    testWidgets('the pill appears exactly when its option is on, showing what '
        'the all-time statistics hold', (WidgetTester tester) async {
      await open(
        tester,
        options: const DesktopQueryOptions(),
        totalSeconds: 45296,
      );
      await start(tester);
      expect(find.textContaining('Total time'), findsNothing);

      await open(
        tester,
        options: const DesktopQueryOptions(showTotalTime: true),
        statisticsSeconds: 60,
        totalSeconds: 45296,
      );
      await start(tester);
      expect(find.text('Total time: 12:34:56'), findsOneWidget);
      // Shown on its own: the other clocks are separate options.
      expect(find.textContaining('Unit time'), findsNothing);
      expect(find.textContaining('Sitting time'), findsNothing);
      expect(find.textContaining('Statistics time'), findsNothing);
      expect(
        find.byTooltip(
          'The learning time held by the all-time statistics: the time of '
          'every unit you rated, each counted at most five minutes. It counts '
          'only from the program version that began keeping it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the pill ticks with the unit clock, and rating the unit moves '
        'its seconds into the total without the pill jumping — a No count '
        'one too', (WidgetTester tester) async {
      await open(
        tester,
        options: totalClock,
        statisticsSeconds: 5,
        totalSeconds: 3600,
      );
      await start(tester);
      expect(find.text('Total time: 1:00:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      expect(find.text('Total time: 1:00:07'), findsOneWidget);

      await rateThinkOnly(tester, 'No count');
      await continueToNext(tester);
      expect(find.text('Unit time: 0:00'), findsOneWidget);
      expect(find.text('Total time: 1:00:07'), findsOneWidget);
      expect(harness(tester).totalSeconds, 3607);

      // Six minutes on one unit count as five.
      await tester.pump(const Duration(minutes: 6));
      expect(find.text('Total time: 1:05:07'), findsOneWidget);
      await rateThinkOnly(tester, 'Knew it');
      await continueToNext(tester);
      expect(harness(tester).totalSeconds, 3907);
    });
  });
}

/// Holds the statistics the page pushes back, as the shell's document does,
/// so a drill session can run to its end — the statistics and total time
/// included, which both grow by each recorded answer's learning seconds.
class _Harness extends StatefulWidget {
  const _Harness({
    super.key,
    required this.deck,
    required this.options,
    required this.parameters,
    this.statisticsSeconds = 0,
    this.totalSeconds = 0,
  });

  final LearningDeck deck;
  final DesktopQueryOptions options;
  final SessionParameters parameters;
  final int statisticsSeconds;
  final int totalSeconds;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  List<UnitStats> _statistics = const <UnitStats>[];
  List<LevelUnitStats> _levelStatistics = const <LevelUnitStats>[];
  late int statisticsSeconds = widget.statisticsSeconds;
  late int totalSeconds = widget.totalSeconds;
  int _resetSignal = 0;
  bool _startOnOpen = false;

  /// Mimics Learn ▸ Practice setup: back to the setup screen.
  void choosePracticeSetup() => setState(() => _resetSignal += 1);

  /// Mimics Learn ▸ Learn with last settings: straight into a session.
  void learnWithLastSettings() => setState(() => _startOnOpen = true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: LearnSessionPage(
          deck: widget.deck,
          statistics: _statistics,
          statisticsSeconds: statisticsSeconds,
          totalSeconds: totalSeconds,
          levelStatistics: _levelStatistics,
          resetToSetupSignal: _resetSignal,
          startSessionOnOpen: _startOnOpen,
          options: widget.options,
          parameters: widget.parameters,
          onParametersChanged: (SessionParameters _) {},
          onStatisticsChanged: (List<UnitStats> value) {
            setState(() => _statistics = value);
          },
          onLevelStatisticsChanged: (List<LevelUnitStats> value) {
            setState(() => _levelStatistics = value);
          },
          onAttemptRecorded: (RecordedAttempt attempt) {
            setState(() {
              statisticsSeconds += attempt.learningSeconds;
              totalSeconds += attempt.learningSeconds;
            });
          },
          onOpenEditor: () {},
          onExit: () {},
        ),
      ),
    );
  }
}

const LearningDeck _deck = LearningDeck(
  mask: LearningMask(
    maskId: 'm_new_sitting-time-fixture',
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
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: 'Answer',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
        ],
      ),
    ],
  ),
  units: <LearningUnit>[
    LearningUnit(
      categoryId: 0,
      fields: <int, FieldValue>{
        0: FieldValue.plain('eins'),
        1: FieldValue.plain('one'),
      },
    ),
    LearningUnit(
      categoryId: 0,
      fields: <int, FieldValue>{
        0: FieldValue.plain('zwei'),
        1: FieldValue.plain('two'),
      },
    ),
  ],
);
