import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper around [SharedPreferences] for mobile-specific settings.
///
/// Covers UI theme and UI language only. Guardrail settings (minimum-attempts
/// guard, wrong-answer ceiling) live in the JSON settings file managed by the
/// core package, mirroring desktop's split between `DesktopPrefs` and
/// `LearnAnywhereSettings`.
final class MobilePrefs {
  /// Creates a prefs wrapper backed by [prefs].
  MobilePrefs(SharedPreferences prefs) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _keyTheme = 'theme';
  static const String _keyLocale = 'locale';

  /// Stored theme name, or null on first run.
  String? get theme => _prefs.getString(_keyTheme);

  /// Persists [value] as the active theme name.
  void setTheme(String value) => unawaited(_prefs.setString(_keyTheme, value));

  /// Stored locale language code, or null on first run.
  String? get locale => _prefs.getString(_keyLocale);

  /// Persists [value] as the active locale language code.
  void setLocale(String value) =>
      unawaited(_prefs.setString(_keyLocale, value));
}
