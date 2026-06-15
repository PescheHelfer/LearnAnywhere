import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
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
      title: 'Learn Anywhere',
      theme: LearnAnywhereTheme.light(),
      darkTheme: LearnAnywhereTheme.dark(),
      home: const _MobileHome(),
    );
  }
}

final class _MobileHome extends StatelessWidget {
  const _MobileHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn Anywhere')),
      body: const Center(child: Text('Mobile shell ready: $corePackageName')),
    );
  }
}
