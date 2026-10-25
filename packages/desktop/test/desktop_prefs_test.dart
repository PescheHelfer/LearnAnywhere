import 'package:flutter_test/flutter_test.dart';
import 'package:learn_anywhere_desktop/src/preferences/desktop_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a fresh install auto-loads and auto-saves statistics', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final DesktopPrefs prefs = DesktopPrefs(
      await SharedPreferences.getInstance(),
    );
    expect(prefs.autoLoadStats, isTrue);
    expect(prefs.autoSaveStats, isTrue);
  });

  test('a toggle switched off stays off', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final DesktopPrefs prefs = DesktopPrefs(
      await SharedPreferences.getInstance(),
    );
    prefs.setAutoLoadStats(false);
    prefs.setAutoSaveStats(false);
    final DesktopPrefs reopened = DesktopPrefs(
      await SharedPreferences.getInstance(),
    );
    expect(reopened.autoLoadStats, isFalse);
    expect(reopened.autoSaveStats, isFalse);
  });
}
