import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'src/about/about_page.dart';
import 'src/editor/unit_editor_page.dart';
import 'src/file_operations/desktop_document.dart';
import 'src/file_operations/desktop_file_service.dart';
import 'src/learn/desktop_query_options.dart';
import 'src/learn/learn_session_page.dart';
import 'src/learn/query_options_page.dart';
import 'src/lexicon/lexicon_page.dart';
import 'src/mask_editor/mask_editor_page.dart';
import 'src/statistics/statistics_page.dart';

void main() {
  runApp(const LearnAnywhereDesktopApp());
}

/// Desktop shell for Learn Anywhere.
final class LearnAnywhereDesktopApp extends StatefulWidget {
  /// Creates the desktop shell.
  const LearnAnywhereDesktopApp({super.key});

  @override
  State<LearnAnywhereDesktopApp> createState() =>
      _LearnAnywhereDesktopAppState();
}

final class _LearnAnywhereDesktopAppState
    extends State<LearnAnywhereDesktopApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          LearnAnywhereLocalizations.of(context).appTitle,
      theme: LearnAnywhereTheme.light(),
      darkTheme: LearnAnywhereTheme.dark(),
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      home: _DesktopHome(
        themeMode: _themeMode,
        locale: _locale,
        onThemeModeChanged: (ThemeMode value) {
          setState(() => _themeMode = value);
        },
        onLocaleChanged: (Locale value) {
          setState(() => _locale = value);
        },
      ),
    );
  }
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
    required this.themeMode,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<_DesktopHome> createState() => _DesktopHomeState();
}

final class _DesktopHomeState extends State<_DesktopHome> {
  final DesktopFileService _fileService = const DesktopFileService();
  final ScrollController _menuScrollController = ScrollController();
  final MenuController _fileMenuController = MenuController();
  final MenuController _editMenuController = MenuController();
  final MenuController _learnMenuController = MenuController();
  final MenuController _helpMenuController = MenuController();
  _DesktopRoute _route = _DesktopRoute.home;
  DesktopDocument _document = DesktopDocument.empty(_defaultMask());
  DesktopQueryOptions _queryOptions = const DesktopQueryOptions();
  SessionParameters _learnParameters = const SessionParameters();
  int _learnSessionAttempts = 0;
  int _learnSessionCorrect = 0;
  String? _lastFileStatus;
  int? _editorInitialIndex;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _menuScrollController.dispose();
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;
    if (_isModifierKey(event.logicalKey)) return false;
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    final bool altPressed = HardwareKeyboard.instance.isAltPressed;
    if (altPressed) {
      return _handleAltMnemonic(event.logicalKey);
    }
    if (_fileMenuController.isOpen) {
      return _handleFileMenuMnemonic(event.character);
    }
    if (_editMenuController.isOpen) {
      return _handleEditMenuMnemonic(event.character);
    }
    if (_learnMenuController.isOpen) {
      return _handleLearnMenuMnemonic(event.character);
    }
    if (_helpMenuController.isOpen) {
      return _handleHelpMenuMnemonic(event.character);
    }
    return false;
  }

  static bool _isModifierKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  bool _handleAltMnemonic(LogicalKeyboardKey key) {
    final bool german = widget.locale.languageCode == 'de';
    if (key == (german ? LogicalKeyboardKey.keyD : LogicalKeyboardKey.keyF)) {
      _fileMenuController.open();
      return true;
    }
    if (key == LogicalKeyboardKey.keyE) {
      _editMenuController.open();
      return true;
    }
    if (key == LogicalKeyboardKey.keyM) {
      _selectRoute(_DesktopRoute.maskEditor);
      return true;
    }
    if (key == LogicalKeyboardKey.keyL) {
      _learnMenuController.open();
      return true;
    }
    if (key == LogicalKeyboardKey.keyS) {
      _selectRoute(_DesktopRoute.statistics);
      return true;
    }
    if (key == LogicalKeyboardKey.keyX) {
      _selectRoute(_DesktopRoute.lexicon);
      return true;
    }
    if (key == LogicalKeyboardKey.keyI) {
      _selectRoute(_DesktopRoute.list);
      return true;
    }
    if (key == LogicalKeyboardKey.keyH) {
      _helpMenuController.open();
      return true;
    }
    return false;
  }

  bool _handleFileMenuMnemonic(String? character) {
    if (character == null) return false;
    final bool german = widget.locale.languageCode == 'de';
    final String ch = character.toLowerCase();
    final Map<String, LearnAnywhereMessage> mapping = german
        ? const <String, LearnAnywhereMessage>{
            'n': LearnAnywhereMessage.fileNewDeck,
            'l': LearnAnywhereMessage.fileOpenDeck,
            'h': LearnAnywhereMessage.fileAddMergeDeck,
            's': LearnAnywhereMessage.fileSave,
            'u': LearnAnywhereMessage.fileSaveAs,
            'i': LearnAnywhereMessage.fileClearUnits,
            'm': LearnAnywhereMessage.fileLoadMask,
            'd': LearnAnywhereMessage.fileSaveMask,
            'b': LearnAnywhereMessage.fileExit,
          }
        : const <String, LearnAnywhereMessage>{
            'n': LearnAnywhereMessage.fileNewDeck,
            'o': LearnAnywhereMessage.fileOpenDeck,
            'a': LearnAnywhereMessage.fileAddMergeDeck,
            's': LearnAnywhereMessage.fileSave,
            'v': LearnAnywhereMessage.fileSaveAs,
            'c': LearnAnywhereMessage.fileClearUnits,
            'l': LearnAnywhereMessage.fileLoadMask,
            'm': LearnAnywhereMessage.fileSaveMask,
            'e': LearnAnywhereMessage.fileExit,
          };
    final LearnAnywhereMessage? command = mapping[ch];
    if (command != null) {
      _runFileCommand(command);
      return true;
    }
    return false;
  }

  bool _handleEditMenuMnemonic(String? character) {
    if (character == null) return false;
    final bool german = widget.locale.languageCode == 'de';
    final String ch = character.toLowerCase();
    _editMenuController.close();
    if (ch == (german ? 'e' : 'u')) {
      _selectRoute(_DesktopRoute.editor);
      return true;
    }
    if (ch == 's') {
      _openEditorSearch();
      return true;
    }
    if (ch == (german ? 'n' : 'j')) {
      _openEditorJump();
      return true;
    }
    return false;
  }

  bool _handleLearnMenuMnemonic(String? character) {
    if (character == null) return false;
    final bool german = widget.locale.languageCode == 'de';
    final String ch = character.toLowerCase();
    if (!german) {
      if (ch == 'p') {
        _learnMenuController.close();
        _selectRoute(_DesktopRoute.learn);
        return true;
      }
      if (ch == 'a') {
        _learnMenuController.close();
        _selectRoute(_DesktopRoute.queryOptions);
        return true;
      }
    } else {
      if (ch == 'ü') {
        _learnMenuController.close();
        _selectRoute(_DesktopRoute.learn);
        return true;
      }
      if (ch == 'e') {
        _learnMenuController.close();
        _selectRoute(_DesktopRoute.queryOptions);
        return true;
      }
    }
    return false;
  }

  bool _handleHelpMenuMnemonic(String? character) {
    if (character == null) return false;
    final bool german = widget.locale.languageCode == 'de';
    final String ch = character.toLowerCase();
    if (ch == (german ? 'p' : 'a')) {
      _helpMenuController.close();
      _selectRoute(_DesktopRoute.about);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.appTitle),
        actions: <Widget>[
          Text(messages.message(LearnAnywhereMessage.themeLabel)),
          const SizedBox(width: LearnAnywhereTokens.gapSmall),
          _ThemeModeMenu(
            themeMode: widget.themeMode,
            onChanged: widget.onThemeModeChanged,
          ),
          const SizedBox(width: LearnAnywhereTokens.gapSmall),
          Text(messages.message(LearnAnywhereMessage.languageLabel)),
          const SizedBox(width: LearnAnywhereTokens.gapSmall),
          _LanguageMenu(
            locale: widget.locale,
            onChanged: widget.onLocaleChanged,
          ),
          const SizedBox(width: LearnAnywhereTokens.gapMedium),
        ],
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
          Expanded(child: _contentForRoute()),
          _HintBar(text: messages.message(LearnAnywhereMessage.desktopHintBar)),
        ],
      ),
    );
  }

  List<Widget> _menuChildren(LearnAnywhereLocalizations messages) {
    final bool german = widget.locale.languageCode == 'de';
    return <Widget>[
      SubmenuButton(
        controller: _fileMenuController,
        menuChildren: <Widget>[
          _commandItem(messages, LearnAnywhereMessage.fileNewDeck,
              englishMnemonic: 'N', germanMnemonic: 'N'),
          _commandItem(messages, LearnAnywhereMessage.fileOpenDeck,
              englishMnemonic: 'O', germanMnemonic: 'L'),
          _commandItem(messages, LearnAnywhereMessage.fileAddMergeDeck,
              englishMnemonic: 'A', germanMnemonic: 'H'),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileSave,
              englishMnemonic: 'S', germanMnemonic: 'S'),
          _commandItem(messages, LearnAnywhereMessage.fileSaveAs,
              englishMnemonic: 'V', germanMnemonic: 'U'),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileClearUnits,
              englishMnemonic: 'C', germanMnemonic: 'I'),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileLoadMask,
              englishMnemonic: 'L', germanMnemonic: 'M'),
          _commandItem(messages, LearnAnywhereMessage.fileSaveMask,
              englishMnemonic: 'M', germanMnemonic: 'D'),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileExit,
              englishMnemonic: 'E', germanMnemonic: 'B'),
        ],
        child: _MnemonicText(
          label: messages.message(LearnAnywhereMessage.menuFile),
          mnemonic: german ? 'D' : 'F',
        ),
      ),
      SubmenuButton(
        controller: _editMenuController,
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.editor),
            child: _MnemonicText(
              label: messages.message(LearnAnywhereMessage.menuEditUnitEditor),
              mnemonic: german ? 'E' : 'U',
            ),
          ),
          MenuItemButton(
            onPressed: _openEditorSearch,
            child: _MnemonicText(
              label: messages.message(LearnAnywhereMessage.menuEditSearchUnit),
              mnemonic: 'S',
            ),
          ),
          MenuItemButton(
            onPressed: _openEditorJump,
            child: _MnemonicText(
              label:
                  messages.message(LearnAnywhereMessage.menuEditJumpToNumber),
              mnemonic: german ? 'N' : 'J',
            ),
          ),
        ],
        child: _MnemonicText(
          label: messages.message(LearnAnywhereMessage.menuEdit),
          mnemonic: 'E',
        ),
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuMaskEditor,
        _DesktopRoute.maskEditor,
        englishMnemonic: 'M',
        germanMnemonic: 'M',
      ),
      SubmenuButton(
        controller: _learnMenuController,
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.learn),
            child: _MnemonicText(
              label: messages.message(LearnAnywhereMessage.menuLearnPractice),
              mnemonic: german ? 'Ü' : 'P',
            ),
          ),
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.queryOptions),
            child: _MnemonicText(
              label: messages
                  .message(LearnAnywhereMessage.menuLearnAdvancedOptions),
              mnemonic: german ? 'E' : 'A',
            ),
          ),
        ],
        child: _MnemonicText(
          label: messages.message(LearnAnywhereMessage.menuLearn),
          mnemonic: 'L',
        ),
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuStatistics,
        _DesktopRoute.statistics,
        englishMnemonic: 'S',
        germanMnemonic: 'S',
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuLexicon,
        _DesktopRoute.lexicon,
        englishMnemonic: 'X',
        germanMnemonic: 'X',
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuList,
        _DesktopRoute.list,
        englishMnemonic: 'I',
        germanMnemonic: 'I',
      ),
      SubmenuButton(
        controller: _helpMenuController,
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.about),
            child: _MnemonicText(
              label: messages.message(LearnAnywhereMessage.helpAbout),
              mnemonic: german ? 'P' : 'A',
            ),
          ),
        ],
        child: _MnemonicText(
          label: messages.message(LearnAnywhereMessage.menuHelp),
          mnemonic: 'H',
        ),
      ),
    ];
  }

  MenuItemButton _commandItem(
    LearnAnywhereLocalizations messages,
    LearnAnywhereMessage message, {
    String? englishMnemonic,
    String? germanMnemonic,
  }) {
    final String? mnemonic = englishMnemonic == null
        ? null
        : _mnemonicFor(
            context,
            english: englishMnemonic,
            german: germanMnemonic ?? englishMnemonic,
          );
    return MenuItemButton(
      onPressed: () => _runFileCommand(message),
      child: mnemonic != null
          ? _MnemonicText(label: messages.message(message), mnemonic: mnemonic)
          : Text(messages.message(message)),
    );
  }

  MenuItemButton _routeMenu(
    LearnAnywhereLocalizations messages,
    LearnAnywhereMessage message,
    _DesktopRoute route, {
    required String englishMnemonic,
    required String germanMnemonic,
  }) {
    return MenuItemButton(
      onPressed: () => _selectRoute(route),
      child: _MnemonicText(
        label: messages.message(message),
        mnemonic: _mnemonicFor(
          context,
          english: englishMnemonic,
          german: germanMnemonic,
        ),
      ),
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
      _DesktopRoute.home => _HomeScreen(document: _document),
      _DesktopRoute.fileOperations => _FileOperationsStatus(
        document: _document,
        status: _lastFileStatus,
      ),
      _DesktopRoute.editor => UnitEditorPage(
        deck: _document.deck,
        initialIndex: _editorInitialIndex,
        onChanged: _updateDeckFromEditor,
        onDone: () => _selectRoute(_DesktopRoute.home),
        onCancel: () => _selectRoute(_DesktopRoute.home),
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
        },
      ),
      _DesktopRoute.statistics => StatisticsPage(
        deck: _document.deck,
        statistics: _document.statistics,
        onLoadStatistics: _loadStatistics,
        onSaveStatistics: _saveStatistics,
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
      _DesktopRoute.about => const AboutPage(),
      _ => _RoutePlaceholder(route: _route),
    };
  }

  void _updateDeckFromEditor(LearningDeck deck) {
    final List<UnitStats> statistics =
        deck.units.length == _document.deck.units.length
        ? _document.statistics
        : clearStatistics(deck);
    setState(() {
      _document = _document.copyWith(deck: deck, statistics: statistics);
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
      case LearnAnywhereMessage.fileExit:
        await _exit();
      default:
        _selectRoute(_DesktopRoute.fileOperations);
    }
  }

  Future<void> _newDeck() async {
    final bool confirmed = await _confirm(LearnAnywhereMessage.confirmNewDeck);
    if (!confirmed) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.newDeck(_document);
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileNewDeckDone);
    });
  }

  Future<void> _openDeck() async {
    final String? path = await _askPath(
      suggestedPath: _document.deckPath ?? 'learn_anywhere.vok',
    );
    if (path == null) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.openDeck(_document, path);
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileOpenDeckDone);
    });
  }

  Future<void> _mergeDeck() async {
    final String? path = await _askPath(suggestedPath: 'merge.vok');
    if (path == null) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.mergeDeck(_document, path);
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileMergeDeckDone);
    });
  }

  Future<void> _saveDeck({required bool saveAs}) async {
    String? path = saveAs ? null : _document.deckPath;
    if (path == null) {
      path = await _askPath(
        suggestedPath: _document.deckPath ?? 'learn_anywhere.vok',
      );
      if (path == null) {
        return;
      }
      path = _ensureExtension(path, 'vok');
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.saveDeck(_document, path: path);
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileSaveDeckDone);
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
      _route = _DesktopRoute.fileOperations;
    });
    _setFileStatus(LearnAnywhereMessage.fileClearUnitsDone);
  }

  Future<void> _loadMask() async {
    final bool confirmed = await _confirm(LearnAnywhereMessage.confirmLoadMask);
    if (!confirmed) {
      return;
    }
    final String? path = await _askPath(suggestedPath: 'learn_anywhere.inf');
    if (path == null) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.loadMask(_document, path);
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileLoadMaskDone);
    });
  }

  Future<void> _saveMask() async {
    final String? path = await _askPath(suggestedPath: 'learn_anywhere.inf');
    if (path == null) {
      return;
    }
    await _guardedFileOperation(() async {
      await _fileService.saveMask(
        _document.mask,
        _ensureExtension(path, 'inf'),
      );
      _selectRoute(_DesktopRoute.fileOperations);
      _setFileStatus(LearnAnywhereMessage.fileSaveMaskDone);
    });
  }

  Future<void> _loadStatistics() async {
    final String? path = await _askPath(
      suggestedPath:
          _document.statisticsPath ??
          (_document.deckPath == null
              ? 'learn_anywhere.sta'
              : _fileService.statisticsSidecarPath(_document.deckPath!)),
    );
    if (path == null) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.loadStatistics(_document, path);
      _showStatus(LearnAnywhereMessage.statisticsLoaded);
    });
  }

  Future<void> _saveStatistics() async {
    final String? path = await _askPath(
      suggestedPath:
          _document.statisticsPath ??
          (_document.deckPath == null
              ? 'learn_anywhere.sta'
              : _fileService.statisticsSidecarPath(_document.deckPath!)),
    );
    if (path == null) {
      return;
    }
    await _guardedFileOperation(() async {
      _document = await _fileService.saveStatistics(
        _document,
        _ensureExtension(path, 'sta'),
      );
      _showStatus(LearnAnywhereMessage.statisticsSaved);
    });
  }

  Future<void> _clearStatistics() async {
    final bool confirmed = await _confirm(LearnAnywhereMessage.statisticsClear);
    if (!confirmed) {
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
    final String? path = await _askPath(suggestedPath: 'selected_units.vok');
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
      await _fileService.saveDeckSnapshot(
        selectedDeck,
        _ensureExtension(path, 'vok'),
      );
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
    });
  }

  Future<void> _exit() async {
    await _guardedFileOperation(() async {
      await _fileService.autoSaveStatistics(_document);
      _setFileStatus(LearnAnywhereMessage.fileExitRequested);
      await SystemNavigator.pop();
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

  Future<String?> _askPath({required String suggestedPath}) async {
    final TextEditingController controller = TextEditingController(
      text: suggestedPath,
    );
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(messages.message(LearnAnywhereMessage.fileStatusDeck)),
          content: TextField(
            autofocus: true,
            controller: controller,
            decoration: InputDecoration(
              labelText: messages.message(LearnAnywhereMessage.fileStatusDeck),
            ),
            onSubmitted: (String value) {
              Navigator.of(context).pop(value.trim());
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(
                messages.message(LearnAnywhereMessage.actionContinue),
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty) {
      return null;
    }
    return result;
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
  const _HomeScreen({required this.document});

  final DesktopDocument document;

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
            if (!hasContent)
              Text(messages.message(LearnAnywhereMessage.homeNoFileLoaded))
            else ...<Widget>[
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

final class _HintBar extends StatelessWidget {
  const _HintBar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LearnAnywhereTokens.gapMedium,
          vertical: LearnAnywhereTokens.gapSmall,
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamilyFallback: LearnAnywhereTokens.monospaceFallback,
          ),
        ),
      ),
    );
  }
}

final class _ThemeModeMenu extends StatelessWidget {
  const _ThemeModeMenu({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return DropdownButtonHideUnderline(
      child: DropdownButton<ThemeMode>(
        value: themeMode,
        items: <DropdownMenuItem<ThemeMode>>[
          DropdownMenuItem<ThemeMode>(
            value: ThemeMode.system,
            child: Text(messages.message(LearnAnywhereMessage.themeSystem)),
          ),
          DropdownMenuItem<ThemeMode>(
            value: ThemeMode.light,
            child: Text(messages.message(LearnAnywhereMessage.themeLight)),
          ),
          DropdownMenuItem<ThemeMode>(
            value: ThemeMode.dark,
            child: Text(messages.message(LearnAnywhereMessage.themeDark)),
          ),
        ],
        onChanged: (ThemeMode? value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

final class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.locale, required this.onChanged});

  final Locale locale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: locale,
        items: <DropdownMenuItem<Locale>>[
          DropdownMenuItem<Locale>(
            value: const Locale('en'),
            child: Text(messages.message(LearnAnywhereMessage.languageEnglish)),
          ),
          DropdownMenuItem<Locale>(
            value: const Locale('de'),
            child: Text(messages.message(LearnAnywhereMessage.languageGerman)),
          ),
        ],
        onChanged: (Locale? value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

final class _MnemonicText extends StatelessWidget {
  const _MnemonicText({required this.label, required this.mnemonic});

  final String label;
  final String mnemonic;

  @override
  Widget build(BuildContext context) {
    final int index = label.toLowerCase().indexOf(mnemonic.toLowerCase());
    if (index < 0) {
      return Text(label);
    }
    final TextStyle? style = DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: label.substring(0, index)),
          TextSpan(
            text: label.substring(index, index + 1),
            style: style?.copyWith(decoration: TextDecoration.underline),
          ),
          TextSpan(text: label.substring(index + 1)),
        ],
      ),
    );
  }
}

String _mnemonicFor(
  BuildContext context, {
  required String english,
  required String german,
}) {
  final String languageCode = LearnAnywhereLocalizations.of(
    context,
  ).locale.languageCode;
  return languageCode == 'de' ? german : english;
}
