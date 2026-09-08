import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/src/mask_editor/mask_sync_dialog.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  const LearnAnywhereLocalizations en = LearnAnywhereLocalizations(
    Locale('en'),
  );

  test('wrote nothing, no failure: reports it and does not navigate', () {
    final MaskSyncReport report = describeMaskSyncOutcome(
      const MaskSyncOutcome(written: <String>[]),
      en,
    );

    expect(report.text, 'No copies were updated');
    expect(report.navigate, isFalse);
  });

  test('wrote something, no failure: reports the count and navigates', () {
    final MaskSyncReport report = describeMaskSyncOutcome(
      const MaskSyncOutcome(written: <String>['/decks/a.vok', '/decks/b.inf']),
      en,
    );

    expect(report.text, 'Synced 2 copy(ies)');
    expect(report.navigate, isTrue);
  });

  test(
    'wrote something, then the re-scan failed: reports both the count and '
    'the failure, and still navigates — the same as an equally sized sync '
    'that did not fail',
    () {
      final MaskSyncReport report = describeMaskSyncOutcome(
        MaskSyncOutcome(
          written: const <String>['/decks/a.vok'],
          failure: (Exception('folder unmounted'), StackTrace.empty),
        ),
        en,
      );

      expect(
        report.text,
        'Synced 1 copy(ies); the folder could not be re-scanned '
        'afterwards: Exception: folder unmounted',
      );
      expect(report.navigate, isTrue);
    },
  );

  test(
    'wrote nothing, then the re-scan failed: reports the failure without '
    'navigating, so unsaved Mask Editor edits are not stranded — the same '
    'guarantee the empty-write case gets',
    () {
      final MaskSyncReport report = describeMaskSyncOutcome(
        MaskSyncOutcome(
          written: const <String>[],
          failure: (Exception('folder unmounted'), StackTrace.empty),
        ),
        en,
      );

      expect(
        report.text,
        'File operation failed: Exception: folder unmounted',
      );
      expect(report.navigate, isFalse);
    },
  );
}
