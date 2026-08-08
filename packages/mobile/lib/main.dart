import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/mobile_app_scope.dart';
import 'src/mobile_app_theme.dart';
import 'src/mobile_file_service.dart';
import 'src/mobile_prefs.dart';
import 'src/settings/mobile_settings_screen.dart';
import 'src/setup/mobile_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
  runApp(LearnAnywhereMobileApp(prefs: MobilePrefs(sharedPrefs)));
}

/// Android companion app for read-only Learn Anywhere practice.
final class LearnAnywhereMobileApp extends StatefulWidget {
  /// Creates the Android companion app.
  const LearnAnywhereMobileApp({required this.prefs, this.fileService, super.key});

  /// Preferences store for theme and language.
  final MobilePrefs prefs;

  /// File service used to manage the library and persist statistics.
  final MobileFileService? fileService;

  @override
  State<LearnAnywhereMobileApp> createState() => _LearnAnywhereMobileAppState();
}

final class _LearnAnywhereMobileAppState extends State<LearnAnywhereMobileApp> {
  late final MobileFileService _fileService;
  late MobileAppTheme _theme;
  late Locale _locale;
  LearnAnywhereSettings _settings = const LearnAnywhereSettings();

  @override
  void initState() {
    super.initState();
    _fileService = widget.fileService ?? MobileFileService();
    _theme = mobileAppThemeFromName(widget.prefs.theme);
    _locale = _localeFromPrefs(widget.prefs);
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final LearnAnywhereSettings loaded = await _fileService.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() => _settings = loaded);
  }

  void _onThemeChanged(MobileAppTheme value) {
    setState(() => _theme = value);
  }

  void _onLocaleChanged(Locale value) {
    setState(() => _locale = value);
  }

  void _onSettingsChanged(LearnAnywhereSettings value) {
    setState(() => _settings = value);
  }

  @override
  Widget build(BuildContext context) {
    // MobileAppScope wraps MaterialApp (not the other way around) so that
    // every route the Navigator pushes — including the cached `home` route —
    // sits below it in the element tree and can read live theme/locale/
    // settings via MobileAppScope.of(context), instead of the frozen
    // constructor snapshot a routed screen would otherwise be stuck with.
    return MobileAppScope(
      theme: _theme,
      locale: _locale,
      settings: _settings,
      onThemeChanged: _onThemeChanged,
      onLocaleChanged: _onLocaleChanged,
      onSettingsChanged: _onSettingsChanged,
      child: MaterialApp(
        onGenerateTitle: (BuildContext context) =>
            LearnAnywhereLocalizations.of(context).appTitle,
        theme: mobileLightThemeData(_theme),
        darkTheme: mobileDarkThemeData(_theme),
        themeMode: mobileThemeMode(_theme),
        locale: _locale,
        supportedLocales: LearnAnywhereLocalizations.supportedLocales,
        localizationsDelegates:
            LearnAnywhereLocalizations.localizationsDelegates,
        home: MobileLibraryScreen(
          fileService: _fileService,
          prefs: widget.prefs,
        ),
      ),
    );
  }
}

Locale _localeFromPrefs(MobilePrefs prefs) {
  final String? code = prefs.locale;
  if (code != null && code.isNotEmpty) {
    return Locale(code);
  }
  return const Locale('en');
}

/// Library home screen: lists decks, and imports, opens or deletes them.
final class MobileLibraryScreen extends StatefulWidget {
  /// Creates the library screen.
  const MobileLibraryScreen({
    required this.fileService,
    required this.prefs,
    super.key,
  });

  /// File service used to list, import, open and delete decks.
  final MobileFileService fileService;

  /// Preferences store for theme and language.
  final MobilePrefs prefs;

  @override
  State<MobileLibraryScreen> createState() => _MobileLibraryScreenState();
}

final class _MobileLibraryScreenState extends State<MobileLibraryScreen> {
  List<LibraryDeckEntry>? _entries;
  String? _status;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final List<LibraryDeckEntry> entries = await widget.fileService
        .listDecks();
    if (!mounted) {
      return;
    }
    setState(() => _entries = entries);
  }

  Future<void> _import() async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    try {
      final int count = await widget.fileService.importDecks();
      if (count == 0) {
        return;
      }
      await _refresh();
      if (!mounted) {
        return;
      }
      setState(() {
        _status = messages
            .message(LearnAnywhereMessage.mobileImportSuccess)
            .replaceAll('{count}', count.toString());
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = messages.message(LearnAnywhereMessage.mobileImportFailed);
      });
    }
  }

  Future<void> _open(LibraryDeckEntry entry) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    try {
      final MobileDeckDocument document = await widget.fileService.openDeck(
        entry.path,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => MobileSetupScreen(
            document: document,
            fileService: widget.fileService,
          ),
        ),
      );
      await _refresh();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = messages.message(LearnAnywhereMessage.mobileDeckLoadFailed);
      });
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MobileSettingsScreen(
          prefs: widget.prefs,
          fileService: widget.fileService,
        ),
      ),
    );
  }

  Future<void> _delete(LibraryDeckEntry entry) async {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              messages.message(
                LearnAnywhereMessage.mobileDeleteDeckConfirmTitle,
              ),
            ),
            content: Text(
              messages.message(
                LearnAnywhereMessage.mobileDeleteDeckConfirmBody,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  messages.message(LearnAnywhereMessage.mobileDeleteDeck),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await widget.fileService.deleteDeck(entry.path);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final List<LibraryDeckEntry>? entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.message(LearnAnywhereMessage.mobileLibraryTitle)),
        actions: <Widget>[
          IconButton(
            tooltip: messages.message(LearnAnywhereMessage.mobileImportDecks),
            onPressed: _import,
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            tooltip: messages.message(LearnAnywhereMessage.mobileSettingsTitle),
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: entries == null
            ? const Center(child: CircularProgressIndicator())
            : entries.isEmpty
            ? _LibraryEmptyState(status: _status, onImport: _import)
            : _LibraryList(
                entries: entries,
                status: _status,
                onOpen: _open,
                onDelete: _delete,
              ),
      ),
    );
  }
}

final class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.onImport, this.status});

  final VoidCallback onImport;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.school_outlined, size: 56),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Text(
              messages.message(LearnAnywhereMessage.mobileLibraryEmptyTitle),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapSmall),
            Text(
              messages.message(LearnAnywhereMessage.mobileLibraryEmptyBody),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(
                messages.message(LearnAnywhereMessage.mobileImportDecks),
              ),
            ),
            if (status != null) ...<Widget>[
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              Text(status!),
            ],
          ],
        ),
      ),
    );
  }
}

final class _LibraryList extends StatelessWidget {
  const _LibraryList({
    required this.entries,
    required this.onOpen,
    required this.onDelete,
    this.status,
  });

  final List<LibraryDeckEntry> entries;
  final ValueChanged<LibraryDeckEntry> onOpen;
  final ValueChanged<LibraryDeckEntry> onDelete;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Column(
      children: <Widget>[
        if (status != null)
          Padding(
            padding: const EdgeInsets.all(LearnAnywhereTokens.gapSmall),
            child: Text(status!, style: Theme.of(context).textTheme.bodySmall),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              final LibraryDeckEntry entry = entries[index];
              return ListTile(
                leading: const Icon(Icons.school_outlined),
                title: Text(entry.name),
                subtitle: Text(
                  '${messages.message(LearnAnywhereMessage.mobileUnits)}: '
                  '${entry.unitCount}',
                ),
                onTap: () => onOpen(entry),
                trailing: IconButton(
                  tooltip: messages.message(
                    LearnAnywhereMessage.mobileDeleteDeck,
                  ),
                  onPressed: () => onDelete(entry),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
