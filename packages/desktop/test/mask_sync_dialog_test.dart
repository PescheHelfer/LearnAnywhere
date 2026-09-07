import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_desktop/src/file_operations/desktop_file_service.dart';
import 'package:learn_anywhere_desktop/src/mask_editor/mask_sync_dialog.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  testWidgets(
    'nothing is preselected and Apply is disabled until a copy is checked',
    (WidgetTester tester) async {
      final List<MaskSyncEntry> entries = <MaskSyncEntry>[
        _entry('/decks/english.vok', MaskSyncStatus.willUpdate),
        _entry('/decks/french.vok', MaskSyncStatus.willUpdate),
      ];

      await _openDialog(tester, entries: entries);

      // The reference mask's own name is shown so the user knows what is
      // about to be applied.
      expect(find.textContaining('English Deck'), findsWidgets);
      // No copy is preselected: a single misclick on Apply must not
      // mass-overwrite every willUpdate copy found under the folder.
      expect(_applyButton(tester).onPressed, isNull);

      // Checking a row's checkbox enables Apply. The checkbox itself is
      // excluded from hit-testing on a selectable row (the row's own InkWell
      // owns the tap instead, so a click anywhere on the row toggles it), so
      // this tap is expected to land on that InkWell rather than the
      // Checkbox render object directly.
      await tester.tap(find.byType(Checkbox).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_applyButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'tapping anywhere on a selectable row toggles it, and a non-selectable '
    "row's tap does nothing",
    (WidgetTester tester) async {
      final List<MaskSyncEntry> entries = <MaskSyncEntry>[
        _entry('/decks/up-to-date.vok', MaskSyncStatus.upToDate),
        _entry('/decks/english.vok', MaskSyncStatus.willUpdate),
      ];

      await _openDialog(tester, entries: entries);
      expect(_applyButton(tester).onPressed, isNull);

      // The up-to-date row cannot be ticked, so tapping its name does
      // nothing at all.
      await tester.tap(find.textContaining('up-to-date.vok'));
      await tester.pumpAndSettle();
      expect(_applyButton(tester).onPressed, isNull);

      // The willUpdate row is tappable across its full width, not just on
      // its checkbox.
      await tester.tap(find.textContaining('english.vok'));
      await tester.pumpAndSettle();
      expect(_applyButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'a non-selectable row is dimmed into the muted foreground, but a '
    "would-break row's status label and reasons stay at full strength",
    (WidgetTester tester) async {
      final List<MaskSyncEntry> entries = <MaskSyncEntry>[
        _entry('/decks/one/up-to-date.vok', MaskSyncStatus.upToDate),
        _entry('/decks/two/english.vok', MaskSyncStatus.willUpdate),
        _entry(
          '/decks/three/french.vok',
          MaskSyncStatus.wouldBreak,
          reasons: _breakingReasons,
        ),
      ];

      await _openDialog(
        tester,
        entries: entries,
        // Dark Blue is the one theme that opts into its own muted
        // foreground, so this is the theme that can tell "used the muted
        // foreground" apart from "used onSurfaceVariant anyway".
        theme: LearnAnywhereTheme.darkBlue(),
      );

      const Color mutedForeground = Color(0xFF9DB2E8);
      Color? colorOf(String textContaining) =>
          tester.widget<Text>(find.textContaining(textContaining)).style?.color;

      // Non-selectable rows (up to date, would break) dim their name line
      // into the muted foreground; the selectable row does not.
      expect(colorOf('up-to-date.vok'), mutedForeground);
      expect(colorOf('french.vok'), mutedForeground);
      expect(colorOf('english.vok'), isNot(mutedForeground));

      // The folder line is secondary info on every row, selectable or not,
      // so it always uses the muted foreground — never the bare
      // onSurfaceVariant that fails 4.5:1 against this dialog's surface in
      // Dark Blue.
      expect(colorOf('/decks/one'), mutedForeground);
      expect(colorOf('/decks/two'), mutedForeground);
      expect(colorOf('/decks/three'), mutedForeground);

      // The would-break row's own alarm-colored status label and its
      // breaking-reason line are untouched by that dimming.
      final ThemeData theme = LearnAnywhereTheme.darkBlue();
      expect(
        tester.widget<Text>(find.text('Would break')).style?.color,
        theme.colorScheme.error,
      );
      expect(colorOf('Deleting field'), isNot(mutedForeground));

      // Dimming is a color swap, never an Opacity wrapper.
      expect(find.byType(Opacity), findsNothing);
    },
  );

  testWidgets(
    'applying keeps the dialog open and every row reports its own fresh '
    'state: the written copy flips to up to date, the failed one stays '
    'outstanding',
    (WidgetTester tester) async {
      final _FakeSync sync = _FakeSync(
        // The second row's write fails, so the re-scan still finds it out of
        // date — exactly what a learner has to be able to see.
        failing: <String>{'/decks/two/french.vok'},
        rescans: <List<MaskSyncEntry>>[
          <MaskSyncEntry>[
            _entry('/decks/one/english.vok', MaskSyncStatus.upToDate),
            _entry('/decks/two/french.vok', MaskSyncStatus.willUpdate),
            _entry(
              '/decks/three/broken.vok',
              MaskSyncStatus.wouldBreak,
              reasons: _breakingReasons,
            ),
          ],
        ],
      );

      await _openDialog(
        tester,
        entries: <MaskSyncEntry>[
          _entry('/decks/one/english.vok', MaskSyncStatus.willUpdate),
          _entry('/decks/two/french.vok', MaskSyncStatus.willUpdate),
          _entry(
            '/decks/three/broken.vok',
            MaskSyncStatus.wouldBreak,
            reasons: _breakingReasons,
          ),
        ],
        sync: sync,
      );

      await tester.tap(find.textContaining('english.vok'));
      await tester.tap(find.textContaining('french.vok'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update selected'));
      await tester.pumpAndSettle();

      // Exactly the ticked paths were applied — never the would-break row.
      expect(sync.applied, <List<String>>[
        <String>['/decks/one/english.vok', '/decks/two/french.vok'],
      ]);

      // The dialog is still on screen, showing the fresh reading.
      expect(find.text('Update other copies of this mask'), findsOneWidget);
      expect(find.text('Up to date'), findsOneWidget);
      expect(find.text('Will update'), findsOneWidget);
      expect(find.textContaining('/decks/one'), findsOneWidget);
      expect(find.textContaining('/decks/two'), findsOneWidget);

      // Selection is cleared and re-derived from the fresh entries alone, so
      // Apply is disabled again and the now-up-to-date row cannot be ticked
      // and applied a second time.
      expect(_applyButton(tester).onPressed, isNull);
      await tester.tap(find.textContaining('english.vok'));
      await tester.pumpAndSettle();
      expect(_applyButton(tester).onPressed, isNull);

      // A would-break row still explains itself after a re-scan.
      expect(find.textContaining('Deleting field'), findsOneWidget);
    },
  );

  testWidgets(
    'Apply can be pressed again for a further round, and closing returns the '
    'paths written across all of them',
    (WidgetTester tester) async {
      final _FakeSync sync = _FakeSync(
        failing: <String>{'/decks/two/french.vok'},
        rescans: <List<MaskSyncEntry>>[
          <MaskSyncEntry>[
            _entry('/decks/one/english.vok', MaskSyncStatus.upToDate),
            _entry('/decks/two/french.vok', MaskSyncStatus.willUpdate),
          ],
          <MaskSyncEntry>[
            _entry('/decks/one/english.vok', MaskSyncStatus.upToDate),
            _entry('/decks/two/french.vok', MaskSyncStatus.upToDate),
          ],
        ],
      );
      final _Result result = _Result();

      await _openDialog(
        tester,
        entries: <MaskSyncEntry>[
          _entry('/decks/one/english.vok', MaskSyncStatus.willUpdate),
          _entry('/decks/two/french.vok', MaskSyncStatus.willUpdate),
        ],
        sync: sync,
        result: result,
      );

      await tester.tap(find.textContaining('english.vok'));
      await tester.tap(find.textContaining('french.vok'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update selected'));
      await tester.pumpAndSettle();

      // The second round retries only the row still outstanding — this time
      // its write lands.
      sync.failing.clear();
      await tester.tap(find.textContaining('french.vok'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update selected'));
      await tester.pumpAndSettle();

      expect(sync.applied, <List<String>>[
        <String>['/decks/one/english.vok', '/decks/two/french.vok'],
        <String>['/decks/two/french.vok'],
      ]);
      expect(find.text('Up to date'), findsNWidgets(2));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Both rounds' landed writes come back, and the path whose first write
      // failed is not double-counted by its successful retry.
      expect(result.written, <String>[
        '/decks/one/english.vok',
        '/decks/two/french.vok',
      ]);
    },
  );

  testWidgets('closing without applying returns an empty list, not null', (
    WidgetTester tester,
  ) async {
    final _FakeSync sync = _FakeSync();
    final _Result result = _Result();

    await _openDialog(
      tester,
      entries: <MaskSyncEntry>[
        _entry('/decks/english.vok', MaskSyncStatus.willUpdate),
      ],
      sync: sync,
      result: result,
    );

    // Ticking a row and then closing must not count as having written it.
    await tester.tap(find.textContaining('english.vok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result.written, isNotNull);
    expect(result.written, isEmpty);
    expect(sync.applied, isEmpty);
  });

  testWidgets(
    'a re-scan that fails ends the visit and reaches the caller, instead of '
    'leaving rows that no longer describe the folder',
    (WidgetTester tester) async {
      // No re-scan queued: reading the folder again throws, as it would if
      // the folder were removed between rounds.
      final _FakeSync sync = _FakeSync();
      final _Result result = _Result();

      await _openDialog(
        tester,
        entries: <MaskSyncEntry>[
          _entry('/decks/english.vok', MaskSyncStatus.willUpdate),
        ],
        sync: sync,
        result: result,
      );

      await tester.tap(find.textContaining('english.vok'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Update selected'));
      await tester.pumpAndSettle();

      // The dialog is gone and the shell — which reports file errors — got
      // the failure, rather than it vanishing into an unawaited callback.
      expect(find.text('Update other copies of this mask'), findsNothing);
      expect(result.failure, isNotNull);
      // The write that landed before the re-scan failed is still handed
      // back, not thrown away with the error: the caller has to bring its
      // own in-memory copy in line with what is actually on disk before it
      // reports the failure, and it can only do that if the ledger survives.
      expect(result.written, <String>['/decks/english.vok']);
    },
  );

  testWidgets('while an apply is in flight both action buttons are blocked', (
    WidgetTester tester,
  ) async {
    final Completer<void> inFlight = Completer<void>();
    final _FakeSync sync = _FakeSync(
      gate: inFlight.future,
      rescans: <List<MaskSyncEntry>>[
        <MaskSyncEntry>[
          _entry('/decks/english.vok', MaskSyncStatus.upToDate),
        ],
      ],
    );

    await _openDialog(
      tester,
      entries: <MaskSyncEntry>[
        _entry('/decks/english.vok', MaskSyncStatus.willUpdate),
      ],
      sync: sync,
    );

    await tester.tap(find.textContaining('english.vok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update selected'));
    // Not pumpAndSettle: the write is deliberately still outstanding.
    await tester.pump();

    // A second Apply cannot race the re-scan the first one is waiting for,
    // and the visit cannot be ended between the write and that re-scan.
    expect(_applyButton(tester).onPressed, isNull);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .onPressed,
      isNull,
    );

    inFlight.complete();
    await tester.pumpAndSettle();
    expect(sync.applied, hasLength(1));
    expect(find.text('Up to date'), findsOneWidget);
  });
}

/// The reasons rendered under a would-break row.
const List<MaskBreakingReason> _breakingReasons = <MaskBreakingReason>[
  MaskBreakingReason(
    kind: MaskBreakingKind.fieldDeleted,
    categoryId: 0,
    categoryName: 'Cat',
    fieldId: 0,
    fieldName: 'Field',
    affectedUnits: 3,
  ),
];

MaskSyncEntry _entry(
  String path,
  MaskSyncStatus status, {
  List<MaskBreakingReason> reasons = const <MaskBreakingReason>[],
}) {
  return MaskSyncEntry(
    path: path,
    isMask: false,
    revision: 1,
    status: status,
    reasons: reasons,
    maskName: 'English Deck',
  );
}

/// Stands in for the shell's file service without touching a filesystem:
/// records what it was asked to write, decides per path whether that write
/// lands, and serves the entries each re-scan finds afterwards.
class _FakeSync {
  _FakeSync({
    this.rescans = const <List<MaskSyncEntry>>[],
    Set<String>? failing,
    this.gate,
  }) : failing = failing ?? <String>{},
       _remaining = List<List<MaskSyncEntry>>.of(rescans);

  /// What each successive re-scan finds, in order.
  final List<List<MaskSyncEntry>> rescans;

  /// Paths whose write fails; every other path in the same batch still lands.
  final Set<String> failing;

  /// Held open by a test that needs an apply to still be in flight.
  final Future<void>? gate;

  /// The path lists handed to apply, one entry per round.
  final List<List<String>> applied = <List<String>>[];

  final List<List<MaskSyncEntry>> _remaining;

  Future<List<MaskWriteResult>> apply(List<String> paths) async {
    applied.add(paths);
    if (gate != null) {
      await gate;
    }
    return <MaskWriteResult>[
      for (final String path in paths)
        MaskWriteResult(path: path, succeeded: !failing.contains(path)),
    ];
  }

  Future<List<MaskSyncEntry>> rescan() async => _remaining.removeAt(0);
}

/// Captures the [MaskSyncOutcome] the dialog returned to its caller.
class _Result {
  List<String>? written;
  Object? failure;
}

FilledButton _applyButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Update selected'),
);

/// Pumps a shell whose only button opens the dialog, then opens it.
Future<void> _openDialog(
  WidgetTester tester, {
  required List<MaskSyncEntry> entries,
  _FakeSync? sync,
  _Result? result,
  ThemeData? theme,
}) async {
  final _FakeSync fake = sync ?? _FakeSync();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return ElevatedButton(
              onPressed: () async {
                // The outcome carries the ledger and the failure together —
                // never one without the other — so there is nothing to
                // catch here, unlike the old throwing contract.
                final MaskSyncOutcome outcome = await MaskSyncDialog.show(
                  context,
                  entries,
                  referenceName: 'English Deck',
                  referenceRevision: 1,
                  onApply: fake.apply,
                  onRescan: fake.rescan,
                );
                result?.written = outcome.written;
                result?.failure = outcome.failure?.$1;
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
