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
import 'src/preferences/desktop_prefs.dart';
import 'src/statistics/statistics_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
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
  list,
  about,
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

final class _DesktopHomeState extends State<_DesktopHome> {
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
  DesktopDocument _document = DesktopDocument.empty(_defaultMask());
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
  // Per-type last-used dialog directories (C1).
  String? _lastVokDir;
  String? _lastStaDir;
  String? _lastInfDir;
  int _learnSessionAttempts = 0;
  int _learnSessionCorrect = 0;
  String? _lastFileStatus;
  int? _editorInitialIndex;
  int? _editorLastIndex;
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
  final MenuController _optionsMenuController = MenuController();
  final MenuController _helpMenuController = MenuController();

  // The three direct-action top-level entries (Learn/Statistics/Lexicon) are bare
  // MenuItemButtons. Without [skipTraversal] the MenuBar's Left/Right arrow
  // navigation lands on them and stalls (they have no submenu to open); skipping
  // them lets arrow nav jump straight to the next submenu-bearing menu. They are
  // still activated via their Alt accelerator and the mouse.
  final FocusNode _learnMenuFocusNode = FocusNode(
    skipTraversal: true,
    debugLabel: 'menuLearn',
  );
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
    HardwareKeyboard.instance.addHandler(_handleMenuAccelerator);
    _settingsPath = _fileService.settingsFilePath();
    _range = resetUnitRange(_document.deck.units.length);
    _queryOptions = _optionsFromSettings(_settings);
    _learnParameters = _parametersFromSettings(_settings);
    // Load per-type dialog directories from shared_preferences (C1).
    _lastVokDir = widget.prefs.lastDirVok;
    _lastStaDir = widget.prefs.lastDirSta;
    _lastInfDir = widget.prefs.lastDirInf;
    // Apply persisted auto-load/auto-save statistics toggles (C11); both
    // default OFF on first run.
    _document = _document.copyWith(
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
    HardwareKeyboard.instance.removeHandler(_handleMenuAccelerator);
    _menuScrollController.dispose();
    _contentFocusScope.dispose();
    _learnMenuFocusNode.dispose();
    _statisticsMenuFocusNode.dispose();
    _lexiconMenuFocusNode.dispose();
    super.dispose();
  }

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
      if (mounted) {
        _contentFocusScope.requestFocus();
      }
    });
  }

  // --- Settings persistence -------------------------------------------------

  DesktopQueryOptions _optionsFromSettings(LearnAnywhereSettings settings) {
    return DesktopQueryOptions(
      wrongInputCorrectable: settings.wrongInputCorrectable,
      completeInputRequired: settings.completeInputRequired,
      caseSensitive: settings.caseSensitive,
      accentSensitive: settings.accentSensitive,
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
      superStatusThreshold: settings.superStatusThreshold,
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
      superStatusThreshold: _learnParameters.superStatusThreshold,
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

  /// Auto-saves statistics before an action that would drop the current units
  /// from memory (open/new/merge/clear/exit). Returns `false` when the user
  /// cancels the overwrite prompt, in which case the caller must abort.
  Future<bool> _confirmAndAutoSaveStats() async {
    final DesktopDocument doc = _document;
    if (!doc.autoSaveStatistics || doc.deck.units.isEmpty) {
      return true;
    }
    String? target = doc.statisticsPath;
    if (target == null) {
      // No manual save this session: derive the path from the deck file.
      if (doc.deckPath == null) {
        return true; // Nothing to derive a path from; skip silently.
      }
      target = _fileService.statisticsSidecarPath(doc.deckPath!);
      if (await File(target).exists()) {
        final _OverwriteChoice choice = await _confirmOverwriteStats(target);
        switch (choice) {
          case _OverwriteChoice.cancel:
            return false;
          case _OverwriteChoice.no:
            return true; // Proceed without saving.
          case _OverwriteChoice.yes:
            break;
        }
      }
    }
    final String resolved = target;
    await _guardedFileOperation(() async {
      _document = await _fileService.saveStatistics(doc, resolved);
    });
    return true;
  }

  /// Yes/No/Cancel prompt shown before overwriting an existing `.sta` sidecar.
  Future<_OverwriteChoice> _confirmOverwriteStats(String path) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final String name = _filePicker.fileNameOf(path);
    final _OverwriteChoice? result = await showDialog<_OverwriteChoice>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.confirmTitle)),
          content: Text(
            messages
                .message(LearnAnywhereMessage.confirmAutoSaveOverwrite)
                .replaceAll('{name}', name),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_OverwriteChoice.cancel),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_OverwriteChoice.no),
              child: Text(messages.message(LearnAnywhereMessage.actionNo)),
            ),
            FilledButton(
              autofocus: true,
              onPressed: () => Navigator.of(context).pop(_OverwriteChoice.yes),
              child: Text(messages.message(LearnAnywhereMessage.actionYes)),
            ),
          ],
        );
      },
    );
    return result ?? _OverwriteChoice.cancel;
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
          (
            LearnAnywhereMessage.menuLearn,
            () => _selectRoute(_DesktopRoute.learn),
          ),
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
          // Load/Save/Save-as share the Statistics screen's handlers (C12);
          // Clear stats stays on the Statistics screen only.
          _commandItem(messages, LearnAnywhereMessage.statisticsLoad),
          _commandItem(messages, LearnAnywhereMessage.statisticsSave),
          _commandItem(messages, LearnAnywhereMessage.fileSaveStatsAs),
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
        ],
        child: MenuAcceleratorDisplayLabel(
          messages.message(LearnAnywhereMessage.menuEdit),
        ),
      ),
      // 3. Learn (direct — opens practice setup)
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuLearn,
        _DesktopRoute.learn,
        _learnMenuFocusNode,
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
          CheckboxMenuButton(
            value: _document.autoLoadStatistics,
            onChanged: (bool? value) => _setAutoLoadStats(value ?? false),
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuOptionsAutoLoadStats),
              builder: menuAcceleratorBuilder,
            ),
          ),
          CheckboxMenuButton(
            value: _document.autoSaveStatistics,
            onChanged: (bool? value) => _setAutoSaveStats(value ?? false),
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuOptionsAutoSaveStats),
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
    FocusNode focusNode,
  ) {
    return MenuItemButton(
      onPressed: () => _selectRoute(route),
      // Skip-traversal node so arrow navigation jumps over this submenu-less entry.
      focusNode: focusNode,
      // Top-level direct action: display-only label; activation is handled by
      // [_handleMenuAccelerator] so it doesn't collide with open-submenu items.
      child: MenuAcceleratorDisplayLabel(messages.message(message)),
    );
  }

  void _selectRoute(_DesktopRoute route) {
    setState(() {
      _editorInitialIndex = null;
      _route = route;
    });
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
      setState(() {
        _maskEditorMask = _document.mask;
        _maskEditorPath = _lastMaskPath;
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
        _maskEditorPath = infPath;
        _maskEditorDirty = false;
        _editorInitialIndex = null;
        _route = _DesktopRoute.maskEditor;
      });
    });
  }

  /// Saves the edited `.inf` (bumping its revision) when it has changed, then
  /// returns home. An unedited session leaves the file untouched.
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
    final LearningMask saved = mask.copyWith(revision: mask.revision + 1);
    await _guardedFileOperation(() async {
      await _fileService.saveMask(saved, infPath);
      _lastMaskPath = infPath;
      _setLastDir('inf', infPath);
      _clearMaskEditorState();
      _setFileStatus(LearnAnywhereMessage.fileStatusMaskSaved);
      unawaited(_saveSettings());
    });
  }

  void _clearMaskEditorState() {
    _maskEditorMask = null;
    _maskEditorPath = null;
    _maskEditorDirty = false;
  }

  Future<void> _openEditorSearch() async {
    if (_document.deck.units.isEmpty) return;
    final int? index = await UnitEditorPage.openSearchDialog(
      context,
      _document.deck,
    );
    if (index != null && mounted) {
      setState(() {
        _editorInitialIndex = index;
        _route = _DesktopRoute.editor;
      });
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
        _editorInitialIndex = index;
        _route = _DesktopRoute.editor;
      });
    }
  }

  Widget _contentForRoute() {
    return switch (_route) {
      _DesktopRoute.home => _HomeScreen(
        document: _document,
        lastDeckPath: widget.prefs.lastPathOpenDeck ?? _settings.lastDeckPath,
        lastMaskPath: _lastMaskPath ?? _settings.lastMaskPath,
        onOpenLastDeck: _openDeckPath,
      ),
      _DesktopRoute.fileOperations => _FileOperationsStatus(
        document: _document,
        status: _lastFileStatus,
      ),
      _DesktopRoute.editor => UnitEditorPage(
        deck: _document.deck,
        initialIndex: _editorInitialIndex ?? _editorLastIndex,
        onChanged: _updateDeckFromEditor,
        onDone: () => _selectRoute(_DesktopRoute.home),
        onCancel: () => _selectRoute(_DesktopRoute.home),
        onCurrentIndexChanged: (int index) {
          _editorLastIndex = index;
        },
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
      ),
      _DesktopRoute.learn => LearnSessionPage(
        deck: _document.deck,
        statistics: _document.statistics,
        options: _queryOptions,
        parameters: _learnParameters,
        sessionAttempts: _learnSessionAttempts,
        sessionCorrect: _learnSessionCorrect,
        onParametersChanged: (SessionParameters value) {
          setState(() => _learnParameters = value);
          unawaited(_saveSettings());
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
        onChanged: (DesktopQueryOptions value) {
          setState(() => _queryOptions = value);
          unawaited(_saveSettings());
        },
        onClose: () => _selectRoute(_DesktopRoute.home),
      ),
      _DesktopRoute.statistics => StatisticsPage(
        deck: _document.deck,
        statistics: _document.statistics,
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
        loadDecksByPattern: _fileService.loadDecksByPattern,
        onLoadFoundDeck: _loadFoundLexiconDeck,
        onClose: () => _selectRoute(_DesktopRoute.home),
      ),
      _DesktopRoute.about => AboutPage(
        onClose: () => _selectRoute(_DesktopRoute.home),
      ),
      _ => _RoutePlaceholder(route: _route),
    };
  }

  void _updateDeckFromEditor(LearningDeck deck) {
    final int previousCount = _document.deck.units.length;
    final int newCount = deck.units.length;
    final List<UnitStats> statistics = newCount == previousCount
        ? _document.statistics
        : clearStatistics(deck);
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
      case LearnAnywhereMessage.fileClearUnits:
        await _clearUnits();
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
        await _exit();
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

  Future<void> _newDeck() async {
    final bool confirmed = await _confirm(LearnAnywhereMessage.confirmNewDeck);
    if (!confirmed) {
      return;
    }
    if (!await _confirmAndAutoSaveStats()) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.newDeck(_document);
      _resetRangeForDeck();
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileNewDeckDone);
      unawaited(_saveSettings());
    });
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
      _resetRangeForDeck();
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileOpenDeckDone);
      _setLastDir('vok', path);
      widget.prefs.setLastPathOpenDeck(path);
      unawaited(_saveSettings());
    });
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

  Future<void> _clearUnits() async {
    final bool confirmed = await _confirm(
      LearnAnywhereMessage.confirmClearUnits,
    );
    if (!confirmed) {
      return;
    }
    if (!await _confirmAndAutoSaveStats()) {
      return;
    }
    setState(() {
      _document = _fileService.clearUnits(_document);
      _resetRangeForDeck();
      _route = _DesktopRoute.fileOperations;
    });
    _setFileStatus(LearnAnywhereMessage.fileClearUnitsDone);
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
    await _guardedFileOperation(() async {
      _document = await _fileService.loadStatistics(_document, path);
      _setLastDir('sta', path);
      _showStatus(LearnAnywhereMessage.statisticsLoaded);
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

  void _loadFoundLexiconDeck(LearningDeck deck) {
    setState(() {
      _document = _document.copyWith(
        deck: deck,
        statistics: clearStatistics(deck),
        clearDeckPath: true,
        clearStatisticsPath: true,
      );
      _resetRangeForDeck();
    });
  }

  // B1: Use exit(0) so the process actually terminates on Windows/Linux.
  Future<void> _exit() async {
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

  /// Resolves the conventional path used as the statistics save/load default:
  /// the loaded `.sta` file, else the deck's sidecar, else null.
  String? _statisticsDefaultPath() {
    return _document.statisticsPath ??
        (_document.deckPath == null
            ? null
            : _fileService.statisticsSidecarPath(_document.deckPath!));
  }

  void _setFileStatus(LearnAnywhereMessage message) {
    if (!mounted) {
      return;
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    setState(() {
      _lastFileStatus = messages.message(message);
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

LearningMask _defaultMask() {
  // A mask created in this app mints a fresh app maskId (see [mintNewMaskId]).
  // Category id 0 and field ids 0..2 follow the 0-based, array-order scheme.
  return LearningMask(
    maskId: mintNewMaskId(),
    name: 'Untitled mask',
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: const <CategoryDefinition>[
      CategoryDefinition(
        id: 0,
        name: 'Category 1',
        fields: <FieldDefinition>[
          FieldDefinition(
            id: 0,
            name: 'Question',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            id: 1,
            name: 'Answer',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
            id: 2,
            name: 'Remark',
            length: 40,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

final class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder({required this.route});

  final _DesktopRoute route;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final _RouteCopy copy = _copyFor(messages);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(copy.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(copy.body),
            ),
          ],
        ),
      ),
    );
  }

  _RouteCopy _copyFor(LearnAnywhereLocalizations messages) {
    return switch (route) {
      _DesktopRoute.home => _RouteCopy(
        messages.message(LearnAnywhereMessage.desktopHomeTitle),
        messages.message(LearnAnywhereMessage.desktopHomeBody),
      ),
      _DesktopRoute.fileOperations => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeFileOperationsTitle),
        messages.message(LearnAnywhereMessage.routeFileOperationsBody),
      ),
      _DesktopRoute.editor => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeEditorTitle),
        messages.message(LearnAnywhereMessage.routeEditorBody),
      ),
      _DesktopRoute.maskEditor => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeMaskEditorTitle),
        messages.message(LearnAnywhereMessage.routeMaskEditorBody),
      ),
      _DesktopRoute.learn => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeLearnTitle),
        messages.message(LearnAnywhereMessage.routeLearnBody),
      ),
      _DesktopRoute.queryOptions => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeQueryOptionsTitle),
        messages.message(LearnAnywhereMessage.routeQueryOptionsBody),
      ),
      _DesktopRoute.statistics => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeStatisticsTitle),
        messages.message(LearnAnywhereMessage.routeStatisticsBody),
      ),
      _DesktopRoute.lexicon => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeLexiconTitle),
        messages.message(LearnAnywhereMessage.routeLexiconBody),
      ),
      _DesktopRoute.list => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeListTitle),
        messages.message(LearnAnywhereMessage.routeListBody),
      ),
      _DesktopRoute.about => _RouteCopy(
        messages.message(LearnAnywhereMessage.routeAboutTitle),
        messages.message(LearnAnywhereMessage.routeAboutBody),
      ),
    };
  }
}

final class _RouteCopy {
  const _RouteCopy(this.title, this.body);

  final String title;
  final String body;
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

/// User choice from the auto-save overwrite prompt (C11).
enum _OverwriteChoice { yes, no, cancel }
