import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'services/window_geometry_service.dart';
import 'src/about/about_page.dart';
import 'src/editor/unit_editor_page.dart';
import 'src/file_operations/desktop_document.dart';
import 'src/file_operations/desktop_file_picker.dart';
import 'src/file_operations/desktop_file_service.dart';
import 'src/learn/desktop_query_options.dart';
import 'src/learn/learn_session_page.dart';
import 'src/learn/query_options_page.dart';
import 'src/lexicon/lexicon_page.dart';
import 'src/mask_editor/mask_editor_page.dart';
import 'src/mask_editor/mask_sync_dialog.dart';
import 'src/preferences/desktop_prefs.dart';
import 'src/statistics/statistics_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  // Intercept the window close (title-bar X) so statistics/settings can be
  // auto-saved before the process exits; see `_DesktopHomeState.onWindowClose`.
  await windowManager.setPreventClose(true);
  final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
  final DesktopPrefs prefs = DesktopPrefs(sharedPrefs);

  final WindowGeometryService geometryService = WindowGeometryService();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1024, 700),
    center: true,
    skipTaskbar: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await geometryService.restoreGeometry();
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(LearnAnywhereDesktopApp(prefs: prefs));
}

/// Desktop shell for Learn Anywhere.
final class LearnAnywhereDesktopApp extends StatefulWidget {
  /// Creates the desktop shell.
  const LearnAnywhereDesktopApp({super.key, required this.prefs});

  /// Desktop-specific preferences (theme, locale, dialog dirs, window bounds).
  final DesktopPrefs prefs;

  @override
  State<LearnAnywhereDesktopApp> createState() =>
      _LearnAnywhereDesktopAppState();
}

final class _LearnAnywhereDesktopAppState
    extends State<LearnAnywhereDesktopApp> with WindowListener {
  late _AppTheme _appTheme;
  late Locale _locale;
  final WindowGeometryService _geometryService = WindowGeometryService();

  ThemeData get _lightTheme => _appTheme == _AppTheme.lightBlue
      ? LearnAnywhereTheme.lightBlue()
      : LearnAnywhereTheme.light();

  ThemeData get _darkTheme => _appTheme == _AppTheme.darkBlue
      ? LearnAnywhereTheme.darkBlue()
      : LearnAnywhereTheme.dark();

  ThemeMode get _themeMode => switch (_appTheme) {
        _AppTheme.system => ThemeMode.system,
        _AppTheme.light => ThemeMode.light,
        _AppTheme.dark || _AppTheme.darkBlue => ThemeMode.dark,
        _AppTheme.lightBlue => ThemeMode.light,
      };

  @override
  void initState() {
    super.initState();
    _appTheme = _appThemeFromPrefs(widget.prefs);
    _locale = _localeFromPrefs(widget.prefs);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _geometryService.dispose();
    super.dispose();
  }

  // --- Window manager callbacks ---------------------------------------------

  @override
  void onWindowResize() => _geometryService.saveGeometry();

  @override
  void onWindowMove() => _geometryService.saveGeometry();

  @override
  void onWindowMaximize() => _geometryService.saveGeometry();

  @override
  void onWindowUnmaximize() => _geometryService.saveGeometry();

  // --- Theme / locale (C4) --------------------------------------------------

  void _onAppThemeChanged(_AppTheme value) {
    setState(() => _appTheme = value);
    widget.prefs.setTheme(value.name);
  }

  void _onLocaleChanged(Locale value) {
    setState(() => _locale = value);
    widget.prefs.setLocale(value.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          LearnAnywhereLocalizations.of(context).appTitle,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      home: _DesktopHome(
        prefs: widget.prefs,
        appTheme: _appTheme,
        locale: _locale,
        onAppThemeChanged: _onAppThemeChanged,
        onLocaleChanged: _onLocaleChanged,
      ),
    );
  }
}

enum _AppTheme { system, light, dark, darkBlue, lightBlue }

_AppTheme _appThemeFromPrefs(DesktopPrefs prefs) {
  final String? name = prefs.theme;
  if (name != null) {
    for (final _AppTheme t in _AppTheme.values) {
      if (t.name == name) {
        return t;
      }
    }
  }
  return _AppTheme.system;
}

Locale _localeFromPrefs(DesktopPrefs prefs) {
  final String? code = prefs.locale;
  if (code != null && code.isNotEmpty) {
    return Locale(code);
  }
  return const Locale('en');
}

enum _DesktopRoute {
  home,
  fileOperations,
  editor,
  maskEditor,
  learn,
  queryOptions,
  statistics,
  lexicon,
  about,
}

/// The user's choice in the breaking-propagation dialog (Step 6).
enum _PropagationChoice {
  /// Abandon the save; keep editing.
  cancel,

  /// Save the `.inf` as a brand-new mask (mint a new id); leave decks alone.
  fork,

  /// Apply the mask to every matching deck, accepting the data loss.
  force,
}

/// Answer to the prompt shown when a session starts in a mode other than the
/// one the current statistics were recorded in.
enum _ModeSwitchChoice {
  /// Do not start the session; keep the setup screen up.
  cancel,

  /// Carry the existing statistics into the new mode.
  keep,

  /// Clear every statistic, then start the session from scratch.
  startFresh,
}

final class _DesktopHome extends StatefulWidget {
  const _DesktopHome({
    required this.prefs,
    required this.appTheme,
    required this.locale,
    required this.onAppThemeChanged,
    required this.onLocaleChanged,
  });

  final DesktopPrefs prefs;
  final _AppTheme appTheme;
  final Locale locale;
  final ValueChanged<_AppTheme> onAppThemeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<_DesktopHome> createState() => _DesktopHomeState();
}

final class _DesktopHomeState extends State<_DesktopHome> with WindowListener {
  final DesktopFileService _fileService = const DesktopFileService();
  final DesktopFilePicker _filePicker = const DesktopFilePicker();
  final ScrollController _menuScrollController = ScrollController();
  // The main content area lives in its own FocusScope so that keyboard focus
  // can be re-asserted into it after interactions that park focus on AppBar
  // chrome (the language/theme dropdowns) or transient overlays (dialogs),
  // none of which are inside this scope. See [_restoreContentFocus].
  final FocusScopeNode _contentFocusScope = FocusScopeNode(
    debugLabel: 'desktopContent',
  );
  _DesktopRoute _route = _DesktopRoute.home;
  // Seeded with English defaults; re-seeded from the active locale in initState.
  DesktopDocument _document = DesktopDocument.empty(_defaultMask('en'));
  DesktopQueryOptions _queryOptions = const DesktopQueryOptions();
  SessionParameters _learnParameters = const SessionParameters();
  LearnAnywhereSettings _settings = const LearnAnywhereSettings();
  UnitRangeSelection _range = const UnitRangeSelection(
    startUnit: 1,
    endUnit: 1,
  );
  String _settingsPath = '';
  String? _lastMaskPath;
  // The Mask Editor edits a linked `.inf` file (Step 4), not the deck's
  // embedded read-only cache. These hold the in-progress mask, its `.inf` path
  // (null until a save-as target is chosen), and whether it has unsaved edits.
  LearningMask? _maskEditorMask;
  String? _maskEditorPath;
  bool _maskEditorDirty = false;
  // Mask snapshot captured whenever the editor's baseline changes (open,
  // fork, new-mask), so Cancel can detect unsaved edits and revert without
  // writing anything (see [_cancelMaskEditor]).
  LearningMask? _maskEditorSnapshot;
  // Per-type last-used dialog directories (C1).
  String? _lastVokDir;
  String? _lastStaDir;
  String? _lastInfDir;
  // Last folder chosen for a Lexicon file search (Batch 8, §4.2).
  String? _lastFileSearchDir;
  int _learnSessionAttempts = 0;
  int _learnSessionCorrect = 0;
  // Bumped by Learn ▸ Practice setup; makes an already-open learn page drop
  // back to its practice setup.
  int _learnResetSignal = 0;
  // Set for one frame by Learn ▸ "Learn with last settings"; makes the learn
  // page start a session immediately with the settings already persisted,
  // whether it is already open or is being created by that command.
  bool _learnStartRequested = false;
  // Whether a learn session is currently running, which relabels that entry to
  // "Continue". Pushed up by the learn page; cleared when its route is left
  // (the page — and with it the session — is disposed on any route change).
  bool _learnSessionActive = false;
  String? _lastFileStatus;
  int? _editorInitialIndex;
  // Document snapshot captured when the editor opens, so Cancel/Esc can revert
  // to it after a confirmation (see [_cancelEditor]). Null when not editing.
  DesktopDocument? _editorSnapshot;
  List<Widget>? _cachedMenuChildren;
  String? _cachedMenuLocale;
  _AppTheme? _cachedMenuTheme;

  // --- ALT-mnemonic scoping (see docs/menu-alt-mnemonics.md) ----------------
  //
  // Flutter's MenuAcceleratorLabel registers every Alt+<letter> into one global
  // ShortcutRegistry with no per-open-menu scoping, so closed top-level menus
  // would steal Alt+<letter> from the items of whichever submenu is open. To fix
  // this, the top-level bar does NOT use MenuAcceleratorLabel; instead each
  // top-level entry is opened/activated through [_topLevelBindings], a gated
  // CallbackShortcuts layer that is disabled whenever a menu is open so the open
  // submenu's items own Alt+<letter> exclusively.
  final MenuController _fileMenuController = MenuController();
  final MenuController _editMenuController = MenuController();
  final MenuController _learnMenuController = MenuController();
  final MenuController _optionsMenuController = MenuController();
  final MenuController _helpMenuController = MenuController();

  // The two direct-action top-level entries (Statistics/Lexicon) are bare
  // MenuItemButtons. Without [skipTraversal] the MenuBar's Left/Right arrow
  // navigation lands on them and stalls (they have no submenu to open); skipping
  // them lets arrow nav jump straight to the next submenu-bearing menu. They are
  // still activated via their Alt accelerator and the mouse.
  final FocusNode _statisticsMenuFocusNode = FocusNode(
    skipTraversal: true,
    debugLabel: 'menuStatistics',
  );
  final FocusNode _lexiconMenuFocusNode = FocusNode(
    skipTraversal: true,
    debugLabel: 'menuLexicon',
  );

  /// Number of top-level submenus currently open (0 or 1 in practice; a counter
  /// keeps the close-one/open-another transition from briefly reading "closed").
  int _openMenuCount = 0;
  bool get _menuActive => _openMenuCount > 0;

  /// Current locale's top-level accelerators (lower-case access char -> action),
  /// refreshed each [build] and consumed by [_handleMenuAccelerator].
  Map<String, VoidCallback> _topLevelAccelerators = <String, VoidCallback>{};

  void _onMenuOpened() {
    setState(() => _openMenuCount++);
  }

  void _onMenuClosed() {
    setState(() {
      if (_openMenuCount > 0) _openMenuCount--;
    });
    // Closing a menu — with Esc, by clicking away, or by activating an item
    // that does not change route — otherwise leaves keyboard focus parked on
    // the MenuBar, and the active page's widget-scoped F-key/Esc shortcuts
    // never see another key event until the user clicks back into the body.
    // Deferred one frame and re-checked, so arrow-key navigation between
    // top-level menus (close one, open the next) leaves focus with the menu
    // that just opened.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && !_menuActive) {
        _restoreContentFocus();
      }
    });
  }

  /// Low-level key handler for the top-level menu accelerators.
  ///
  /// Handling them here (rather than via `MenuAcceleratorLabel`/`Shortcuts`)
  /// matters on Windows: a [HardwareKeyboard] handler's return value is what marks
  /// the key event handled for the embedder, which suppresses the system "ding".
  /// We also consume the bare **left** Alt so Windows never enters menu-mode (the
  /// other source of the ding). Right Alt (AltGr) is deliberately left alone so
  /// German keyboards can still type `@ € { }` etc.
  bool _handleMenuAccelerator(KeyEvent event) {
    // Swallow the bare left-Alt press/release to keep Windows out of menu-mode.
    if (event.logicalKey == LogicalKeyboardKey.altLeft) {
      return true;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }
    // While a menu is open, its items own Alt+<letter>; don't intercept.
    if (_menuActive) {
      return false;
    }
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    // Require Alt, but reject AltGr (reported as Control+AltRight).
    if (!keyboard.isAltPressed || keyboard.isControlPressed) {
      return false;
    }
    final String? character = event.character?.toLowerCase();
    if (character == null || character.isEmpty) {
      return false;
    }
    final VoidCallback? action = _topLevelAccelerators[character];
    if (action == null) {
      return false;
    }
    action();
    return true;
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    HardwareKeyboard.instance.addHandler(_handleMenuAccelerator);
    _settingsPath = _fileService.settingsFilePath();
    _range = resetUnitRange(_document.deck.units.length);
    _queryOptions = _optionsFromSettings(_settings);
    _learnParameters = _parametersFromSettings(_settings);
    // Load per-type dialog directories from shared_preferences (C1).
    _lastVokDir = widget.prefs.lastDirVok;
    _lastStaDir = widget.prefs.lastDirSta;
    _lastInfDir = widget.prefs.lastDirInf;
    _lastFileSearchDir = widget.prefs.lastDirFileSearch;
    // Re-seed the default deck's mask in the active UI language, and apply the
    // persisted auto-load/auto-save statistics toggles (C11; both default OFF).
    _document =
        DesktopDocument.empty(
          _defaultMask(widget.locale.languageCode),
        ).copyWith(
          autoLoadStatistics: widget.prefs.autoLoadStats,
          autoSaveStatistics: widget.prefs.autoSaveStats,
        );
    unawaited(_loadSettings());
  }

  @override
  void didUpdateWidget(_DesktopHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A locale or theme change is triggered from the Options submenu in the
    // MenuBar, which lives OUTSIDE the content FocusScope. Selecting an item
    // leaves keyboard focus parked on the menu, so the active page's
    // Shortcuts/Actions (F-keys, Esc) stop receiving key events until the user
    // clicks back into the body. We detect either change here, clear the menu
    // cache so radio checkmarks reflect the new state, and pull focus back into
    // the content scope to re-activate page shortcuts immediately.
    if (widget.locale != oldWidget.locale ||
        widget.appTheme != oldWidget.appTheme) {
      _cachedMenuChildren = null;
      _restoreContentFocus();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    HardwareKeyboard.instance.removeHandler(_handleMenuAccelerator);
    _menuScrollController.dispose();
    _contentFocusScope.dispose();
    _statisticsMenuFocusNode.dispose();
    _lexiconMenuFocusNode.dispose();
    super.dispose();
  }

  /// Handles the title-bar X close.
  ///
  /// Routes through the same [_confirmAndExit] sequence as File→Exit — confirm,
  /// auto-save statistics/settings, then `exit(0)` — so the two paths cannot
  /// drift apart. `setPreventClose(true)` in `main` is what routes the close
  /// here; cancelling any prompt leaves the window open.
  @override
  Future<void> onWindowClose() => _confirmAndExit();

  /// Re-asserts keyboard focus into the main content area so the active page's
  /// Shortcuts/Actions keep receiving F-key and Esc events.
  ///
  /// Used as a belt-and-suspenders guard after anything that can move focus
  /// outside the content scope: the AppBar language/theme menus and the modal
  /// file dialogs. Requesting focus on the scope re-homes primary focus to its
  /// most recent descendant — the page's autofocus [Focus] node — which is the
  /// surface the shortcuts are registered above.
  void _restoreContentFocus() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted) {
        return;
      }
      // Never pull focus out from under a modal that is still up (a
      // confirmation dialog, or one a menu item just opened): while a dialog
      // route is current, its own scope owns the keyboard.
      if (ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      _contentFocusScope.requestFocus();
    });
  }

  // --- Settings persistence -------------------------------------------------

  DesktopQueryOptions _optionsFromSettings(LearnAnywhereSettings settings) {
    return DesktopQueryOptions(
      wrongInputCorrectable: settings.wrongInputCorrectable,
      completeInputRequired: settings.completeInputRequired,
      caseSensitive: settings.caseSensitive,
      accentSensitive: settings.accentSensitive,
      almostEnabled: settings.almostEnabled,
      almostThreshold: settings.almostThreshold,
      showClock: settings.showClock,
      timeLimitSeconds: settings.timeLimitSeconds,
      minimumAttemptsGuardEnabled: settings.minimumAttemptsGuardEnabled,
      minAttempts: settings.minAttempts,
      wrongAnswerCeilingEnabled: settings.wrongAnswerCeilingEnabled,
      wrongAnswerCeiling: settings.wrongAnswerCeiling,
    );
  }

  SessionParameters _parametersFromSettings(LearnAnywhereSettings settings) {
    return SessionParameters(
      directionSelection: settings.direction,
      withInput: settings.requireTypedAnswers,
      mode: settings.mode,
      shuffle: settings.shuffle,
      masteryThreshold: settings.masteryThreshold,
      startIndex: _range.startUnit,
      endIndex: _range.endUnit,
    );
  }

  Future<void> _loadSettings() async {
    final LearnAnywhereSettings loaded = await readSettingsFile(_settingsPath);
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = loaded;
      _lastMaskPath = loaded.lastMaskPath;
      _queryOptions = _optionsFromSettings(loaded);
      _learnParameters = _parametersFromSettings(loaded);
    });
  }

  Future<void> _saveSettings() async {
    final LearnAnywhereSettings next = LearnAnywhereSettings(
      wrongInputCorrectable: _queryOptions.wrongInputCorrectable,
      completeInputRequired: _queryOptions.completeInputRequired,
      caseSensitive: _queryOptions.caseSensitive,
      accentSensitive: _queryOptions.accentSensitive,
      almostEnabled: _queryOptions.almostEnabled,
      almostThreshold: _queryOptions.almostThreshold,
      showClock: _queryOptions.showClock,
      timeLimitSeconds: _queryOptions.timeLimitSeconds,
      minimumAttemptsGuardEnabled: _queryOptions.minimumAttemptsGuardEnabled,
      minAttempts: _queryOptions.minAttempts,
      wrongAnswerCeilingEnabled: _queryOptions.wrongAnswerCeilingEnabled,
      wrongAnswerCeiling: _queryOptions.wrongAnswerCeiling,
      mode: _learnParameters.mode,
      direction: _learnParameters.directionSelection,
      shuffle: _learnParameters.shuffle,
      requireTypedAnswers: _learnParameters.withInput,
      masteryThreshold: _learnParameters.masteryThreshold,
      // Level-Learning settings are edited elsewhere (setup entry-level control
      // and the level-name panel) and live only on _settings, so carry them
      // forward here rather than resetting them to defaults on every save.
      entryLevelCap: _settings.entryLevelCap,
      levelNamesEn: _settings.levelNamesEn,
      levelNamesDe: _settings.levelNamesDe,
      lastDeckPath: _document.deckPath ?? _settings.lastDeckPath,
      lastMaskPath: _lastMaskPath ?? _settings.lastMaskPath,
    );
    _settings = next;
    await writeSettingsFile(_settingsPath, next);
  }

  // --- Per-file unit range --------------------------------------------------

  UnitRangeSelection _clampRange(UnitRangeSelection range, int unitCount) {
    final int maximum = unitCount < 1 ? 1 : unitCount;
    return range.copyWith(
      startUnit: range.startUnit.clamp(1, maximum).toInt(),
      endUnit: range.endUnit.clamp(1, maximum).toInt(),
    );
  }

  /// Resets Start/End to the full range when a new or different file is loaded.
  void _resetRangeForDeck() {
    _range = resetUnitRange(_document.deck.units.length);
    _learnParameters = _learnParameters.copyWith(
      startIndex: _range.startUnit,
      endIndex: _range.endUnit,
    );
  }

  // --- Auto-load / auto-save statistics toggles (C11) -----------------------

  void _setAutoLoadStats(bool value) {
    setState(() {
      _document = _document.copyWith(autoLoadStatistics: value);
      // The menu is cached across rebuilds; drop the cache so the checkmark
      // reflects the new state.
      _cachedMenuChildren = null;
    });
    widget.prefs.setAutoLoadStats(value);
  }

  void _setAutoSaveStats(bool value) {
    setState(() {
      _document = _document.copyWith(autoSaveStatistics: value);
      _cachedMenuChildren = null;
    });
    widget.prefs.setAutoSaveStats(value);
  }

  /// Options ▸ Statistics ▸ "Keep last N session files...": prompts for the
  /// retention count ([LearnAnywhereSettings.keepStatisticsVersions]) and
  /// persists the choice. `0` disables pruning.
  Future<void> _promptKeepStatisticsVersions() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final TextEditingController controller = TextEditingController(
      text: _settings.keepStatisticsVersions.toString(),
    );
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            messages.message(LearnAnywhereMessage.keepStatisticsTitle),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                autofocus: true,
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: messages.message(
                    LearnAnywhereMessage.keepStatisticsLabel,
                  ),
                ),
                onSubmitted: (String value) =>
                    Navigator.of(ctx).pop(int.tryParse(value)),
              ),
              const SizedBox(height: 8),
              Text(
                messages.message(LearnAnywhereMessage.keepStatisticsHint),
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(int.tryParse(controller.text)),
              child: Text(
                messages.message(LearnAnywhereMessage.actionContinue),
              ),
            ),
          ],
        );
      },
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() {
      _settings = _settings.copyWith(keepStatisticsVersions: value.clamp(0, 999));
      _cachedMenuChildren = null;
    });
    unawaited(_saveSettings());
  }

  // --- Session statistics auto-save target (§3.7) ---------------------------
  //
  // Session `.sta` writes are serialized through this chain so overlapping
  // per-answer saves never race, and so a slow write never stalls the UI (each
  // save is queued, not awaited by the caller).
  Future<void> _statsSaveChain = Future<void>.value();

  /// Queues a write of [snapshot]'s statistics to [target] behind any pending
  /// session save. Failures are swallowed: an unwritable auto-save must not
  /// interrupt a live session (manual Save and the pre-switch save still
  /// surface errors normally).
  void _queueStatsSave(DesktopDocument snapshot, String target) {
    _statsSaveChain = _statsSaveChain.then((_) async {
      try {
        await _fileService.writeStatistics(snapshot, target);
      } on Object {
        // Silent during a session; see doc comment.
      }
    });
  }

  /// Queues a prune of old timestamped session `.sta` files behind any
  /// pending save, so it runs after [target]'s own write lands and never
  /// races it. A no-op when retention is off (`keepStatisticsVersions == 0`)
  /// or the deck has no folder to scan. Failures are swallowed — the same
  /// "must not interrupt a live session" rule as [_queueStatsSave].
  void _queuePruneOldStatistics(String target) {
    final int keep = _settings.keepStatisticsVersions;
    final String? deckPath = _document.deckPath;
    if (keep <= 0 || deckPath == null) {
      return;
    }
    _statsSaveChain = _statsSaveChain.then((_) async {
      try {
        await _fileService.pruneTimestampedStatistics(
          deckPath,
          keep: keep,
          protectPath: target,
        );
      } on Object {
        // Silent during a session; see doc comment.
      }
    });
  }

  /// Gate run when a session is about to start in [mode].
  ///
  /// Warns when the statistics on hand were recorded in a different kind of
  /// mode, then ensures an auto-save target exists. Returns `false` to abort.
  Future<bool> _prepareSessionStart(SessionMode mode) async {
    if (!await _confirmModeSwitch(mode) || !mounted) {
      return false;
    }
    setState(() {
      _document = _document.copyWith(lastSessionMode: mode);
    });
    _ensureAutoSaveTargetForSession();
    return true;
  }

  /// Prompts when [mode] and the mode the current statistics came from sit on
  /// opposite sides of the Level-Learning divide.
  ///
  /// Only that divide matters: the drill-style modes have always shared the
  /// same counters, so switching among them is not worth a prompt. Silent when
  /// nothing has been recorded yet, or when the recording mode is unknown (a
  /// `.sta` written before the mode was tracked).
  Future<bool> _confirmModeSwitch(SessionMode mode) async {
    final DesktopDocument doc = _document;
    final SessionMode? last = doc.lastSessionMode;
    if (last == null) {
      return true;
    }
    final bool wasLevel = last == SessionMode.levelLearning;
    final bool isLevel = mode == SessionMode.levelLearning;
    if (wasLevel == isLevel) {
      return true;
    }
    if (!hasRecordedStatistics(
      statistics: doc.statistics,
      levelStatistics: doc.levelStatistics,
    )) {
      return true;
    }
    final _ModeSwitchChoice? choice = await _showModeSwitchDialog(
      toLevelLearning: isLevel,
    );
    switch (choice) {
      case null:
      case _ModeSwitchChoice.cancel:
        return false;
      case _ModeSwitchChoice.keep:
        return true;
      case _ModeSwitchChoice.startFresh:
        if (!mounted) {
          return false;
        }
        setState(() {
          _document = _fileService.clearStatisticsInMemory(_document);
        });
        return true;
    }
  }

  /// Shows the mode-switch prompt. [toLevelLearning] picks the wording and the
  /// "keep" button's label (seeding levels vs. plain carry-over).
  Future<_ModeSwitchChoice?> _showModeSwitchDialog({
    required bool toLevelLearning,
  }) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return showDialog<_ModeSwitchChoice>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            messages.message(LearnAnywhereMessage.sessionModeSwitchTitle),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    messages.message(
                      toLevelLearning
                          ? LearnAnywhereMessage.sessionModeSwitchToLevelBody
                          : LearnAnywhereMessage.sessionModeSwitchToDrillBody,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    messages.message(
                      LearnAnywhereMessage.sessionModeSwitchFreshWarning,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ModeSwitchChoice.cancel),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ModeSwitchChoice.startFresh),
              child: Text(
                messages.message(LearnAnywhereMessage.sessionModeSwitchFresh),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_ModeSwitchChoice.keep),
              child: Text(
                messages.message(
                  toLevelLearning
                      ? LearnAnywhereMessage.sessionModeSwitchSeed
                      : LearnAnywhereMessage.sessionModeSwitchKeep,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Ensures a session started with no `.sta` loaded gets a fresh timestamped
  /// auto-save target created in the deck's folder (§3.7). A no-op when
  /// auto-saving is off, a target already exists (loaded/adopted/created), or
  /// the deck is unsaved (no folder to derive from).
  void _ensureAutoSaveTargetForSession() {
    final DesktopDocument doc = _document;
    if (!doc.autoSaveStatistics ||
        doc.autoSaveTargetPath != null ||
        doc.deckPath == null) {
      return;
    }
    final String target = _fileService.timestampedStatisticsPath(
      doc.deckPath!,
      DateTime.now(),
    );
    setState(() {
      _document = _document.copyWith(
        autoSaveTargetPath: target,
        statisticsPath: target,
      );
    });
    // Write the initial file immediately so it appears at session start.
    _queueStatsSave(_document, target);
    _queuePruneOldStatistics(target);
  }

  /// Persists statistics to the auto-save target after each check→continue
  /// cycle (§3.7). A no-op when auto-saving is suspended or off.
  void _persistSessionStatistics() {
    final DesktopDocument doc = _document;
    final String? target = doc.autoSaveTargetPath;
    if (!doc.autoSaveStatistics || target == null) {
      return;
    }
    _queueStatsSave(doc, target);
  }

  /// Auto-saves statistics to the active auto-save target before an action that
  /// would drop the current units from memory (open/new/merge/clear/exit).
  ///
  /// The target is always a file the user opted into (created this session,
  /// chosen via "Save stats as", or adopted on load), so no overwrite prompt is
  /// needed — the whole point of the target is that we keep writing to it. The
  /// `Future<bool>` return is kept so callers can still abort on failure; it
  /// only reports `false` if a caller-visible cancellation is ever reintroduced.
  Future<bool> _confirmAndAutoSaveStats() async {
    final DesktopDocument doc = _document;
    final String? target = doc.autoSaveTargetPath;
    if (!doc.autoSaveStatistics || target == null || doc.deck.units.isEmpty) {
      return true;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.saveStatistics(doc, target);
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    // Refresh the top-level accelerator map (char -> action) for the current
    // locale; [_handleMenuAccelerator] reads it. Top-level accelerators are
    // handled there (NOT via MenuAcceleratorLabel) so they can be scoped to "no
    // menu open" and so the key is marked handled at the HardwareKeyboard level,
    // which silences the Windows Alt "ding". See docs/menu-alt-mnemonics.md.
    _topLevelAccelerators = _buildTopLevelAccelerators(messages);
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.appTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Scrollbar(
              controller: _menuScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _menuScrollController,
                scrollDirection: Axis.horizontal,
                child: MenuBar(children: _menuChildren(messages)),
              ),
            ),
          ),
          // The content lives in a dedicated FocusScope so focus can be
          // restored here after the AppBar menus or a dialog steal it; see
          // [_restoreContentFocus].
          //
          // The Shortcuts/Actions pair provides a global ESC handler: any
          // non-root screen that does not handle ESC internally (Statistics,
          // Lexicon, About, Options, Mask Editor) is returned to home. Screens
          // with their own inner Shortcuts (UnitEditor, LearnSession) take
          // priority because Flutter processes the innermost Shortcuts first.
          Expanded(
            child: Shortcuts(
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.escape): _GoHomeIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  _GoHomeIntent: CallbackAction<_GoHomeIntent>(
                    onInvoke: (_) {
                      if (_route != _DesktopRoute.home &&
                          _route != _DesktopRoute.fileOperations) {
                        _selectRoute(_DesktopRoute.home);
                      }
                      return null;
                    },
                  ),
                },
                child: FocusScope(
                  node: _contentFocusScope,
                  child: _contentForRoute(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the top-level accelerator map (lower-case access char -> action),
  /// keyed off each top-level label's `&` marker so it stays in sync with the
  /// localized strings.
  ///
  /// Submenu entries open their menu via a [MenuController]; the direct-action
  /// entries (Learn/Statistics/Lexicon) select their route. Consumed by
  /// [_handleMenuAccelerator] only while no menu is open; once a menu opens, its
  /// items' own [MenuAcceleratorLabel] accelerators take over Alt+<letter>.
  Map<String, VoidCallback> _buildTopLevelAccelerators(
    LearnAnywhereLocalizations messages,
  ) {
    final List<(LearnAnywhereMessage, VoidCallback)> entries =
        <(LearnAnywhereMessage, VoidCallback)>[
          (LearnAnywhereMessage.menuFile, () => _fileMenuController.open()),
          (LearnAnywhereMessage.menuEdit, () => _editMenuController.open()),
          (LearnAnywhereMessage.menuLearn, () => _learnMenuController.open()),
          (
            LearnAnywhereMessage.menuStatistics,
            () => _selectRoute(_DesktopRoute.statistics),
          ),
          (
            LearnAnywhereMessage.menuLexicon,
            () => _selectRoute(_DesktopRoute.lexicon),
          ),
          (
            LearnAnywhereMessage.menuOptions,
            () => _optionsMenuController.open(),
          ),
          (LearnAnywhereMessage.menuHelp, () => _helpMenuController.open()),
        ];
    final Map<String, VoidCallback> accelerators = <String, VoidCallback>{};
    for (final (LearnAnywhereMessage message, VoidCallback action) in entries) {
      final String? key = MenuAcceleratorDisplayLabel.accessKeyOf(
        messages.message(message),
      );
      if (key != null) {
        accelerators[key] = action;
      }
    }
    return accelerators;
  }

  // Each build() would create new widget objects, causing _MenuAnchorState
  // .didUpdateWidget to fire on every unrelated setState (route changes, session
  // progress, clock ticks, etc.) and cascade through all MenuAcceleratorLabel
  // instances. Flutter's fast-path (skip update when child.widget == newWidget)
  // is never reached, so the resulting churn competes with
  // _MenuAcceleratorLabelState._listenToKeyEvent and causes intermittent ~1 s
  // delays before Alt-key underlines appear. Caching restores the fast-path.
  List<Widget> _menuChildren(LearnAnywhereLocalizations messages) {
    final String locale = messages.locale.languageCode;
    final _AppTheme theme = widget.appTheme;
    if (locale != _cachedMenuLocale || theme != _cachedMenuTheme) {
      _cachedMenuChildren = null;
      _cachedMenuLocale = locale;
      _cachedMenuTheme = theme;
    }
    return _cachedMenuChildren ??= _buildMenuChildren(messages);
  }

  List<Widget> _buildMenuChildren(LearnAnywhereLocalizations messages) {
    return <Widget>[
      // 1. File
      SubmenuButton(
        controller: _fileMenuController,
        onOpen: _onMenuOpened,
        onClose: _onMenuClosed,
        menuChildren: <Widget>[
          _commandItem(messages, LearnAnywhereMessage.fileOpenDeck),
          _commandItem(messages, LearnAnywhereMessage.fileAddMergeDeck),
          _commandItem(messages, LearnAnywhereMessage.fileSave),
          _commandItem(messages, LearnAnywhereMessage.fileSaveAs),
          _commandItem(messages, LearnAnywhereMessage.fileNewDeck),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileLoadMask),
          _commandItem(messages, LearnAnywhereMessage.fileSaveMask),
          _commandItem(messages, LearnAnywhereMessage.fileSaveMaskAs),
          const _MenuSeparator(),
          // Load/Save/Save-as/Clear share the Statistics screen's handlers (C12).
          _commandItem(messages, LearnAnywhereMessage.statisticsLoad),
          _commandItem(messages, LearnAnywhereMessage.statisticsSave),
          _commandItem(messages, LearnAnywhereMessage.fileSaveStatsAs),
          _commandItem(messages, LearnAnywhereMessage.statisticsClear),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileExit),
        ],
        child: MenuAcceleratorDisplayLabel(
          messages.message(LearnAnywhereMessage.menuFile),
        ),
      ),
      // 2. Edit (absorbs Mask Editor)
      SubmenuButton(
        controller: _editMenuController,
        onOpen: _onMenuOpened,
        onClose: _onMenuClosed,
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.editor),
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuEditUnitEditor),
              builder: menuAcceleratorBuilder,
            ),
          ),
          MenuItemButton(
            onPressed: _openEditorSearch,
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuEditSearchUnit),
              builder: menuAcceleratorBuilder,
            ),
          ),
          MenuItemButton(
            onPressed: _openEditorJump,
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuEditJumpToNumber),
              builder: menuAcceleratorBuilder,
            ),
          ),
          const _MenuSeparator(),
          MenuItemButton(
            onPressed: _openMaskEditor,
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuMaskEditor),
              builder: menuAcceleratorBuilder,
            ),
          ),
          MenuItemButton(
            onPressed: _updateMaskCopies,
            child: MenuAcceleratorLabel(
              messages.message(
                LearnAnywhereMessage.menuEditUpdateMaskCopies,
              ),
              builder: menuAcceleratorBuilder,
            ),
          ),
        ],
        child: MenuAcceleratorDisplayLabel(
          messages.message(LearnAnywhereMessage.menuEdit),
        ),
      ),
      // 3. Learn (setup vs. start/resume — see [_openLearnSetup]/[_continueLearn])
      SubmenuButton(
        controller: _learnMenuController,
        onOpen: _onMenuOpened,
        onClose: _onMenuClosed,
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: _openLearnSetup,
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuLearnPracticeSetup),
              builder: menuAcceleratorBuilder,
            ),
          ),
          MenuItemButton(
            onPressed: _continueLearn,
            child: MenuAcceleratorLabel(
              messages.message(
                _learnSessionActive
                    ? LearnAnywhereMessage.menuLearnContinue
                    : LearnAnywhereMessage.menuLearnWithLastSettings,
              ),
              builder: menuAcceleratorBuilder,
            ),
          ),
        ],
        child: MenuAcceleratorDisplayLabel(
          messages.message(LearnAnywhereMessage.menuLearn),
        ),
      ),
      // 4. Statistics (direct)
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuStatistics,
        _DesktopRoute.statistics,
        _statisticsMenuFocusNode,
      ),
      // 5. Lexicon (direct)
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuLexicon,
        _DesktopRoute.lexicon,
        _lexiconMenuFocusNode,
      ),
      // 6. Options (new)
      SubmenuButton(
        controller: _optionsMenuController,
        onOpen: _onMenuOpened,
        onClose: _onMenuClosed,
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.queryOptions),
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuOptionsAdvancedLearning),
              builder: menuAcceleratorBuilder,
            ),
          ),
          const _MenuSeparator(),
          SubmenuButton(
            menuChildren: <Widget>[
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.system,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: MenuAcceleratorLabel(
                  messages.message(LearnAnywhereMessage.themeSystem),
                  builder: menuAcceleratorBuilder,
                ),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.light,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: MenuAcceleratorLabel(
                  messages.message(LearnAnywhereMessage.themeLight),
                  builder: menuAcceleratorBuilder,
                ),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.dark,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: MenuAcceleratorLabel(
                  messages.message(LearnAnywhereMessage.themeDark),
                  builder: menuAcceleratorBuilder,
                ),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.darkBlue,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: MenuAcceleratorLabel(
                  messages.message(LearnAnywhereMessage.themeDarkBlue),
                  builder: menuAcceleratorBuilder,
                ),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.lightBlue,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: MenuAcceleratorLabel(
                  messages.message(LearnAnywhereMessage.themeLightBlue),
                  builder: menuAcceleratorBuilder,
                ),
              ),
            ],
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.themeLabel),
              builder: menuAcceleratorBuilder,
            ),
          ),
          SubmenuButton(
            menuChildren: <Widget>[
              RadioMenuButton<Locale>(
                value: const Locale('en'),
                groupValue: widget.locale,
                onChanged: (Locale? v) {
                  if (v != null) widget.onLocaleChanged(v);
                },
                child: MenuAcceleratorLabel(
                  messages.message(LearnAnywhereMessage.languageEnglish),
                  builder: menuAcceleratorBuilder,
                ),
              ),
              RadioMenuButton<Locale>(
                value: const Locale('de'),
                groupValue: widget.locale,
                onChanged: (Locale? v) {
                  if (v != null) widget.onLocaleChanged(v);
                },
                child: MenuAcceleratorLabel(
                  messages.message(LearnAnywhereMessage.languageGerman),
                  builder: menuAcceleratorBuilder,
                ),
              ),
            ],
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.languageLabel),
              builder: menuAcceleratorBuilder,
            ),
          ),
          const _MenuSeparator(),
          SubmenuButton(
            menuChildren: <Widget>[
              CheckboxMenuButton(
                value: _document.autoLoadStatistics,
                onChanged: (bool? value) => _setAutoLoadStats(value ?? false),
                child: MenuAcceleratorLabel(
                  messages.message(
                    LearnAnywhereMessage.menuOptionsAutoLoadStats,
                  ),
                  builder: menuAcceleratorBuilder,
                ),
              ),
              CheckboxMenuButton(
                value: _document.autoSaveStatistics,
                onChanged: (bool? value) => _setAutoSaveStats(value ?? false),
                child: MenuAcceleratorLabel(
                  messages.message(
                    LearnAnywhereMessage.menuOptionsAutoSaveStats,
                  ),
                  builder: menuAcceleratorBuilder,
                ),
              ),
              MenuItemButton(
                onPressed: _promptKeepStatisticsVersions,
                child: MenuAcceleratorLabel(
                  messages
                      .message(LearnAnywhereMessage.menuOptionsKeepStatistics)
                      .replaceAll(
                        '{count}',
                        _settings.keepStatisticsVersions.toString(),
                      ),
                  builder: menuAcceleratorBuilder,
                ),
              ),
            ],
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuOptionsStatistics),
              builder: menuAcceleratorBuilder,
            ),
          ),
        ],
        child: MenuAcceleratorDisplayLabel(
          messages.message(LearnAnywhereMessage.menuOptions),
        ),
      ),
      // 7. Help
      SubmenuButton(
        controller: _helpMenuController,
        onOpen: _onMenuOpened,
        onClose: _onMenuClosed,
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.about),
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.helpAbout),
              builder: menuAcceleratorBuilder,
            ),
          ),
        ],
        child: MenuAcceleratorDisplayLabel(
          messages.message(LearnAnywhereMessage.menuHelp),
        ),
      ),
    ];
  }

  MenuItemButton _commandItem(
    LearnAnywhereLocalizations messages,
    LearnAnywhereMessage message,
  ) {
    return MenuItemButton(
      onPressed: () => _runFileCommand(message),
      child: MenuAcceleratorLabel(messages.message(message), builder: menuAcceleratorBuilder),
    );
  }

  MenuItemButton _routeMenu(
    LearnAnywhereLocalizations messages,
    LearnAnywhereMessage message,
    _DesktopRoute route,
    FocusNode focusNode, {
    VoidCallback? onPressed,
  }) {
    return MenuItemButton(
      onPressed: onPressed ?? () => _selectRoute(route),
      // Skip-traversal node so arrow navigation jumps over this submenu-less entry.
      focusNode: focusNode,
      // Top-level direct action: display-only label; activation is handled by
      // [_handleMenuAccelerator] so it doesn't collide with open-submenu items.
      child: MenuAcceleratorDisplayLabel(messages.message(message)),
    );
  }

  /// Learn ▸ Practice setup: opens the Learn page on its setup screen.
  ///
  /// The reset signal makes an already-open page leave whatever it is showing
  /// (a running session or the completion view) and return to setup.
  void _openLearnSetup() {
    setState(() => _learnResetSignal++);
    _selectRoute(_DesktopRoute.learn);
  }

  /// Learn ▸ "Learn with last settings" / "Continue".
  ///
  /// With no session running this starts one straight away from the persisted
  /// settings (or the defaults, when nothing has been saved yet); with one
  /// running it just returns to it.
  void _continueLearn() {
    if (!_learnSessionActive) {
      // One-frame request: the page consumes it on creation or on rebuild, so
      // it is cleared again right after this frame.
      setState(() => _learnStartRequested = true);
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _learnStartRequested) {
          setState(() => _learnStartRequested = false);
        }
      });
    }
    _selectRoute(_DesktopRoute.learn);
  }

  /// Tracks whether the learn page currently has a session running, so the
  /// Learn menu can offer "Continue" instead of a fresh start.
  void _setLearnSessionActive(bool active) {
    if (_learnSessionActive == active) {
      return;
    }
    setState(() {
      _learnSessionActive = active;
      // The menu cache is keyed by locale/theme only; this label depends on
      // session state, so drop the cache by hand.
      _cachedMenuChildren = null;
    });
  }

  void _selectRoute(_DesktopRoute route) {
    // Leaving the learn route disposes the page and with it the session, so
    // the entry must go back to offering a fresh start.
    if (_route == _DesktopRoute.learn && route != _DesktopRoute.learn) {
      _setLearnSessionActive(false);
    }
    setState(() {
      // Snapshot the document when first entering the editor so Cancel can
      // revert to it. Re-entering menu actions while already editing keep the
      // original snapshot.
      if (route == _DesktopRoute.editor && _route != _DesktopRoute.editor) {
        _editorSnapshot = _document;
        // Land on the last unit — the common case is appending new ones —
        // rather than the first, which used to require a manual jump.
        final int unitCount = _document.deck.units.length;
        _editorInitialIndex = unitCount == 0 ? null : unitCount - 1;
      }
      _route = route;
    });
    // Learn/Statistics/Lexicon/Edit are opened from MenuBar entries outside
    // the content FocusScope; re-assert focus so the destination page's
    // F-key/Esc shortcuts are live immediately.
    _restoreContentFocus();
  }

  /// Finishes editing (F10/Done): keeps the changes and drops the snapshot.
  void _finishEditor() {
    _editorSnapshot = null;
    _selectRoute(_DesktopRoute.home);
  }

  /// Cancels editing (Esc): if the deck changed since the editor opened, asks
  /// to discard; on confirm, restores the snapshot (deck, statistics, and
  /// range) before returning home.
  Future<void> _cancelEditor() async {
    final DesktopDocument? snapshot = _editorSnapshot;
    final bool changed =
        snapshot != null &&
        encodeDeckJson(_document.deck) != encodeDeckJson(snapshot.deck);
    if (changed) {
      final bool discard = await _confirm(
        LearnAnywhereMessage.confirmDiscardEdits,
      );
      if (!discard) {
        return;
      }
      setState(() {
        _document = snapshot;
        _range = _clampRange(_range, _document.deck.units.length);
        _learnParameters = _learnParameters.copyWith(
          startIndex: _range.startUnit,
          endIndex: _range.endUnit,
        );
      });
    }
    _editorSnapshot = null;
    if (mounted) {
      _selectRoute(_DesktopRoute.home);
    }
  }

  /// Opens the Mask Editor on the `.inf` LINKED to the loaded deck (Step 4).
  ///
  /// Resolves the linked mask by scanning the deck's OWN directory for an
  /// `.inf` whose maskId matches the deck's embedded maskId. If none exists,
  /// offers to create one from the embedded mask (reusing its maskId — never
  /// minting a new one). When no deck is saved yet, edits the in-memory mask
  /// and prompts for a save target on close. The deck's embedded mask is a
  /// read-only cache and is never edited here.
  Future<void> _openMaskEditor() async {
    final String? deckPath = _document.deckPath;
    if (deckPath == null) {
      // _lastMaskPath is "the last .inf this app touched" — unrelated to the
      // in-memory mask's identity unless it demonstrably describes the SAME
      // mask. Reusing it blindly can silently overwrite a completely
      // different mask file (see B8). Only reuse it when its own maskId
      // matches; otherwise the editor targets no file and prompts for a save
      // destination on close.
      String? resolvedPath;
      final String? candidate = _lastMaskPath;
      if (candidate != null) {
        try {
          final LearningMask candidateMask = await _fileService.readMask(
            candidate,
          );
          if (candidateMask.maskId == _document.mask.maskId) {
            resolvedPath = candidate;
          }
        } on Object {
          resolvedPath = null;
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _maskEditorMask = _document.mask;
        _maskEditorSnapshot = _document.mask;
        _maskEditorPath = resolvedPath;
        _maskEditorDirty = false;
        _editorInitialIndex = null;
        _route = _DesktopRoute.maskEditor;
      });
      return;
    }
    String? linked;
    try {
      linked = await _fileService.findLinkedMaskPath(
        deckPath,
        _document.mask.maskId,
      );
    } on Object {
      linked = null;
    }
    if (linked == null) {
      final bool create = await _confirm(
        LearnAnywhereMessage.confirmCreateLinkedMask,
      );
      if (!create) {
        return;
      }
    }
    final String? resolvedLink = linked;
    await _guardedFileOperation(() async {
      final LearningMask editMask;
      final String infPath;
      if (resolvedLink != null) {
        editMask = await _fileService.readMask(resolvedLink);
        infPath = resolvedLink;
      } else {
        infPath = await _fileService.createLinkedMask(deckPath, _document.mask);
        editMask = _document.mask;
        _setLastDir('inf', infPath);
        unawaited(_saveSettings());
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _maskEditorMask = editMask;
        _maskEditorSnapshot = editMask;
        _maskEditorPath = infPath;
        _maskEditorDirty = false;
        _editorInitialIndex = null;
        _route = _DesktopRoute.maskEditor;
      });
    });
  }

  /// Saves the edited `.inf` (bumping its revision) when it has changed, then
  /// propagates it to same-directory decks (Step 6) and returns home. An
  /// unedited session leaves the file untouched.
  Future<void> _closeMaskEditor() async {
    final LearningMask? mask = _maskEditorMask;
    if (mask == null || !_maskEditorDirty) {
      _clearMaskEditorState();
      _selectRoute(_DesktopRoute.home);
      return;
    }
    String? path = _maskEditorPath;
    if (path == null) {
      path = await _pickSavePath(
        extension: 'inf',
        typeLabel: LearnAnywhereMessage.filePickerMaskType,
        suggestedName: _suggestedName(
          _lastMaskPath ?? _settings.lastMaskPath,
          'learn_anywhere.inf',
        ),
      );
      if (path == null) {
        // Cancelled the save target: stay in the editor rather than lose edits.
        return;
      }
    }
    final String infPath = _ensureExtension(path, 'inf');
    // A revision is bumped on each `.inf` save.
    var saved = mask.copyWith(revision: mask.revision + 1);
    final String directory = _filePicker.directoryOf(infPath);

    await _guardedFileOperation(() async {
      // Tier-1 propagation: classify same-directory decks sharing this maskId.
      final MaskPropagationPlan plan = await _fileService.planMaskPropagation(
        maskDirectory: directory,
        newMask: saved,
        excludePaths: <String>[
          if (_document.deckPath != null) _document.deckPath!,
        ],
      );

      if (plan.hasBreaking) {
        final _PropagationChoice? choice =
            await _showBreakingPropagationDialog(plan);
        if (choice == null || choice == _PropagationChoice.cancel) {
          // Nothing written; stay in the editor with edits intact.
          return;
        }
        if (choice == _PropagationChoice.fork) {
          // Fork: the .inf becomes a brand-new mask; no existing deck matches
          // its new id, so nothing propagates. Existing decks keep the old one.
          saved = saved.copyWith(maskId: mintNewMaskId());
          await _fileService.saveMask(saved, infPath);
          _finishMaskSave(infPath, saved, updatedDeckCount: 0);
          return;
        }
        // Force: accept the data loss and overwrite every matching deck.
        await _fileService.saveMask(saved, infPath);
        await _fileService.applyMaskPropagation(
          newMask: saved,
          deckPaths: plan.allPaths,
        );
        final bool openDeckWritten = await _applyMaskToLoadedDeck(
          saved,
          force: true,
        );
        _finishMaskSave(
          infPath,
          saved,
          updatedDeckCount: plan.allPaths.length + (openDeckWritten ? 1 : 0),
        );
        return;
      }

      // No breaking decks: ask which compatible siblings to update (unless
      // there are none, in which case there is nothing to confirm).
      List<String> toUpdate = plan.compatible;
      if (plan.compatible.isNotEmpty) {
        final List<String>? checked = await _showPropagationConfirmDialog(
          plan.compatible,
        );
        if (checked == null) {
          // Cancelled: nothing written; stay in the editor with edits intact.
          return;
        }
        toUpdate = checked;
      }
      await _fileService.saveMask(saved, infPath);
      await _fileService.applyMaskPropagation(
        newMask: saved,
        deckPaths: toUpdate,
      );
      final bool openDeckWritten = await _applyMaskToLoadedDeck(
        saved,
        force: false,
      );
      _finishMaskSave(
        infPath,
        saved,
        updatedDeckCount: toUpdate.length + (openDeckWritten ? 1 : 0),
      );
    });
  }

  /// Confirms which compatible sibling decks to update before writing
  /// anything (Step 6 tier-1 propagation). All entries are checked by
  /// default; unchecking one leaves that deck's file untouched. Returns
  /// `null` on cancel.
  Future<List<String>?> _showPropagationConfirmDialog(
    List<String> paths,
  ) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final Set<String> selected = paths.toSet();
    return showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setInnerState) {
            return AlertDialog(
              title: Text(
                messages.message(LearnAnywhereMessage.propagationConfirmTitle),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        messages.message(
                          LearnAnywhereMessage.propagationConfirmBody,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final String path in paths)
                        Row(
                          children: <Widget>[
                            Checkbox(
                              value: selected.contains(path),
                              onChanged: (bool? value) {
                                setInnerState(() {
                                  if (value ?? false) {
                                    selected.add(path);
                                  } else {
                                    selected.remove(path);
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Text(_filePicker.fileNameOf(path)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    messages.message(LearnAnywhereMessage.actionCancel),
                  ),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(selected.toList()),
                  child: Text(messages.message(LearnAnywhereMessage.maskSyncApply)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Common bookkeeping after a mask save completes.
  void _finishMaskSave(
    String infPath,
    LearningMask saved, {
    required int updatedDeckCount,
  }) {
    _lastMaskPath = infPath;
    _setLastDir('inf', infPath);
    _clearMaskEditorState();
    _setFileStatus(
      updatedDeckCount > 0
          ? LearnAnywhereMessage.fileStatusDecksUpdated
          : LearnAnywhereMessage.fileStatusMaskSaved,
      count: updatedDeckCount,
    );
    unawaited(_saveSettings());
  }

  /// Applies [saved] to the in-memory loaded deck when it is the same mask and
  /// the change is safe (or [force] is set), then writes the deck to its own
  /// file so it doesn't silently keep a stale embedded mask on disk until the
  /// next explicit File ▸ Save (Batch 12 write-through fix — previously only
  /// sibling decks were written here; see [_reconcileLinkedMask] for the
  /// complementary read-side fix).
  ///
  /// Returns whether the deck's file was written, so the caller can fold it
  /// into the "decks updated" count.
  Future<bool> _applyMaskToLoadedDeck(
    LearningMask saved, {
    required bool force,
  }) async {
    if (_document.mask.maskId != saved.maskId) {
      return false;
    }
    if (!force) {
      final MaskCompatibilityResult result = checkMaskCompatibility(
        oldMask: _document.mask,
        newMask: saved,
        units: _document.deck.units,
      );
      if (!result.isCompatible) {
        return false;
      }
    }
    final LearningDeck updatedDeck = applyMaskToDeck(_document.deck, saved);
    setState(() {
      _document = _document.copyWith(deck: updatedDeck);
    });
    final String? deckPath = _document.deckPath;
    if (deckPath == null) {
      return false;
    }
    await _fileService.saveDeckSnapshot(updatedDeck, deckPath);
    return true;
  }

  Future<_PropagationChoice?> _showBreakingPropagationDialog(
    MaskPropagationPlan plan,
  ) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return showDialog<_PropagationChoice>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            messages.message(LearnAnywhereMessage.propagationBreakingTitle),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    messages.message(
                      LearnAnywhereMessage.propagationBreakingBody,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final DeckBreak deck in plan.breaking) ...<Widget>[
                    Text(
                      _filePicker.fileNameOf(deck.deckPath),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final MaskBreakingReason reason in deck.reasons)
                      Text('• ${describeBreakingReason(messages, reason)}'),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_PropagationChoice.cancel),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_PropagationChoice.fork),
              child: Text(messages.message(LearnAnywhereMessage.actionForkMask)),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(_PropagationChoice.force),
              child: Text(
                messages.message(LearnAnywhereMessage.actionForceUpdate),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tier-2 sync (Step 7): find every copy of the current mask under a chosen
  /// folder and update the selected ones. The current in-memory mask is the
  /// reference; copies that differ at the same revision, or decks that would
  /// break, are shown but never auto-merged.
  Future<void> _updateMaskCopies() async {
    final LearningMask reference = _document.mask;
    final String? defaultDir = _document.deckPath == null
        ? _lastInfDir
        : _filePicker.directoryOf(_document.deckPath!);
    final String? root = await _filePicker.pickDirectory(
      initialDirectory: defaultDir,
    );
    if (root == null) {
      return;
    }
    await _guardedFileOperation(() async {
      final List<MaskSyncEntry> entries = await _fileService.scanMaskCopies(
        root: root,
        reference: reference,
      );
      if (!mounted) {
        return;
      }
      if (entries.isEmpty) {
        _setFileStatus(
          LearnAnywhereMessage.maskSyncNoneFound,
          placeholders: <String, String>{'folder': root},
        );
        return;
      }
      final List<String>? selected = await MaskSyncDialog.show(
        context,
        entries,
        referenceName: reference.name,
        referenceRevision: reference.revision,
        referenceSourcePath: _document.deckPath,
      );
      if (selected == null || selected.isEmpty) {
        return;
      }
      await _fileService.applyMaskSync(reference: reference, paths: selected);
      // Keep the open deck in sync when it was one of the updated copies.
      final String? deckPath = _document.deckPath;
      if (deckPath != null && selected.contains(deckPath)) {
        setState(() {
          _document = _document.copyWith(
            deck: applyMaskToDeck(_document.deck, reference),
          );
        });
      }
      _setFileStatus(LearnAnywhereMessage.maskSyncDone, count: selected.length);
    });
  }

  /// Forks the mask currently open in the Mask Editor into a brand-new,
  /// independent mask (fresh `maskId`, revision reset to 0), written to a
  /// user-chosen `.inf` path. The original file is left untouched. This is
  /// the only way to give a mask a new identity on demand — the recovery
  /// path for decks whose identity got tangled by a prior sharing bug.
  Future<void> _forkMask() async {
    final LearningMask? mask = _maskEditorMask;
    if (mask == null) {
      return;
    }
    final String? newPath = await _pickSavePath(
      extension: 'inf',
      typeLabel: LearnAnywhereMessage.filePickerMaskType,
      suggestedName: _suggestedName(_maskEditorPath, 'learn_anywhere.inf'),
    );
    if (newPath == null) {
      return;
    }
    final String infPath = _ensureExtension(newPath, 'inf');
    final LearningMask forked = mask.copyWith(
      maskId: mintNewMaskId(),
      revision: 0,
    );
    await _guardedFileOperation(() async {
      await _fileService.saveMask(forked, infPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _maskEditorMask = forked;
        _maskEditorSnapshot = forked;
        _maskEditorPath = infPath;
        _maskEditorDirty = false;
      });
      _setLastDir('inf', infPath);
      // Only offer to re-link when the currently loaded deck is actually the
      // mask being forked — never relink an unrelated in-memory document.
      if (_document.mask.maskId == mask.maskId &&
          _document.deck.units.isNotEmpty) {
        final bool relink = await _confirm(
          LearnAnywhereMessage.confirmForkRelinkDeck,
        );
        if (relink && mounted) {
          setState(() {
            _document = _document.copyWith(
              deck: applyMaskToDeck(_document.deck, forked),
            );
          });
          if (_document.deckPath != null) {
            _document = await _fileService.saveDeck(_document);
          }
        }
      }
    });
  }

  void _clearMaskEditorState() {
    _maskEditorMask = null;
    _maskEditorSnapshot = null;
    _maskEditorPath = null;
    _maskEditorDirty = false;
  }

  /// Cancels the Mask Editor: if the mask changed since it was opened (or
  /// last forked/created), confirms discarding those in-memory edits, then
  /// returns home WITHOUT writing anything — mirrors [_cancelEditor] for the
  /// Unit Editor.
  Future<void> _cancelMaskEditor() async {
    final LearningMask? mask = _maskEditorMask;
    final LearningMask? snapshot = _maskEditorSnapshot;
    final bool changed =
        mask != null &&
        snapshot != null &&
        encodeMaskJson(mask) != encodeMaskJson(snapshot);
    if (changed) {
      final bool discard = await _confirm(
        LearnAnywhereMessage.confirmDiscardEdits,
      );
      if (!discard) {
        return;
      }
    }
    _clearMaskEditorState();
    if (mounted) {
      _selectRoute(_DesktopRoute.home);
    }
  }

  Future<void> _openEditorSearch() async {
    if (_document.deck.units.isEmpty) return;
    final int? index = await UnitEditorPage.openSearchDialog(
      context,
      _document.deck,
    );
    if (index != null && mounted) {
      setState(() {
        if (_route != _DesktopRoute.editor) {
          _editorSnapshot = _document;
        }
        _editorInitialIndex = index;
        _route = _DesktopRoute.editor;
      });
      _restoreContentFocus();
    }
  }

  Future<void> _openEditorJump() async {
    if (_document.deck.units.isEmpty) return;
    final int? index = await UnitEditorPage.openJumpDialog(
      context,
      _document.deck,
    );
    if (index != null && mounted) {
      setState(() {
        if (_route != _DesktopRoute.editor) {
          _editorSnapshot = _document;
        }
        _editorInitialIndex = index;
        _route = _DesktopRoute.editor;
      });
      _restoreContentFocus();
    }
  }

  Widget _contentForRoute() {
    return switch (_route) {
      _DesktopRoute.home => _HomeScreen(
        document: _document,
        lastDeckPath: _settings.lastDeckPath,
        lastMaskPath: _lastMaskPath ?? _settings.lastMaskPath,
        onOpenLastDeck: _openDeckPath,
      ),
      _DesktopRoute.fileOperations => _FileOperationsStatus(
        document: _document,
        status: _lastFileStatus,
      ),
      _DesktopRoute.editor => UnitEditorPage(
        deck: _document.deck,
        initialIndex: _editorInitialIndex,
        onChanged: _updateDeckFromEditor,
        onDone: _finishEditor,
        onCancel: _cancelEditor,
      ),
      _DesktopRoute.maskEditor => MaskEditorPage(
        // Edits the linked `.inf` mask, never the deck's embedded cache.
        mask: _maskEditorMask ?? _document.mask,
        onChanged: (LearningMask value) {
          setState(() {
            _maskEditorMask = value;
            _maskEditorDirty = true;
          });
        },
        onClose: _closeMaskEditor,
        onCancel: _cancelMaskEditor,
        linkedPath: _maskEditorPath,
        onFork: _forkMask,
      ),
      _DesktopRoute.learn => LearnSessionPage(
        deck: _document.deck,
        statistics: _document.statistics,
        levelStatistics: _document.levelStatistics,
        levelNames: widget.locale.languageCode == 'de'
            ? _settings.levelNamesDe
            : _settings.levelNamesEn,
        entryLevelCap: _settings.entryLevelCap,
        resetToSetupSignal: _learnResetSignal,
        startSessionOnOpen: _learnStartRequested,
        onSessionActiveChanged: _setLearnSessionActive,
        options: _queryOptions,
        parameters: _learnParameters,
        sessionAttempts: _learnSessionAttempts,
        sessionCorrect: _learnSessionCorrect,
        onParametersChanged: (SessionParameters value) {
          setState(() => _learnParameters = value);
          unawaited(_saveSettings());
        },
        onEntryLevelCapChanged: (int value) {
          setState(() => _settings = _settings.copyWith(entryLevelCap: value));
          unawaited(_saveSettings());
        },
        onLevelStatisticsChanged: (List<LevelUnitStats> value) {
          setState(
            () => _document = _document.copyWith(levelStatistics: value),
          );
        },
        onStartUnitChanged: (int value) {
          setState(() {
            _range = _clampRange(
              _range.copyWith(startUnit: value),
              _document.deck.units.length,
            );
            _learnParameters = _learnParameters.copyWith(
              startIndex: _range.startUnit,
            );
          });
        },
        onEndUnitChanged: (int value) {
          setState(() {
            _range = _clampRange(
              _range.copyWith(endUnit: value, endManuallySet: true),
              _document.deck.units.length,
            );
            _learnParameters = _learnParameters.copyWith(
              endIndex: _range.endUnit,
            );
          });
        },
        onStatisticsChanged: (List<UnitStats> value) {
          setState(() => _document = _document.copyWith(statistics: value));
        },
        onSessionStarted: _prepareSessionStart,
        onPersistStatistics: _persistSessionStatistics,
        onSessionProgressChanged: (int attempts, int correct) {
          setState(() {
            _learnSessionAttempts = attempts;
            _learnSessionCorrect = correct;
          });
        },
        onOpenEditor: () => _selectRoute(_DesktopRoute.editor),
        onExit: () => _selectRoute(_DesktopRoute.home),
      ),
      _DesktopRoute.queryOptions => QueryOptionsPage(
        options: _queryOptions,
        levelNamesEn: _settings.levelNamesEn,
        levelNamesDe: _settings.levelNamesDe,
        onChanged: (DesktopQueryOptions value) {
          setState(() => _queryOptions = value);
          unawaited(_saveSettings());
        },
        onLevelNamesChanged:
            (List<String> levelNamesEn, List<String> levelNamesDe) {
          setState(
            () => _settings = _settings.copyWith(
              levelNamesEn: levelNamesEn,
              levelNamesDe: levelNamesDe,
            ),
          );
          unawaited(_saveSettings());
        },
        onClose: () => _selectRoute(_DesktopRoute.home),
      ),
      _DesktopRoute.statistics => StatisticsPage(
        deck: _document.deck,
        statistics: _document.statistics,
        levelStatistics: _document.levelStatistics,
        levelNames: widget.locale.languageCode == 'de'
            ? _settings.levelNamesDe
            : _settings.levelNamesEn,
        onLoadStatistics: _loadStatistics,
        onSaveStatistics: _saveStatistics,
        onSaveStatisticsAs: () => _saveStatistics(saveAs: true),
        onClearStatistics: _clearStatistics,
        onSaveSelectedUnits: _saveSelectedUnits,
        onClose: () => _selectRoute(_DesktopRoute.home),
      ),
      _DesktopRoute.lexicon => LexiconPage(
        deck: _document.deck,
        textOptions: TextMatchOptions(
          caseSensitive: _queryOptions.caseSensitive,
          accentSensitive: _queryOptions.accentSensitive,
        ),
        onPickFolderDecks: _pickLexiconFolderDecks,
        onLoadFoundDeck: _loadFoundLexiconDeck,
        onClose: () => _selectRoute(_DesktopRoute.home),
      ),
      _DesktopRoute.about => AboutPage(
        onClose: () => _selectRoute(_DesktopRoute.home),
      ),
    };
  }

  void _updateDeckFromEditor(
    LearningDeck deck, {
    int? insertedAt,
    int? deletedAt,
  }) {
    final int previousCount = _document.deck.units.length;
    final int newCount = deck.units.length;
    // Keep per-unit statistics attached to their units across edits: an insert
    // or delete shifts later indices; an append (or any other count change with
    // no position) keeps existing indices and pads/truncates; a field edit
    // leaves them untouched.
    final List<UnitStats> statistics;
    if (insertedAt != null) {
      statistics = statsAfterInsert(_document.statistics, insertedAt, newCount);
    } else if (deletedAt != null) {
      statistics = statsAfterDelete(_document.statistics, deletedAt, newCount);
    } else if (newCount != previousCount) {
      statistics = resizeUnitStats(_document.statistics, newCount);
    } else {
      statistics = _document.statistics;
    }
    setState(() {
      _document = _document.copyWith(deck: deck, statistics: statistics);
      _range = _clampRange(
        autoExpandEndUnit(
          _range,
          previousCount: previousCount,
          newCount: newCount,
        ),
        newCount,
      );
      _learnParameters = _learnParameters.copyWith(
        startIndex: _range.startUnit,
        endIndex: _range.endUnit,
      );
    });
  }

  Future<void> _runFileCommand(LearnAnywhereMessage command) async {
    switch (command) {
      case LearnAnywhereMessage.fileNewDeck:
        await _newDeck();
      case LearnAnywhereMessage.fileOpenDeck:
        await _openDeck();
      case LearnAnywhereMessage.fileAddMergeDeck:
        await _mergeDeck();
      case LearnAnywhereMessage.fileSave:
        await _saveDeck(saveAs: false);
      case LearnAnywhereMessage.fileSaveAs:
        await _saveDeck(saveAs: true);
      case LearnAnywhereMessage.fileLoadMask:
        await _loadMask();
      case LearnAnywhereMessage.fileSaveMask:
        await _saveMask();
      case LearnAnywhereMessage.fileSaveMaskAs:
        await _saveMask(saveAs: true);
      case LearnAnywhereMessage.statisticsLoad:
        await _loadStatistics();
      case LearnAnywhereMessage.statisticsSave:
        await _saveStatistics();
      case LearnAnywhereMessage.fileSaveStatsAs:
        await _saveStatistics(saveAs: true);
      case LearnAnywhereMessage.statisticsClear:
        await _clearStatistics();
      case LearnAnywhereMessage.fileExit:
        await _confirmAndExit();
      default:
        _selectRoute(_DesktopRoute.fileOperations);
    }
    // Every File-menu command runs through a modal (a confirm dialog and/or the
    // native file picker) and is launched from the MenuBar, which lives outside
    // the content FocusScope. Re-assert content focus once the command settles
    // so the destination page's F-key/Esc shortcuts are live again — the same
    // defensive guard applied to the language/theme switch.
    if (mounted) {
      _restoreContentFocus();
    }
  }

  /// New deck: replaces the silent mask carry-over (which let two unrelated
  /// decks accidentally share a `maskId`) with an explicit choice between
  /// reusing an existing mask file or minting a brand-new mask identity.
  Future<void> _newDeck() async {
    final bool confirmed = await _confirm(LearnAnywhereMessage.confirmNewDeck);
    if (!confirmed) {
      return;
    }
    if (!await _confirmAndAutoSaveStats()) {
      return;
    }
    final _NewMaskChoice? choice = await _showNewMaskChoiceDialog();
    if (choice == null || choice == _NewMaskChoice.cancel) {
      return;
    }
    if (choice == _NewMaskChoice.loadExisting) {
      final String? path = await _pickOpenPath(
        extension: 'inf',
        typeLabel: LearnAnywhereMessage.filePickerMaskType,
      );
      if (path == null) {
        return;
      }
      await _guardedFileOperation(() async {
        final LearningMask loadedMask = await _fileService.readMask(path);
        _document = await _fileService.newDeck(_document, mask: loadedMask);
        _lastMaskPath = path;
        _resetRangeForDeck();
        _selectRoute(_DesktopRoute.fileOperations);
        _setFileStatus(LearnAnywhereMessage.fileNewDeckDone);
        _setLastDir('inf', path);
        unawaited(_saveSettings());
      });
      return;
    }
    // Create new mask: mint a fresh identity and go straight into the Mask
    // Editor so the user can shape it before saving.
    await _guardedFileOperation(() async {
      final LearningMask freshMask = _defaultMask(widget.locale.languageCode);
      _document = await _fileService.newDeck(_document, mask: freshMask);
      _resetRangeForDeck();
      setState(() {
        _maskEditorMask = freshMask;
        _maskEditorSnapshot = freshMask;
        // Explicitly null (never _lastMaskPath, which is an unrelated file
        // from a previous session — see B8): a brand-new mask must prompt
        // for a save target on close.
        _maskEditorPath = null;
        _maskEditorDirty = false;
        _editorInitialIndex = null;
        _route = _DesktopRoute.maskEditor;
      });
      unawaited(_saveSettings());
    });
  }

  /// Offers a choice between loading an existing mask or minting a new one
  /// for a brand-new deck; returns `null` when the dialog is dismissed.
  Future<_NewMaskChoice?> _showNewMaskChoiceDialog() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return showDialog<_NewMaskChoice>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            messages.message(LearnAnywhereMessage.fileNewMaskChoiceTitle),
          ),
          content: Text(
            messages.message(LearnAnywhereMessage.fileNewMaskChoiceBody),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_NewMaskChoice.cancel),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_NewMaskChoice.loadExisting),
              child: Text(
                messages.message(LearnAnywhereMessage.actionLoadExistingMask),
              ),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () =>
                  Navigator.of(context).pop(_NewMaskChoice.createNew),
              child: Text(
                messages.message(LearnAnywhereMessage.actionCreateNewMask),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDeck() async {
    final String? path = await _pickOpenPath(
      extension: 'vok',
      typeLabel: LearnAnywhereMessage.filePickerDeckType,
    );
    if (path == null) {
      return;
    }
    await _openDeckPath(path);
  }

  /// Opens the deck at [path] directly (no file dialog).
  ///
  /// Shared by File > Open and the clickable last-deck link on the workspace
  /// (N1). Persists [path] as the last-opened deck for that link.
  Future<void> _openDeckPath(String path) async {
    if (!await _confirmAndAutoSaveStats()) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.openDeck(_document, path);
      final LearnAnywhereMessage? maskStatus = await _reconcileLinkedMask();
      _resetRangeForDeck();
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(maskStatus ?? LearnAnywhereMessage.fileOpenDeckDone);
      _setLastDir('vok', path);
      // The last-opened deck path is persisted by _saveSettings via
      // _settings.lastDeckPath (single source of truth).
      unawaited(_saveSettings());
    });
    await _maybeAutoLoadStatistics(path);
  }

  /// Reconciles the just-opened deck's embedded mask cache against its
  /// linked `.inf` file, so an edit made in the Mask Editor since the deck
  /// was last written on disk is picked up on open (rather than the deck
  /// silently keeping a stale schema — see the Batch 12 write-through fix in
  /// [_closeMaskEditor], which this complements for decks that were open
  /// elsewhere, or closed without saving, when the mask changed).
  ///
  /// A different but non-breaking `.inf` is applied to the in-memory deck
  /// silently. A breaking difference is left alone — the deck keeps its own
  /// embedded mask rather than risk dropping data — and reported via the
  /// returned status message. Returns `null` when there is nothing to
  /// reconcile: no linked `.inf`, an unreadable one, or one identical to the
  /// deck's own embedded mask.
  Future<LearnAnywhereMessage?> _reconcileLinkedMask() async {
    final String? deckPath = _document.deckPath;
    if (deckPath == null) {
      return null;
    }
    String? linkedPath;
    try {
      linkedPath = await _fileService.findLinkedMaskPath(
        deckPath,
        _document.mask.maskId,
      );
    } on Object {
      return null;
    }
    if (linkedPath == null) {
      return null;
    }
    final LearningMask linkedMask;
    try {
      linkedMask = await _fileService.readMask(linkedPath);
    } on Object {
      return null;
    }
    if (encodeMaskJson(linkedMask) == encodeMaskJson(_document.mask)) {
      return null;
    }
    final MaskCompatibilityResult compat = checkMaskCompatibility(
      oldMask: _document.mask,
      newMask: linkedMask,
      units: _document.deck.units,
    );
    if (!compat.isCompatible) {
      return LearnAnywhereMessage.fileStatusLinkedMaskConflict;
    }
    setState(() {
      _document = _document.copyWith(
        deck: applyMaskToDeck(_document.deck, linkedMask),
      );
    });
    return LearnAnywhereMessage.fileStatusLinkedMaskAdopted;
  }

  /// After opening a deck, offers to auto-load its most recent timestamped
  /// session `.sta` (§3.7). On acceptance the loaded file becomes and stays the
  /// auto-save target; declining leaves auto-saving to start a fresh session
  /// file on the next session. A no-op when auto-loading is off or no matching
  /// file exists.
  Future<void> _maybeAutoLoadStatistics(String deckPath) async {
    if (!_document.autoLoadStatistics || _document.deckPath != deckPath) {
      return;
    }
    final List<TimestampedStatistics> found;
    try {
      found = await _fileService.findTimestampedStatistics(deckPath);
    } on Object {
      return;
    }
    if (found.isEmpty || !mounted) {
      return;
    }
    final TimestampedStatistics latest = found.first;
    final StatisticsFile file;
    try {
      file = decodeStatisticsJson(await File(latest.path).readAsString());
    } on Object {
      return;
    }
    final StatisticsCoverage coverage = _fileService.statisticsCoverage(
      file,
      _document.deck.units.length,
    );
    if (!mounted) {
      return;
    }
    final bool load = await _confirmLoadAvailableStats(
      latest.timestamp,
      coverage,
    );
    if (!load || !mounted) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = (await _fileService.loadStatistics(_document, latest.path))
          .copyWith(autoSaveTargetPath: latest.path);
      _setLastDir('sta', latest.path);
      _showStatus(LearnAnywhereMessage.statisticsLoaded);
    });
  }

  /// Yes/No prompt offering to load a discovered session `.sta` (§3.7).
  Future<bool> _confirmLoadAvailableStats(
    DateTime when,
    StatisticsCoverage coverage,
  ) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return _confirmYesNo(
      messages: messages,
      body: messages
          .message(LearnAnywhereMessage.confirmLoadAvailableStats)
          .replaceAll('{datetime}', _formatTimestamp(when))
          .replaceAll('{queried}', coverage.queriedUnits.toString())
          .replaceAll('{total}', coverage.totalUnits.toString()),
    );
  }

  /// Shows a Yes/No confirmation with [body] and returns the choice (No when
  /// dismissed). Yes is the default action.
  Future<bool> _confirmYesNo({
    required LearnAnywhereLocalizations messages,
    required String body,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(messages.message(LearnAnywhereMessage.actionNo)),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(messages.message(LearnAnywhereMessage.actionYes)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Formats [when] as a human-readable `YYYY-MM-DD HH:MM:SS` for prompts.
  String _formatTimestamp(DateTime when) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${when.year}-${pad(when.month)}-${pad(when.day)} '
        '${pad(when.hour)}:${pad(when.minute)}:${pad(when.second)}';
  }

  Future<void> _mergeDeck() async {
    final String? path = await _pickOpenPath(
      extension: 'vok',
      typeLabel: LearnAnywhereMessage.filePickerDeckType,
    );
    if (path == null) {
      return;
    }
    if (!await _confirmAndAutoSaveStats()) {
      return;
    }
    final int previousCount = _document.deck.units.length;
    await _guardedFileOperation(() async {
      _document = await _fileService.mergeDeck(_document, path);
      final int newCount = _document.deck.units.length;
      _range = _clampRange(
        autoExpandEndUnit(
          _range,
          previousCount: previousCount,
          newCount: newCount,
        ),
        newCount,
      );
      _learnParameters = _learnParameters.copyWith(
        startIndex: _range.startUnit,
        endIndex: _range.endUnit,
      );
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileMergeDeckDone);
      _setLastDir('vok', path);
    });
  }

  Future<void> _saveDeck({required bool saveAs}) async {
    String? path = saveAs ? null : _document.deckPath;
    if (path == null) {
      path = await _pickSavePath(
        extension: 'vok',
        typeLabel: LearnAnywhereMessage.filePickerDeckType,
        suggestedName: _suggestedName(_document.deckPath, 'learn_anywhere.vok'),
      );
      if (path == null) {
        return;
      }
      path = _ensureExtension(path, 'vok');
    }
    final String resolvedPath = path;
    await _guardedFileOperation(() async {
      _document = await _fileService.saveDeck(_document, path: resolvedPath);
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileSaveDeckDone);
      _setLastDir('vok', resolvedPath);
      unawaited(_saveSettings());
    });
  }

  Future<void> _loadMask() async {
    final bool confirmed = await _confirm(LearnAnywhereMessage.confirmLoadMask);
    if (!confirmed) {
      return;
    }
    final String? path = await _pickOpenPath(
      extension: 'inf',
      typeLabel: LearnAnywhereMessage.filePickerMaskType,
    );
    if (path == null) {
      return;
    }
    if (!await _confirmAndAutoSaveStats()) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.loadMask(_document, path);
      _lastMaskPath = path;
      _resetRangeForDeck();
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileLoadMaskDone);
      _setLastDir('inf', path);
      unawaited(_saveSettings());
    });
  }

  Future<void> _saveMask({bool saveAs = false}) async {
    String? path = saveAs ? null : (_lastMaskPath ?? _settings.lastMaskPath);
    if (path == null) {
      path = await _pickSavePath(
        extension: 'inf',
        typeLabel: LearnAnywhereMessage.filePickerMaskType,
        suggestedName: _suggestedName(
          _lastMaskPath ?? _settings.lastMaskPath,
          'learn_anywhere.inf',
        ),
      );
      if (path == null) {
        return;
      }
    }
    await _guardedFileOperation(() async {
      final String maskPath = _ensureExtension(path!, 'inf');
      await _fileService.saveMask(_document.mask, maskPath);
      _lastMaskPath = maskPath;
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileSaveMaskDone);
      _setLastDir('inf', maskPath);
      unawaited(_saveSettings());
    });
  }

  Future<void> _loadStatistics() async {
    final String? path = await _pickOpenPath(
      extension: 'sta',
      typeLabel: LearnAnywhereMessage.filePickerStatsType,
    );
    if (path == null) {
      return;
    }
    bool loaded = false;
    await _guardedFileOperation(() async {
      _document = await _fileService.loadStatistics(_document, path);
      _setLastDir('sta', path);
      _showStatus(LearnAnywhereMessage.statisticsLoaded);
      loaded = true;
    });
    // A manual load asks whether to adopt the file for auto-saving; declining
    // suspends auto-saving until another `.sta` is loaded or created (§3.7).
    if (!loaded || !mounted) {
      return;
    }
    final bool adopt = await _confirmYesNo(
      messages: LearnAnywhereLocalizations.of(context),
      body: LearnAnywhereLocalizations.of(
        context,
      ).message(LearnAnywhereMessage.confirmAdoptAutoSaveTarget),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _document = adopt
          ? _document.copyWith(autoSaveTargetPath: path)
          : _document.copyWith(clearAutoSaveTarget: true);
    });
  }

  Future<void> _saveStatistics({bool saveAs = false}) async {
    String? path = saveAs ? null : _document.statisticsPath;
    if (path == null) {
      final String? statsDefault = _statisticsDefaultPath();
      path = await _pickSavePath(
        extension: 'sta',
        typeLabel: LearnAnywhereMessage.filePickerStatsType,
        suggestedName: _suggestedName(statsDefault, 'learn_anywhere.sta'),
      );
      if (path == null) {
        return;
      }
    }
    await _guardedFileOperation(() async {
      final String staPath = _ensureExtension(path!, 'sta');
      _document = await _fileService.saveStatistics(_document, staPath);
      // "Save stats as" retargets auto-saving to the chosen file (§3.7).
      if (saveAs) {
        _document = _document.copyWith(autoSaveTargetPath: staPath);
      }
      _setLastDir('sta', staPath);
      _showStatus(LearnAnywhereMessage.statisticsSaved);
    });
  }

  Future<void> _clearStatistics() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
          content: Text(
            messages.message(LearnAnywhereMessage.confirmClearStatistics),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(messages.message(LearnAnywhereMessage.actionClear)),
            ),
          ],
        );
      },
    );
    if (result != true) {
      return;
    }
    setState(() {
      _document = _fileService.clearStatisticsInMemory(_document);
      // Clearing statistics also resets the live session counters so the
      // Attempts/Accuracy pills start from zero again.
      _learnSessionAttempts = 0;
      _learnSessionCorrect = 0;
    });
    _showStatus(LearnAnywhereMessage.statisticsCleared);
  }

  Future<void> _saveSelectedUnits(List<int> unitIndices) async {
    if (unitIndices.isEmpty) {
      _showStatus(LearnAnywhereMessage.statisticsNoSelection);
      return;
    }
    final String? path = await _pickSavePath(
      extension: 'vok',
      typeLabel: LearnAnywhereMessage.filePickerDeckType,
      suggestedName: 'selected_units.vok',
    );
    if (path == null) {
      return;
    }
    final Set<int> selected = unitIndices.toSet();
    final LearningDeck selectedDeck = LearningDeck(
      mask: _document.mask,
      units: <LearningUnit>[
        for (var index = 0; index < _document.deck.units.length; index += 1)
          if (selected.contains(index + 1)) _document.deck.units[index],
      ],
    );
    await _guardedFileOperation(() async {
      final String vokPath = _ensureExtension(path, 'vok');
      await _fileService.saveDeckSnapshot(selectedDeck, vokPath);
      _setLastDir('vok', vokPath);
      _showStatus(LearnAnywhereMessage.statisticsSelectedSaved);
    });
  }

  /// Prompts for a folder and recursively loads its `.vok` decks for a Lexicon
  /// file search (Batch 8, §4.2).
  ///
  /// The picker opens in the last folder used for a file search, falling back
  /// to the last folder a deck was opened from. The chosen folder is persisted
  /// so the next search starts there. Returns null when the user cancels.
  Future<Map<String, LearningDeck>?> _pickLexiconFolderDecks() async {
    final String? initialDir =
        _lastFileSearchDir ?? _lastVokDir ?? _filePicker.initialDirectory(null);
    final String? folder = await _filePicker.pickDirectory(
      initialDirectory: initialDir,
    );
    if (folder == null) {
      return null;
    }
    _lastFileSearchDir = folder;
    widget.prefs.setLastDirFileSearch(folder);
    return _fileService.loadDecksInFolder(folder);
  }

  void _loadFoundLexiconDeck(LearningDeck deck) {
    setState(() {
      _document = _document.copyWith(
        deck: deck,
        statistics: clearStatistics(deck),
        clearDeckPath: true,
        clearStatisticsPath: true,
        clearAutoSaveTarget: true,
      );
      _resetRangeForDeck();
    });
  }

  /// Shared shutdown sequence used by both File→Exit and the title-bar X.
  ///
  /// Confirms the exit, auto-saves statistics (with the overwrite prompt) and
  /// settings, then terminates via `exit(0)`. Cancelling any prompt aborts the
  /// shutdown and leaves the app running.
  ///
  /// `exit(0)` is used rather than `windowManager.destroy()` because destroy()
  /// can hang for ~30s on Windows and end in a crash dump (window_manager issue
  /// #478); exit(0) terminates cleanly. `setPreventClose(true)` in `main` routes
  /// the X through here (via [onWindowClose]).
  Future<void> _confirmAndExit() async {
    final bool confirmed = await _confirm(LearnAnywhereMessage.confirmExit);
    if (!confirmed) return;
    // Auto-save (with overwrite prompt) before leaving; Cancel aborts exit.
    if (!await _confirmAndAutoSaveStats()) {
      return;
    }
    await _guardedFileOperation(() async {
      await _saveSettings();
      exit(0);
    });
  }

  Future<void> _guardedFileOperation(Future<void> Function() operation) async {
    try {
      await operation();
    } on FileOperationException catch (error) {
      // Known file-operation failures carry a catalog id, resolved here so the
      // message is shown in the active UI language.
      if (!mounted) {
        return;
      }
      final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
        context,
      );
      final String text = messages
          .message(error.messageId)
          .replaceAll('{detail}', error.detail ?? '');
      setState(() {
        _lastFileStatus = text;
        _route = _DesktopRoute.fileOperations;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text)));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
        context,
      );
      setState(() {
        _lastFileStatus =
            '${messages.message(LearnAnywhereMessage.fileOperationFailed)}: $error';
        _route = _DesktopRoute.fileOperations;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_lastFileStatus!)));
    }
  }

  Future<bool> _confirm(LearnAnywhereMessage message) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
          content: Text(messages.message(message)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                messages.message(LearnAnywhereMessage.actionContinue),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // --- File dialog helpers (C1) ---------------------------------------------

  /// Returns the initial directory for a dialog of the given [extension] type.
  ///
  /// Uses the last directory saved for that type; falls back to the
  /// user's Documents folder (or home on Linux) on first run.
  String? _initialDirectoryFor(String extension) {
    final String? saved = switch (extension) {
      'vok' => _lastVokDir,
      'sta' => _lastStaDir,
      'inf' => _lastInfDir,
      _ => null,
    };
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    return _filePicker.initialDirectory(null);
  }

  /// Extracts the directory from [path] and persists it for [extension].
  void _setLastDir(String extension, String path) {
    final String dir = _filePicker.directoryOf(path);
    if (dir.isEmpty) {
      return;
    }
    switch (extension) {
      case 'vok':
        _lastVokDir = dir;
        widget.prefs.setLastDirVok(dir);
      case 'sta':
        _lastStaDir = dir;
        widget.prefs.setLastDirSta(dir);
      case 'inf':
        _lastInfDir = dir;
        widget.prefs.setLastDirInf(dir);
    }
  }

  /// Shows the native "Open file" dialog filtered to [extension].
  ///
  /// Opens in the last-used directory for that type, or Documents on first run.
  /// Returns the chosen absolute path, or null when the user cancels.
  Future<String?> _pickOpenPath({
    required String extension,
    required LearnAnywhereMessage typeLabel,
  }) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return _filePicker.openPath(
      extension: extension,
      typeLabel: messages.message(typeLabel),
      initialDirectory: _initialDirectoryFor(extension),
    );
  }

  /// Shows the native "Save file" dialog filtered to [extension], pre-filling
  /// [suggestedName] as the file name.
  ///
  /// Opens in the last-used directory for that type, or Documents on first run.
  /// Returns the chosen absolute path, or null when the user cancels.
  Future<String?> _pickSavePath({
    required String extension,
    required LearnAnywhereMessage typeLabel,
    required String suggestedName,
  }) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return _filePicker.savePath(
      extension: extension,
      typeLabel: messages.message(typeLabel),
      suggestedName: suggestedName,
      initialDirectory: _initialDirectoryFor(extension),
    );
  }

  /// Returns the file name to pre-fill in a save dialog: the name of [path]
  /// when set, otherwise [fallback].
  String _suggestedName(String? path, String fallback) {
    return path == null ? fallback : _filePicker.fileNameOf(path);
  }

  /// Resolves the path suggested in the "Save stats as" dialog: the currently
  /// associated `.sta`, else a fresh timestamped session name in the deck's
  /// folder, else null.
  String? _statisticsDefaultPath() {
    return _document.statisticsPath ??
        (_document.deckPath == null
            ? null
            : _fileService.timestampedStatisticsPath(
                _document.deckPath!,
                DateTime.now(),
              ));
  }

  void _setFileStatus(
    LearnAnywhereMessage message, {
    int count = 0,
    Map<String, String> placeholders = const <String, String>{},
  }) {
    if (!mounted) {
      return;
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    setState(() {
      var text = messages.message(message).replaceAll('{count}', count.toString());
      for (final MapEntry<String, String> entry in placeholders.entries) {
        text = text.replaceAll('{${entry.key}}', entry.value);
      }
      _lastFileStatus = text;
      _route = _DesktopRoute.fileOperations;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_lastFileStatus!)));
  }

  void _showStatus(LearnAnywhereMessage message) {
    if (!mounted) {
      return;
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final String status = messages.message(message);
    setState(() => _lastFileStatus = status);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
  }
}

String _ensureExtension(String path, String extension) {
  final String normalizedExtension = '.$extension';
  return path.toLowerCase().endsWith(normalizedExtension)
      ? path
      : '$path$normalizedExtension';
}

LearningMask _defaultMask(String localeCode) {
  // A mask created in this app mints a fresh app maskId (see [mintNewMaskId]).
  // Category id 0 and field ids 0..2 follow the 0-based, array-order scheme.
  // The seed names are user data, localized once from the active UI language.
  String seed(LearnAnywhereMessage message) =>
      LearnAnywhereCatalog.message(message, localeCode);
  return LearningMask(
    maskId: mintNewMaskId(),
    name: seed(LearnAnywhereMessage.defaultMaskName),
    direction1Label: seed(LearnAnywhereMessage.defaultDirection1Label),
    direction2Label: seed(LearnAnywhereMessage.defaultDirection2Label),
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 0,
        name: seed(LearnAnywhereMessage.defaultCategoryName).replaceAll(
          '{n}',
          '1',
        ),
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: seed(LearnAnywhereMessage.defaultFieldQuestion),
            length: defaultFieldLength,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: seed(LearnAnywhereMessage.defaultFieldAnswer),
            length: defaultFieldLength,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            id: 2,
            name: seed(LearnAnywhereMessage.defaultFieldRemark),
            length: defaultFieldLength,
            equalGroup: 0,
            role1: FieldRole.remark,
            role2: FieldRole.remark,
          ),
        ],
      ),
    ],
  );
}

final class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.document,
    required this.onOpenLastDeck,
    this.lastDeckPath,
    this.lastMaskPath,
  });

  final DesktopDocument document;
  final String? lastDeckPath;
  final String? lastMaskPath;

  /// Loads the given deck path directly (no file dialog).
  final Future<void> Function(String path) onOpenLastDeck;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages =
        LearnAnywhereLocalizations.of(context);
    final bool hasContent =
        document.deckPath != null || document.deck.units.isNotEmpty;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              messages.message(LearnAnywhereMessage.desktopHomeTitle),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            if (!hasContent) ...<Widget>[
              Text(messages.message(LearnAnywhereMessage.homeNoFileLoaded)),
              if (lastDeckPath != null)
                _LastDeckLink(
                  label: messages.message(LearnAnywhereMessage.homeLastDeck),
                  path: lastDeckPath!,
                  onOpen: onOpenLastDeck,
                ),
              if (lastMaskPath != null)
                _StatusLine(
                  label: messages.message(LearnAnywhereMessage.homeLastMask),
                  value: lastMaskPath!,
                ),
            ] else ...<Widget>[
              _StatusLine(
                label: messages.message(LearnAnywhereMessage.fileStatusDeck),
                value: document.deckPath ??
                    messages.message(LearnAnywhereMessage.fileStatusUnsaved),
              ),
              _StatusLine(
                label: messages.message(LearnAnywhereMessage.homeMaskName),
                value: document.mask.name,
              ),
              _StatusLine(
                label: messages.message(LearnAnywhereMessage.fileStatusUnits),
                value: document.deck.units.length.toString(),
              ),
              _HomeStatsSummary(
                unitCount: document.deck.units.length,
                statistics: document.statistics,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _HomeStatsSummary extends StatelessWidget {
  const _HomeStatsSummary({
    required this.unitCount,
    required this.statistics,
  });

  final int unitCount;
  final List<UnitStats> statistics;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages =
        LearnAnywhereLocalizations.of(context);
    if (unitCount == 0) return const SizedBox.shrink();
    final StatisticsSummary summary = aggregateStatistics(
      unitCount: unitCount,
      statistics: statistics,
    );
    final int mastered = summary.buckets
        .where(
          (BucketSummary b) =>
              b.bucket == HitRateBucket.perfect ||
              b.bucket == HitRateBucket.good,
        )
        .fold(0, (int sum, BucketSummary b) => sum + b.count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _StatusLine(
          label:
              messages.message(LearnAnywhereMessage.statisticsQueriedUnits),
          value: summary.queriedUnits.toString(),
        ),
        _StatusLine(
          label: messages.message(LearnAnywhereMessage.learnLiveMastered),
          value: mastered.toString(),
        ),
      ],
    );
  }
}

final class _MenuSeparator extends StatelessWidget {
  const _MenuSeparator();

  @override
  Widget build(BuildContext context) {
    // `outlineVariant` all but disappears against the dark blue theme's menu
    // surface (that theme sets outline == outlineVariant), so it opts into a
    // brighter color via LearnAnywhereMenuTheme; every other theme falls back
    // to the shared outlineVariant role unchanged.
    final Color color =
        Theme.of(context).extension<LearnAnywhereMenuTheme>()?.separatorColor ??
        Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, thickness: 1, color: color),
    );
  }
}

final class _FileOperationsStatus extends StatelessWidget {
  const _FileOperationsStatus({required this.document, required this.status});

  final DesktopDocument document;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final String unsaved = messages.message(
      LearnAnywhereMessage.fileStatusUnsaved,
    );
    return Padding(
      padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.routeFileOperationsTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          _StatusLine(
            label: messages.message(LearnAnywhereMessage.fileStatusDeck),
            value: document.deckPath ?? unsaved,
          ),
          _StatusLine(
            label: messages.message(LearnAnywhereMessage.fileStatusStats),
            value: document.statisticsPath ?? unsaved,
          ),
          _StatusLine(
            label: messages.message(LearnAnywhereMessage.fileStatusUnits),
            value: document.deck.units.length.toString(),
          ),
          if (status != null) ...<Widget>[
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Text(status!),
          ],
        ],
      ),
    );
  }
}

/// Clickable "Last deck: <name>" link on the workspace (N1).
///
/// Loads the stored deck directly on tap. When the file no longer exists the
/// link is muted and a tap shows a "File not found" snackbar instead.
final class _LastDeckLink extends StatelessWidget {
  const _LastDeckLink({
    required this.label,
    required this.path,
    required this.onOpen,
  });

  final String label;
  final String path;
  final Future<void> Function(String path) onOpen;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool exists = File(path).existsSync();
    final String fileName = _fileNameOf(path);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle linkStyle = TextStyle(
      color: exists ? colors.primary : colors.onSurfaceVariant,
      decoration: exists ? TextDecoration.underline : TextDecoration.none,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapSmall),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('$label: '),
          Tooltip(
            message: path,
            child: InkWell(
              onTap: () {
                if (exists) {
                  unawaited(onOpen(path));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        messages
                            .message(LearnAnywhereMessage.fileNotFound)
                            .replaceAll('{path}', path),
                      ),
                    ),
                  );
                }
              },
              child: Text(fileName, style: linkStyle),
            ),
          ),
        ],
      ),
    );
  }

  String _fileNameOf(String value) {
    final int slash = value.lastIndexOf('/');
    final int backslash = value.lastIndexOf(r'\');
    final int separator = slash > backslash ? slash : backslash;
    return separator < 0 ? value : value.substring(separator + 1);
  }
}

final class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapSmall),
      child: Text('$label: $value'),
    );
  }
}

/// Intent fired by the global ESC shortcut to return to the home screen.
/// Screens with their own inner Shortcuts (UnitEditor, LearnSession) take
/// priority, so this only fires for screens that have no ESC handler.
final class _GoHomeIntent extends Intent {
  const _GoHomeIntent();
}

/// User choice from the File→New mask dialog (B1).
enum _NewMaskChoice { loadExisting, createNew, cancel }
