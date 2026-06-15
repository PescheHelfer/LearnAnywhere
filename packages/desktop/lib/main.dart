import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
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
      title: 'Learn Anywhere',
      theme: LearnAnywhereTheme.light(),
      darkTheme: LearnAnywhereTheme.dark(),
      home: const _DesktopHome(),
    );
  }
}

final class _DesktopHome extends StatelessWidget {
  const _DesktopHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn Anywhere')),
      body: const Center(child: Text('Desktop shell ready: $corePackageName')),
    );
  }
}
