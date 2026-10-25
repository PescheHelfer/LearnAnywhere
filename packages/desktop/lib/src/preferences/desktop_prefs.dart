import 'dart:async';

import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper around [SharedPreferences] for desktop-specific settings.
///
/// Covers UI theme, UI language, the zoom level, the content frame, the start
/// folder, and last-used file-dialog directories.
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
  static const String _keyLastDirFileSearch = 'last_dir_file_search';
  static const String _keyStartFolder = 'start_folder';
  static const String _keyZoomPercent = 'zoom_percent';
  static const String _keyContentFrame = 'content_frame';
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

  // --- Zoom level -----------------------------------------------------------

  /// The stored zoom level in per cent, always one of the offered levels.
  ///
  /// Anything else — nothing stored, or a value hand-edited into the store —
  /// reads back as the nearest offered level, so the rest of the program never
  /// has to cope with a size that was never laid out.
  int get zoomPercent {
    final int? stored = _prefs.getInt(_keyZoomPercent);
    return stored == null
        ? LearnAnywhereZoom.normal
        : LearnAnywhereZoom.nearest(stored);
  }

  /// Persists [value] as the zoom level, snapped to an offered level.
  void setZoomPercent(int value) => unawaited(
    _prefs.setInt(_keyZoomPercent, LearnAnywhereZoom.nearest(value)),
  );

  // --- Content frame --------------------------------------------------------

  /// Whether each screen's content is centred in a width-limited frame.
  ///
  /// Off unless the learner has turned it on: the full-width layout is the
  /// default.
  bool get contentFrameEnabled => _prefs.getBool(_keyContentFrame) ?? false;

  /// Persists whether the content frame is in force.
  void setContentFrameEnabled(bool value) =>
      unawaited(_prefs.setBool(_keyContentFrame, value));

  // --- Start folder ---------------------------------------------------------

  /// The folder every file dialog opens at, or null when none is set.
  ///
  /// An empty stored value reads back as null, so a cleared setting behaves
  /// exactly like one that was never set.
  String? get startFolder {
    final String? value = _prefs.getString(_keyStartFolder);
    return value == null || value.isEmpty ? null : value;
  }

  /// Persists [value] as the start folder; a null or empty [value] clears it.
  void setStartFolder(String? value) {
    if (value == null || value.isEmpty) {
      unawaited(_prefs.remove(_keyStartFolder));
    } else {
      unawaited(_prefs.setString(_keyStartFolder, value));
    }
  }

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

  /// Folder last chosen for a Lexicon file search, or null on first run.
  String? get lastDirFileSearch => _prefs.getString(_keyLastDirFileSearch);

  /// Persists [value] as the last-used Lexicon file-search folder.
  void setLastDirFileSearch(String value) =>
      unawaited(_prefs.setString(_keyLastDirFileSearch, value));

  // --- Auto-load / auto-save statistics toggles (C11) ------------------------

  /// Whether opening a `.vok` offers its newest session `.sta`. Defaults to on.
  bool get autoLoadStats => _prefs.getBool(_keyAutoLoadStats) ?? true;

  /// Persists the auto-load statistics toggle state.
  void setAutoLoadStats(bool value) =>
      unawaited(_prefs.setBool(_keyAutoLoadStats, value));

  /// Whether statistics are auto-saved to a session file. Defaults to on.
  bool get autoSaveStats => _prefs.getBool(_keyAutoSaveStats) ?? true;

  /// Persists the auto-save statistics toggle state.
  void setAutoSaveStats(bool value) =>
      unawaited(_prefs.setBool(_keyAutoSaveStats, value));
}
