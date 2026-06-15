import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'src/mask_editor/mask_editor_page.dart';

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
  _DesktopRoute _route = _DesktopRoute.home;
  LearningMask _mask = _defaultMask();

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: MenuBar(children: _menuChildren(messages)),
            ),
          ),
          Expanded(child: _contentForRoute()),
          _HintBar(text: messages.message(LearnAnywhereMessage.desktopHintBar)),
        ],
      ),
    );
  }

  List<Widget> _menuChildren(LearnAnywhereLocalizations messages) {
    return <Widget>[
      SubmenuButton(
        menuChildren: <Widget>[
          _commandItem(messages, LearnAnywhereMessage.fileNewDeck),
          _commandItem(messages, LearnAnywhereMessage.fileOpenDeck),
          _commandItem(messages, LearnAnywhereMessage.fileAddMergeDeck),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileSave),
          _commandItem(messages, LearnAnywhereMessage.fileSaveAs),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileClearUnits),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileLoadMask),
          _commandItem(messages, LearnAnywhereMessage.fileSaveMask),
          const _MenuSeparator(),
          _commandItem(messages, LearnAnywhereMessage.fileExit),
        ],
        child: _MnemonicText(
          label: messages.message(LearnAnywhereMessage.menuFile),
          mnemonic: _mnemonicFor(context, english: 'F', german: 'D'),
        ),
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuEdit,
        _DesktopRoute.editor,
        englishMnemonic: 'E',
        germanMnemonic: 'E',
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuMaskEditor,
        _DesktopRoute.maskEditor,
        englishMnemonic: 'M',
        germanMnemonic: 'M',
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuLearn,
        _DesktopRoute.learn,
        englishMnemonic: 'L',
        germanMnemonic: 'L',
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuQueryOptions,
        _DesktopRoute.queryOptions,
        englishMnemonic: 'Q',
        germanMnemonic: 'A',
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
        germanMnemonic: 'L',
      ),
      _routeMenu(
        messages,
        LearnAnywhereMessage.menuList,
        _DesktopRoute.list,
        englishMnemonic: 'I',
        germanMnemonic: 'I',
      ),
      SubmenuButton(
        menuChildren: <Widget>[
          MenuItemButton(
            onPressed: () => _selectRoute(_DesktopRoute.about),
            child: Text(messages.message(LearnAnywhereMessage.helpAbout)),
          ),
        ],
        child: _MnemonicText(
          label: messages.message(LearnAnywhereMessage.menuHelp),
          mnemonic: _mnemonicFor(context, english: 'H', german: 'H'),
        ),
      ),
    ];
  }

  MenuItemButton _commandItem(
    LearnAnywhereLocalizations messages,
    LearnAnywhereMessage message,
  ) {
    return MenuItemButton(
      onPressed: () => _selectRoute(_DesktopRoute.fileOperations),
      child: Text(messages.message(message)),
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
    setState(() => _route = route);
  }

  Widget _contentForRoute() {
    return switch (_route) {
      _DesktopRoute.maskEditor => MaskEditorPage(
        mask: _mask,
        onChanged: (LearningMask value) {
          setState(() => _mask = value);
        },
      ),
      _ => _RoutePlaceholder(route: _route),
    };
  }
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
