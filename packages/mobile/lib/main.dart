import 'package:flutter/material.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

void main() {
  runApp(const LearnAnywhereMobileApp());
}

/// Android companion shell for Learn Anywhere.
final class LearnAnywhereMobileApp extends StatelessWidget {
  /// Creates the Android companion shell.
  const LearnAnywhereMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          LearnAnywhereLocalizations.of(context).appTitle,
      theme: LearnAnywhereTheme.light(),
      darkTheme: LearnAnywhereTheme.dark(),
      supportedLocales: LearnAnywhereLocalizations.supportedLocales,
      localizationsDelegates: LearnAnywhereLocalizations.localizationsDelegates,
      home: const _MobileHome(),
    );
  }
}

final class _MobileHome extends StatelessWidget {
  const _MobileHome();

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Scaffold(
      appBar: AppBar(title: Text(messages.appTitle)),
      body: Center(child: Text(messages.mobileShellReady)),
    );
  }
}
