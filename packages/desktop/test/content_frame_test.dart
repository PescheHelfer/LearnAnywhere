import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/editor/unit_editor_page.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/learn/learn_session_page.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  const LearningMask mask = LearningMask(
    maskId: 'm_new_content-frame-fixture',
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
  );

  final LearningDeck deck = LearningDeck(
    mask: mask,
    units: const <LearningUnit>[
      LearningUnit(
        categoryId: 0,
        fields: <int, FieldValue>{
          0: FieldValue.plain('eins'),
          1: FieldValue.plain('one'),
        },
      ),
    ],
  );

  Widget buildSession(Locale locale, {void Function(BuildContext)? report}) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              report?.call(context);
              return LearnSessionPage(
                startSessionOnOpen: true,
                deck: deck,
                statistics: const <UnitStats>[],
                // The clock adds the one optional pill, so the statistic row
                // laid out here is the widest the drill modes can produce.
                options: const DesktopQueryOptions(showClock: true),
                parameters: const SessionParameters(
                  // Typed input, so the view-toggle pill is present and the
                  // action row is at its widest.
                  withInput: true,
                  mode: SessionMode.onceThrough,
                  directionSelection: DirectionSelection.direction1,
                  shuffle: false,
                ),
                onParametersChanged: (SessionParameters _) {},
                onStatisticsChanged: (List<UnitStats> _) {},
                onOpenEditor: () {},
                onExit: () {},
              );
            },
          ),
        ),
      );

  Widget buildEditor(Locale locale, {void Function(BuildContext)? report}) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              report?.call(context);
              return UnitEditorPage(
                deck: deck,
                onChanged: (LearningDeck _, {int? insertedAt, int? deletedAt}) {},
                onDone: () {},
                onCancel: () {},
              );
            },
          ),
        ),
      );

  // `learnControlRowWidth` composes measured labels with constant chrome, and
  // the frame is computed from it before any of these rows exist. These tests
  // are what keep that composition honest: they lay the real rows out, in both
  // languages, and fail if the model has drifted from the widgets — a new
  // pill, a changed padding, a longer label.
  //
  // Both sides of the comparison use whatever font the test host provides, so
  // an inequality that holds here holds in the shipping font too.
  for (final (String language, Locale locale) in const <(String, Locale)>[
    ('English', Locale('en')),
    ('German', Locale('de')),
  ]) {
    testWidgets('the frame floor covers the $language control rows', (
      WidgetTester tester,
    ) async {
      // Far wider than the rows, so nothing wraps: a wrapped row measures
      // narrower than it really is and would let the floor pass by accident.
      tester.view.physicalSize = const Size(3000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late BuildContext context;
      await tester.pumpWidget(
        buildSession(locale, report: (BuildContext c) => context = c),
      );
      await tester.pumpAndSettle();

      final double floor = learnControlRowWidth(
        context,
        LearnAnywhereLocalizations.of(context),
      );

      final double statisticRow = tester
          .getSize(find.byKey(const Key('learnStatPills')))
          .width;
      expect(
        floor,
        greaterThanOrEqualTo(statisticRow),
        reason: 'the $language statistic pills lay out $statisticRow wide',
      );

      // Reveal, so the action and evaluation pills exist.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      final double actionRow =
          tester.getSize(find.byKey(const Key('learnActionPillsGroup'))).width +
          LearnAnywhereTokens.gapLarge +
          tester
              .getSize(find.byKey(const Key('learnEvaluationPillsGroup')))
              .width;
      expect(
        floor,
        greaterThanOrEqualTo(actionRow),
        reason:
            'the $language action and evaluation pills lay out $actionRow wide',
      );
    });

    testWidgets('the frame floor covers the $language editor action row', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(3000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late BuildContext context;
      await tester.pumpWidget(
        buildEditor(locale, report: (BuildContext c) => context = c),
      );
      await tester.pumpAndSettle();

      // The editor's eight icon buttons are the widest control row in either
      // screen, and the frame is sized for both screens at once — so this is
      // the row that actually decides the floor for a short-field deck.
      final double row = tester
          .getSize(find.byKey(const Key('editorActionRow')))
          .width;
      expect(
        editorControlRowWidth(
          context,
          LearnAnywhereLocalizations.of(context),
        ),
        greaterThanOrEqualTo(row),
        reason: 'the $language editor action row lays out $row wide',
      );
    });
  }

  testWidgets('a mask too wide for the frame scrolls inside its own container',
      (WidgetTester tester) async {
    // Narrower than this deck's mask however the frame is sized, so the mask
    // genuinely does not fit and has to fall back on its own scrolling.
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSession(const Locale('en')));
    await tester.pumpAndSettle();

    // The grid's own horizontal scroll view took up the slack...
    final Finder gridScroller = find
        .descendant(
          of: find.byType(FieldRowGrid),
          matching: find.byType(Scrollable),
        )
        .first;
    final ScrollPosition inner = tester
        .state<ScrollableState>(gridScroller)
        .position;
    expect(inner.axis, Axis.horizontal);
    expect(inner.maxScrollExtent, greaterThan(0));

    // ...and nothing above it scrolls the page sideways. Scoped to the grid's
    // own ancestors on purpose: a single-line TextField scrolls horizontally
    // inside itself, and that is not the page doing it.
    final Iterable<ScrollableState> page = tester.stateList<ScrollableState>(
      find.ancestor(
        of: find.byType(FieldRowGrid),
        matching: find.byType(Scrollable),
      ),
    );
    expect(page, isNotEmpty);
    for (final ScrollableState outer in page) {
      expect(
        outer.position.axis,
        Axis.vertical,
        reason: 'a page-level horizontal scroll appeared',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
