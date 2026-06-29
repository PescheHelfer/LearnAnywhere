import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper around [SharedPreferences] for desktop-specific settings.
///
/// Covers UI theme, UI language, last-used file-dialog directories, and
/// window position/size. Pure learning-engine settings are stored separately
/// in the JSON settings file managed by the core package.
final class DesktopPrefs {
  /// Creates a prefs wrapper backed by [prefs].
  DesktopPrefs(SharedPreferences prefs) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _keyTheme = 'theme';
  static const String _keyLocale = 'locale';
  static const String _keyLastDirVok = 'last_dir_vok';
  static const String _keyLastDirSta = 'last_dir_sta';
  static const String _keyLastDirInf = 'last_dir_inf';
  static const String _keyWindowX = 'window_x';
  static const String _keyWindowY = 'window_y';
  static const String _keyWindowWidth = 'window_width';
  static const String _keyWindowHeight = 'window_height';

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

  // --- Window position & size -----------------------------------------------

  /// Last saved window X position in logical pixels, or null on first run.
  double? get windowX => _prefs.getDouble(_keyWindowX);

  /// Last saved window Y position in logical pixels, or null on first run.
  double? get windowY => _prefs.getDouble(_keyWindowY);

  /// Last saved window width in logical pixels, or null on first run.
  double? get windowWidth => _prefs.getDouble(_keyWindowWidth);

  /// Last saved window height in logical pixels, or null on first run.
  double? get windowHeight => _prefs.getDouble(_keyWindowHeight);

  /// Persists window position ([x], [y]) and size ([width], [height]) in
  /// logical pixels.
  void setWindowBounds(double x, double y, double width, double height) {
    unawaited(_prefs.setDouble(_keyWindowX, x));
    unawaited(_prefs.setDouble(_keyWindowY, y));
    unawaited(_prefs.setDouble(_keyWindowWidth, width));
    unawaited(_prefs.setDouble(_keyWindowHeight, height));
  }
}
