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

  // The floor composes measured labels with constant chrome, and the frame is
  // computed from it before any of these controls exist. These tests are what
  // keep that composition honest: they lay the real controls out, in both
  // languages, and fail if the model has drifted from the widgets — a new
  // pill, a changed padding, a longer label.
  //
  // What the floor guards is that nothing is *squeezed*. The rows themselves
  // are meant to wrap to the deck's width, so it is each unbreakable cluster
  // that is checked here, never the width of a whole row.
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

      final double floor = learnControlGroupWidth(
        context,
        LearnAnywhereLocalizations.of(context),
      );

      // Reveal, so the action and evaluation pills exist.
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.pumpAndSettle();

      // Each group is a FittedBox: a frame narrower than one of them shrinks
      // its text rather than moving it, which is the one thing the floor is
      // there to prevent. Their combined width is deliberately NOT checked —
      // the evaluation group dropping to its own line is a supported layout.
      for (final String group in <String>[
        'learnActionPillsGroup',
        'learnEvaluationPillsGroup',
      ]) {
        final double width = tester.getSize(find.byKey(Key(group))).width;
        expect(
          floor,
          greaterThanOrEqualTo(width),
          reason: 'the $language $group lays out $width wide',
        );
      }
    });

    testWidgets('the frame floor covers the widest $language editor button', (
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

      // The row is free to wrap to the deck's width; what the frame owes it is
      // that its widest single button is never squeezed. Measured against the
      // real buttons, so a longer label or a new one fails here.
      double widest = 0;
      for (final Element button in find
          .descendant(
            of: find.byKey(const Key('editorActionRow')),
            matching: find.byType(FilledButton),
          )
          .evaluate()) {
        widest = widest > button.size!.width ? widest : button.size!.width;
      }
      expect(widest, greaterThan(0));
      expect(
        editorControlButtonWidth(
          context,
          LearnAnywhereLocalizations.of(context),
        ),
        greaterThanOrEqualTo(widest),
        reason: 'the widest $language editor button lays out $widest wide',
      );
    });
  }

  testWidgets('a short deck wraps the editor row rather than widening the frame',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(3000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late BuildContext context;
    await tester.pumpWidget(
      buildEditor(const Locale('en'), report: (BuildContext c) => context = c),
    );
    await tester.pumpAndSettle();

    final LearnAnywhereLocalizations messages =
        LearnAnywhereLocalizations.of(context);
    final double frame = deckContentFrameWidth(
      context,
      mask,
      minimumWidth: editorControlButtonWidth(context, messages),
    );

    // The frame follows the deck, and this deck is narrower than its own
    // action row. The row is expected to wrap into it — the alternative,
    // holding the frame open at the row's full width, is what made a
    // short-field deck sit in a frame far wider than anything in it.
    final double row = tester
        .getSize(find.byKey(const Key('editorActionRow')))
        .width;
    expect(frame, lessThan(row));
    // But never so narrow that a single button has to be squeezed.
    expect(
      frame,
      greaterThanOrEqualTo(editorControlButtonWidth(context, messages)),
    );

    // And it really does wrap rather than overflow: laid out at the frame's
    // own inner width, the row takes more than one line and raises nothing.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: frame,
            child: UnitEditorPage(
              deck: deck,
              onChanged: (LearningDeck _, {int? insertedAt, int? deletedAt}) {},
              onDone: () {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size wrapped = tester.getSize(
      find.byKey(const Key('editorActionRow')),
    );
    final Size button = tester.getSize(
      find.descendant(
        of: find.byKey(const Key('editorActionRow')),
        matching: find.byType(FilledButton),
      ).first,
    );
    expect(wrapped.height, greaterThan(button.height));
    expect(tester.takeException(), isNull);
  });

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
