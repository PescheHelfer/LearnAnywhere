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

  @override
  void initState() {
    super.initState();
    _settingsPath = _fileService.settingsFilePath();
    _range = resetUnitRange(_document.deck.units.length);
    _queryOptions = _optionsFromSettings(_settings);
    _learnParameters = _parametersFromSettings(_settings);
    // Load per-type dialog directories from shared_preferences (C1).
    _lastVokDir = widget.prefs.lastDirVok;
    _lastStaDir = widget.prefs.lastDirSta;
    _lastInfDir = widget.prefs.lastDirInf;
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
    _menuScrollController.dispose();
    _contentFocusScope.dispose();
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

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
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
          _commandItem(messages, LearnAnywhereMessage.statisticsLoad),
          _commandItem(messages, LearnAnywhereMessage.statisticsSave),
          _commandItem(messages, LearnAnywhereMessage.fileSaveStatsAs),
          _commandItem(messages, LearnAnywhereMessage.statisticsClear),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileExit),
        ],
        child: MenuAcceleratorLabel(
          messages.message(LearnAnywhereMessage.menuFile),
          builder: menuAcceleratorBuilder,
        ),
      ),
      // 2. Edit (absorbs Mask Editor)
      SubmenuButton(
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
            onPressed: () => _selectRoute(_DesktopRoute.maskEditor),
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.menuMaskEditor),
              builder: menuAcceleratorBuilder,
            ),
          ),
        ],
        child: MenuAcceleratorLabel(
          messages.message(LearnAnywhereMessage.menuEdit),
          builder: menuAcceleratorBuilder,
        ),
      ),
      // 3. Learn (direct — opens practice setup)
      _routeMenu(messages, LearnAnywhereMessage.menuLearn, _DesktopRoute.learn),
      // 4. Statistics (direct)
      _routeMenu(messages, LearnAnywhereMessage.menuStatistics, _DesktopRoute.statistics),
      // 5. Lexicon (direct)
      _routeMenu(messages, LearnAnywhereMessage.menuLexicon, _DesktopRoute.lexicon),
      // 6. Options (new)
      SubmenuButton(
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
                child: Text(messages.message(LearnAnywhereMessage.themeSystem)),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.light,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: Text(messages.message(LearnAnywhereMessage.themeLight)),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.dark,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: Text(messages.message(LearnAnywhereMessage.themeDark)),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.darkBlue,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: Text(messages.message(LearnAnywhereMessage.themeDarkBlue)),
              ),
              RadioMenuButton<_AppTheme>(
                value: _AppTheme.lightBlue,
                groupValue: widget.appTheme,
                onChanged: (_AppTheme? v) {
                  if (v != null) widget.onAppThemeChanged(v);
                },
                child: Text(messages.message(LearnAnywhereMessage.themeLightBlue)),
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
                child: Text(messages.message(LearnAnywhereMessage.languageEnglish)),
              ),
              RadioMenuButton<Locale>(
                value: const Locale('de'),
                groupValue: widget.locale,
                onChanged: (Locale? v) {
                  if (v != null) widget.onLocaleChanged(v);
                },
                child: Text(messages.message(LearnAnywhereMessage.languageGerman)),
              ),
            ],
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.languageLabel),
              builder: menuAcceleratorBuilder,
            ),
          ),
          const _MenuSeparator(),
          CheckboxMenuButton(
            value: false,
            onChanged: null,
            child: Text(
              messages.message(LearnAnywhereMessage.menuOptionsAutoLoadStats),
            ),
          ),
          CheckboxMenuButton(
            value: false,
            onChanged: null,
            child: Text(
              messages.message(LearnAnywhereMessage.menuOptionsAutoSaveStats),
            ),
          ),
        ],
        child: MenuAcceleratorLabel(
          messages.message(LearnAnywhereMessage.menuOptions),
          builder: menuAcceleratorBuilder,
        ),
      ),
      // 7. Help
      SubmenuButton(
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.about),
            child: MenuAcceleratorLabel(
              messages.message(LearnAnywhereMessage.helpAbout),
              builder: menuAcceleratorBuilder,
            ),
          ),
        ],
        child: MenuAcceleratorLabel(
          messages.message(LearnAnywhereMessage.menuHelp),
          builder: menuAcceleratorBuilder,
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
  ) {
    return MenuItemButton(
      onPressed: () => _selectRoute(route),
      child: MenuAcceleratorLabel(messages.message(message), builder: menuAcceleratorBuilder),
    );
  }

  void _selectRoute(_DesktopRoute route) {
    setState(() {
      _editorInitialIndex = null;
      _route = route;
    });
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
        lastDeckPath: _settings.lastDeckPath,
        lastMaskPath: _lastMaskPath ?? _settings.lastMaskPath,
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
        mask: _document.mask,
        onChanged: (LearningMask value) {
          final LearningDeck deck = LearningDeck(
            mask: value,
            units: _document.deck.units,
          );
          setState(() => _document = _document.copyWith(deck: deck));
        },
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
      ),
      _DesktopRoute.lexicon => LexiconPage(
        deck: _document.deck,
        textOptions: TextMatchOptions(
          caseSensitive: _queryOptions.caseSensitive,
          accentSensitive: _queryOptions.accentSensitive,
        ),
        loadDecksByPattern: _fileService.loadDecksByPattern,
        onLoadFoundDeck: _loadFoundLexiconDeck,
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
    await _guardedFileOperation(() async {
      _document = await _fileService.openDeck(_document, path);
      _resetRangeForDeck();
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileOpenDeckDone);
      _setLastDir('vok', path);
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
    await _guardedFileOperation(() async {
      await _fileService.autoSaveStatistics(_document);
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
  return const LearningMask(
    name: 'Untitled mask',
    direction1Label: 'Direction 1',
    direction2Label: 'Direction 2',
    categories: <CategoryDefinition>[
      CategoryDefinition(
        id: 1,
        name: 'Category 1',
        fields: <FieldDefinition>[
          FieldDefinition(
            name: 'Question',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.question,
            role2: FieldRole.answer,
          ),
          FieldDefinition(
            name: 'Answer',
            length: 40,
            equalGroup: 0,
            role1: FieldRole.answer,
            role2: FieldRole.question,
          ),
          FieldDefinition(
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
    this.lastDeckPath,
    this.lastMaskPath,
  });

  final DesktopDocument document;
  final String? lastDeckPath;
  final String? lastMaskPath;

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
                _StatusLine(
                  label: messages.message(LearnAnywhereMessage.homeLastDeck),
                  value: lastDeckPath!,
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
