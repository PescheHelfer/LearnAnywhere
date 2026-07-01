import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper around [SharedPreferences] for desktop-specific settings.
///
/// Covers UI theme, UI language, and last-used file-dialog directories.
/// Window geometry is handled separately by `WindowGeometryService`.
/// Pure learning-engine settings are stored in the JSON settings file
/// managed by the core package.
final class DesktopPrefs {
  /// Creates a prefs wrapper backed by [prefs].
  DesktopPrefs(SharedPreferences prefs) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _keyTheme = 'theme';
  static const String _keyLocale = 'locale';
  static const String _keyLastDirVok = 'last_dir_vok';
  static const String _keyLastDirSta = 'last_dir_sta';
  static const String _keyLastDirInf = 'last_dir_inf';
  static const String _keyLastPathOpenDeck = 'last_path_open_deck';
  static const String _keyAutoLoadStats = 'auto_load_stats';
  static const String _keyAutoSaveStats = 'auto_save_stats';

  // --- Theme & locale -------------------------------------------------------

  /// Stored theme name, or null on first run.
  String? get theme => _prefs.getString(_keyTheme);

  /// Persists [value] as the active theme name.
  void setTheme(String value) =>
      unawaited(_prefs.setString(_keyTheme, value));

  /// Stored locale language code, or null on first run.
  String? get locale => _prefs.getString(_keyLocale);

  /// Persists [value] as the active locale language code.
  void setLocale(String value) =>
      unawaited(_prefs.setString(_keyLocale, value));

  // --- Last-used dialog directories -----------------------------------------

  /// Directory last used for a `.vok` deck file dialog, or null on first run.
  String? get lastDirVok => _prefs.getString(_keyLastDirVok);

  /// Persists [value] as the last-used `.vok` dialog directory.
  void setLastDirVok(String value) =>
      unawaited(_prefs.setString(_keyLastDirVok, value));

  /// Directory last used for a `.sta` statistics file dialog, or null on first run.
  String? get lastDirSta => _prefs.getString(_keyLastDirSta);

  /// Persists [value] as the last-used `.sta` dialog directory.
  void setLastDirSta(String value) =>
      unawaited(_prefs.setString(_keyLastDirSta, value));

  /// Directory last used for a `.inf` mask file dialog, or null on first run.
  String? get lastDirInf => _prefs.getString(_keyLastDirInf);

  /// Persists [value] as the last-used `.inf` dialog directory.
  void setLastDirInf(String value) =>
      unawaited(_prefs.setString(_keyLastDirInf, value));

  // --- Last opened deck (N1) -------------------------------------------------

  /// Absolute path of the deck last opened via File > Open, or null.
  String? get lastPathOpenDeck => _prefs.getString(_keyLastPathOpenDeck);

  /// Persists [value] as the path of the deck last opened.
  void setLastPathOpenDeck(String value) =>
      unawaited(_prefs.setString(_keyLastPathOpenDeck, value));

  // --- Auto-load / auto-save statistics toggles (C11) ------------------------

  /// Whether opening a `.vok` auto-loads a sidecar `.sta`. Defaults to off.
  bool get autoLoadStats => _prefs.getBool(_keyAutoLoadStats) ?? false;

  /// Persists the auto-load statistics toggle state.
  void setAutoLoadStats(bool value) =>
      unawaited(_prefs.setBool(_keyAutoLoadStats, value));

  /// Whether leaving a deck auto-saves statistics. Defaults to off.
  bool get autoSaveStats => _prefs.getBool(_keyAutoSaveStats) ?? false;

  /// Persists the auto-save statistics toggle state.
  void setAutoSaveStats(bool value) =>
      unawaited(_prefs.setBool(_keyAutoSaveStats, value));
}
