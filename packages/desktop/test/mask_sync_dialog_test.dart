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
        const MaskSyncEntry(
          path: '/decks/english.vok',
          isMask: false,
          revision: 1,
          status: MaskSyncStatus.willUpdate,
          reasons: <MaskBreakingReason>[],
          maskName: 'English Deck',
        ),
        const MaskSyncEntry(
          path: '/decks/french.vok',
          isMask: false,
          revision: 1,
          status: MaskSyncStatus.willUpdate,
          reasons: <MaskBreakingReason>[],
          maskName: 'French Deck',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => MaskSyncDialog.show(
                    context,
                    entries,
                    referenceName: 'English Deck',
                    referenceRevision: 1,
                  ),
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

      // The reference mask's own name is shown so the user knows what is
      // about to be applied.
      expect(find.textContaining('English Deck'), findsWidgets);
      // No copy is preselected: a single misclick on Apply must not
      // mass-overwrite every willUpdate copy found under the folder.
      final FilledButton applyButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update selected'),
      );
      expect(applyButton.onPressed, isNull);

      // Checking a row's checkbox enables Apply. The checkbox itself is
      // excluded from hit-testing on a selectable row (the row's own InkWell
      // owns the tap instead, so a click anywhere on the row toggles it), so
      // this tap is expected to land on that InkWell rather than the
      // Checkbox render object directly.
      await tester.tap(find.byType(Checkbox).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      final FilledButton enabledApply = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update selected'),
      );
      expect(enabledApply.onPressed, isNotNull);
    },
  );

  testWidgets(
    'tapping anywhere on a selectable row toggles it, and a non-selectable '
    "row's tap does nothing",
    (WidgetTester tester) async {
      final List<MaskSyncEntry> entries = <MaskSyncEntry>[
        const MaskSyncEntry(
          path: '/decks/up-to-date.vok',
          isMask: false,
          revision: 1,
          status: MaskSyncStatus.upToDate,
          reasons: <MaskBreakingReason>[],
          maskName: 'Up To Date Deck',
        ),
        const MaskSyncEntry(
          path: '/decks/english.vok',
          isMask: false,
          revision: 1,
          status: MaskSyncStatus.willUpdate,
          reasons: <MaskBreakingReason>[],
          maskName: 'English Deck',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => MaskSyncDialog.show(
                    context,
                    entries,
                    referenceName: 'English Deck',
                    referenceRevision: 1,
                  ),
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

      FilledButton applyButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update selected'),
      );
      expect(applyButton().onPressed, isNull);

      // The up-to-date row cannot be ticked, so tapping its name does
      // nothing at all.
      await tester.tap(find.textContaining('up-to-date.vok'));
      await tester.pumpAndSettle();
      expect(applyButton().onPressed, isNull);

      // The willUpdate row is tappable across its full width, not just on
      // its checkbox.
      await tester.tap(find.textContaining('english.vok'));
      await tester.pumpAndSettle();
      expect(applyButton().onPressed, isNotNull);
    },
  );

  testWidgets(
    'a non-selectable row is dimmed into the muted foreground, but a '
    "would-break row's status label and reasons stay at full strength",
    (WidgetTester tester) async {
      final List<MaskSyncEntry> entries = <MaskSyncEntry>[
        const MaskSyncEntry(
          path: '/decks/up-to-date.vok',
          isMask: false,
          revision: 1,
          status: MaskSyncStatus.upToDate,
          reasons: <MaskBreakingReason>[],
          maskName: 'Up To Date Deck',
        ),
        const MaskSyncEntry(
          path: '/decks/english.vok',
          isMask: false,
          revision: 1,
          status: MaskSyncStatus.willUpdate,
          reasons: <MaskBreakingReason>[],
          maskName: 'English Deck',
        ),
        const MaskSyncEntry(
          path: '/decks/french.vok',
          isMask: false,
          revision: 1,
          status: MaskSyncStatus.wouldBreak,
          reasons: <MaskBreakingReason>[
            MaskBreakingReason(
              kind: MaskBreakingKind.fieldDeleted,
              categoryId: 0,
              categoryName: 'Cat',
              fieldId: 0,
              fieldName: 'Field',
              affectedUnits: 3,
            ),
          ],
          maskName: 'French Deck',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          // Dark Blue is the one theme that opts into its own muted
          // foreground, so this is the theme that can tell "used the muted
          // foreground" apart from "used onSurfaceVariant anyway".
          theme: LearnAnywhereTheme.darkBlue(),
          localizationsDelegates:
              LearnAnywhereLocalizations.localizationsDelegates,
          supportedLocales: LearnAnywhereLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => MaskSyncDialog.show(
                    context,
                    entries,
                    referenceName: 'English Deck',
                    referenceRevision: 1,
                  ),
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

      const Color mutedForeground = Color(0xFF9DB2E8);
      Color? colorOf(String textContaining) =>
          tester.widget<Text>(find.textContaining(textContaining)).style?.color;

      // Non-selectable rows (up to date, would break) dim their name line
      // into the muted foreground; the selectable row does not.
      expect(colorOf('up-to-date.vok'), mutedForeground);
      expect(colorOf('french.vok'), mutedForeground);
      expect(colorOf('english.vok'), isNot(mutedForeground));

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
}
