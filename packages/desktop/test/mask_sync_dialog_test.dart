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

      // Checking a row's checkbox enables Apply.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      final FilledButton enabledApply = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Update selected'),
      );
      expect(enabledApply.onPressed, isNotNull);
    },
  );
}
