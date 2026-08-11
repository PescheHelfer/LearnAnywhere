import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// The one guide chapter the phone shows.
///
/// The rest of the bundled guide describes menus, function keys, the editors
/// and Level Learning — none of which exist here — so the companion opens
/// [HelpViewer] in single-chapter mode rather than offering a contents list of
/// chapters about a program the reader is not running.
const String kMobileHelpChapter = '14-android-companion.md';

/// Shows the Android chapter of the bundled user guide.
///
/// The chapter follows the app's language setting, because [HelpViewer] reads
/// the ambient locale and the language folders hold identical file names.
final class MobileHelpScreen extends StatelessWidget {
  /// Creates the help screen.
  const MobileHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.message(LearnAnywhereMessage.routeHelpTitle)),
      ),
      body: const SafeArea(
        child: HelpViewer(singleChapterFileName: kMobileHelpChapter),
      ),
    );
  }
}
