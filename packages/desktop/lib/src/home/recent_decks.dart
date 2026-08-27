/// Recently opened decks, listed as one-click links on the workspace.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Trailing mark that says an entry is a link rather than a status line
/// (U+29C9 TWO JOINED SQUARES).
const String _linkGlyph = '⧉';

/// "Recent decks" heading with one [RecentDeckLink] per entry.
///
/// Renders nothing when [paths] is empty. The list is shown whether or not a
/// deck is loaded — switching decks is exactly the moment it is wanted — so the
/// caller passes it already stripped of the open deck (see
/// [recentDecksExcluding]).
final class RecentDecksList extends StatelessWidget {
  /// Creates the workspace's recent-deck list.
  const RecentDecksList({
    super.key,
    required this.paths,
    required this.onOpen,
  });

  /// Deck paths to offer, newest first.
  final List<String> paths;

  /// Loads the given deck path directly (no file dialog).
  final Future<void> Function(String path) onOpen;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
      return const SizedBox.shrink();
    }
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${messages.message(LearnAnywhereMessage.homeRecentDecks)}:'),
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
        for (final String path in paths)
          Padding(
            padding: const EdgeInsets.only(left: LearnAnywhereTokens.gapMedium),
            child: RecentDeckLink(path: path, onOpen: onOpen),
          ),
      ],
    );
  }
}

/// Clickable deck link on the workspace (N1).
///
/// Loads the deck directly on tap. A deck whose file has moved stays listed
/// rather than being pruned — a missing entry would hide a moved folder — so it
/// is shown muted and a tap reports "File not found" naming the path instead.
///
/// Existence is checked synchronously in `build`, as the single last-deck link
/// this replaces always did, so an entry that reappears is live again on the
/// next rebuild without any cache to invalidate. The cost is one `stat` per
/// listed deck per rebuild; at three entries on local paths that is
/// negligible, but a listed deck on an unreachable network share pays that
/// share's timeout on the UI thread.
final class RecentDeckLink extends StatelessWidget {
  /// Creates a link to the deck at [path].
  const RecentDeckLink({
    super.key,
    required this.path,
    required this.onOpen,
  });

  /// Full path of the deck this link opens.
  final String path;

  /// Loads the given deck path directly (no file dialog).
  final Future<void> Function(String path) onOpen;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool exists = File(path).existsSync();
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
              // The folder and the file name, parsed with the host's path
              // rules (so a Linux file name containing a backslash is not
              // split on it). The name alone rarely says which language a
              // deck is; its folder usually does. The full path is on the
              // tooltip.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(DeckPaths.folderAndFileName(path), style: linkStyle),
                  const SizedBox(width: LearnAnywhereTokens.gapSmall),
                  Text(_linkGlyph, style: TextStyle(color: linkStyle.color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
