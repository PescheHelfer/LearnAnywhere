import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/editor/unit_editor_page.dart';
import 'package:learn_anywhere_desktop/src/learn/desktop_query_options.dart';
import 'package:learn_anywhere_desktop/src/learn/learn_session_page.dart';
import 'package:learn_anywhere_desktop/src/mask_editor/mask_editor_page.dart';
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
                // Offered, so the Difficult pill is laid out too.
                onToggleDifficult: (int _) {},
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
                onToggleDifficult: (int _) {},
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
        'learnDifficultPill',
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
              onToggleDifficult: (int _) {},
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

  group('the mask editor derives its own frame', () {
    // The Mask Editor is not sized from a deck: its width comes from the Fields
    // table's own columns, so a mask with one field is all these need.
    Widget buildMaskEditor(
      Locale locale, {
      int zoomPercent = LearnAnywhereZoom.normal,
      double? frameWidth,
      void Function(BuildContext)? report,
    }) => MaterialApp(
      locale: locale,
      theme: LearnAnywhereTheme.light(zoomPercent: zoomPercent),
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            report?.call(context);
            final Widget page = MaskEditorPage(
              mask: mask,
              onChanged: (LearningMask _) {},
            );
            return frameWidth == null
                ? page
                : ContentFrame(maxWidth: frameWidth, child: page);
          },
        ),
      ),
    );

    /// Lays the editor out unframed on a surface far wider than it, and returns
    /// the width its own function derives for it.
    Future<double> derivedWidth(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
      int zoomPercent = LearnAnywhereZoom.normal,
    }) async {
      late BuildContext context;
      await tester.pumpWidget(
        buildMaskEditor(
          locale,
          zoomPercent: zoomPercent,
          report: (BuildContext c) => context = c,
        ),
      );
      await tester.pumpAndSettle();
      return maskEditorContentFrameWidth(
        context,
        LearnAnywhereLocalizations.of(context),
      );
    }

    /// The Fields table's own horizontal scroll view — the thing that has to
    /// have nothing left to scroll once the frame is wide enough.
    ScrollPosition tablePosition(WidgetTester tester) => tester
        .state<ScrollableState>(
          find
              .ancestor(
                of: find.byType(DataTable),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;

    void useWideSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(3400, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('German asks for more room than English', (
      WidgetTester tester,
    ) async {
      useWideSurface(tester);
      final double english = await derivedWidth(tester);
      final double german = await derivedWidth(
        tester,
        locale: const Locale('de'),
      );
      // Nothing tells the function which language is wider; it comes out of
      // measuring *Vorlesesprache* against *Spoken language* and the rest.
      expect(german, greaterThan(english));
    });

    testWidgets('the width grows with the zoom level', (
      WidgetTester tester,
    ) async {
      useWideSurface(tester);
      final double normal = await derivedWidth(tester);
      final double zoomed = await derivedWidth(
        tester,
        zoomPercent: LearnAnywhereZoom.maximum,
      );
      expect(zoomed, greaterThan(normal));
    });

    testWidgets('the width never falls below the categories column plus the '
        'table', (WidgetTester tester) async {
      useWideSurface(tester);
      for (final int zoomPercent in <int>[
        LearnAnywhereZoom.minimum,
        LearnAnywhereZoom.normal,
        LearnAnywhereZoom.maximum,
      ]) {
        final double derived = await derivedWidth(
          tester,
          locale: const Locale('de'),
          zoomPercent: zoomPercent,
        );
        // Both measured off the real widgets: the table is inside a horizontal
        // scroll view, so it lays out at exactly the width it asks for however
        // wide the surface is.
        final double categories = tester
            .getSize(find.byKey(const Key('mask-editor-categories-column')))
            .width;
        final double table = tester.getSize(find.byType(DataTable)).width;
        expect(
          derived,
          greaterThanOrEqualTo(categories + table),
          reason: 'at $zoomPercent per cent the two columns need '
              '${categories + table}',
        );
      }
    });

    for (final (String language, Locale locale) in const <(String, Locale)>[
      ('English', Locale('en')),
      ('German', Locale('de')),
    ]) {
      testWidgets('the $language fields table fits inside the derived frame', (
        WidgetTester tester,
      ) async {
        useWideSurface(tester);
        final double frame = await derivedWidth(tester, locale: locale);

        // The real frame, at the real derived width, around the real page —
        // the whole point being that the table has nothing left to scroll.
        await tester.pumpWidget(buildMaskEditor(locale, frameWidth: frame));
        await tester.pumpAndSettle();

        final ScrollPosition table = tablePosition(tester);
        expect(table.axis, Axis.horizontal);
        expect(
          table.maxScrollExtent,
          0,
          reason: 'the $language table still scrolls inside a $frame frame',
        );
        // And the frame really did impose that width rather than step aside.
        expect(tester.getSize(find.byType(MaskEditorPage)).width, frame);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a window narrower than the frame lets the table scroll', (
      WidgetTester tester,
    ) async {
      useWideSurface(tester);
      final double frame = await derivedWidth(tester);

      tester.view.physicalSize = const Size(700, 900);
      await tester.pumpWidget(
        buildMaskEditor(const Locale('en'), frameWidth: frame),
      );
      await tester.pumpAndSettle();

      // The frame is clamped to what it is given and steps aside entirely
      // below its own width, exactly as it did before this screen derived one.
      expect(tester.getSize(find.byType(MaskEditorPage)).width, 700);
      final ScrollPosition table = tablePosition(tester);
      expect(table.axis, Axis.horizontal);
      expect(table.maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}
