import 'package:flutter/material.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  runApp(const LearnAnywhereDesktopApp());
}

/// Desktop shell for Learn Anywhere.
final class LearnAnywhereDesktopApp extends StatelessWidget {
  /// Creates the desktop shell.
  const LearnAnywhereDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          LearnAnywhereLocalizations.of(context).appTitle,
      theme: LearnAnywhereTheme.light(),
      darkTheme: LearnAnywhereTheme.dark(),
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      home: const _DesktopHome(),
    );
  }
}

final class _DesktopHome extends StatelessWidget {
  const _DesktopHome();

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Scaffold(
      appBar: AppBar(title: Text(messages.appTitle)),
      body: Center(child: Text(messages.desktopShellReady)),
    );
  }
}
