/// Recently opened decks, listed as one-click links on the workspace.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../file_operations/desktop_file_service.dart';

/// Trailing mark that says an entry is a link rather than a status line
/// (U+29C9 TWO JOINED SQUARES).
const String _linkGlyph = '⧉';

/// Looks up a deck's last-edited and last-learned dates.
typedef DeckDatesLookup = Future<DeckDates> Function(String path);

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
    required this.datesOf,
  });

  /// Deck paths to offer, newest first.
  final List<String> paths;

  /// Loads the given deck path directly (no file dialog).
  final Future<void> Function(String path) onOpen;

  /// Looks up each entry's dates; see [RecentDeckLink.datesOf].
  final DeckDatesLookup datesOf;

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
            child: RecentDeckLink(
              path: path,
              onOpen: onOpen,
              datesOf: datesOf,
            ),
          ),
      ],
    );
  }
}

/// Clickable deck link on the workspace (N1), with the deck's dates under it.
///
/// Loads the deck directly on tap. A deck whose file has moved stays listed
/// rather than being pruned — a missing entry would hide a moved folder — so it
/// is shown muted, without dates, and a tap reports "File not found" naming the
/// path instead.
///
/// Existence is checked synchronously in `build`, as the single last-deck link
/// this replaces always did, so an entry that reappears is live again on the
/// next rebuild without any cache to invalidate. The cost is one `stat` per
/// listed deck per rebuild; at three entries on local paths that is
/// negligible, but a listed deck on an unreachable network share pays that
/// share's timeout on the UI thread.
final class RecentDeckLink extends StatefulWidget {
  /// Creates a link to the deck at [path].
  const RecentDeckLink({
    super.key,
    required this.path,
    required this.onOpen,
    required this.datesOf,
  });

  /// Full path of the deck this link opens.
  final String path;

  /// Loads the given deck path directly (no file dialog).
  final Future<void> Function(String path) onOpen;

  /// Looks up when the deck was last edited and last learned.
  ///
  /// Asked once per path, not on every rebuild as existence is: the
  /// last-edited date means reading the whole deck file, and neither date
  /// changes while the workspace is on screen — editing or learning happens on
  /// other screens, and coming back builds the list afresh.
  final DeckDatesLookup datesOf;

  @override
  State<RecentDeckLink> createState() => _RecentDeckLinkState();
}

final class _RecentDeckLinkState extends State<RecentDeckLink> {
  late Future<DeckDates> _dates;

  @override
  void initState() {
    super.initState();
    _dates = widget.datesOf(widget.path);
  }

  @override
  void didUpdateWidget(RecentDeckLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _dates = widget.datesOf(widget.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final String path = widget.path;
    final bool exists = File(path).existsSync();
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle linkStyle = TextStyle(
      color: exists ? colors.primary : colors.onSurfaceVariant,
      decoration: exists ? TextDecoration.underline : TextDecoration.none,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: LearnAnywhereTokens.gapSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Tooltip(
                message: path,
                child: InkWell(
                  onTap: () {
                    if (exists) {
                      unawaited(widget.onOpen(path));
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
                      Text(
                        DeckPaths.folderAndFileName(path),
                        style: linkStyle,
                      ),
                      const SizedBox(width: LearnAnywhereTokens.gapSmall),
                      Text(
                        _linkGlyph,
                        style: TextStyle(color: linkStyle.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // A deck that is gone has no dates worth showing: the muted link
          // already says what matters.
          if (exists)
            FutureBuilder<DeckDates>(
              future: _dates,
              builder: (BuildContext context, AsyncSnapshot<DeckDates> dates) {
                final DeckDates? value = dates.data;
                if (value == null) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _describeDates(value, messages),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// One line naming both dates, each read on this machine's clock, or saying
/// that the deck has no record of it.
String _describeDates(DeckDates dates, LearnAnywhereLocalizations messages) {
  final LocalTimestamp? edited = dates.lastEdited;
  final DateTime? learned = dates.lastLearned;
  final String editedText = edited == null
      ? messages.message(LearnAnywhereMessage.homeRecentDeckNotRecorded)
      : _formatMinute(edited.toLocal());
  final String learnedText = learned == null
      ? messages.message(LearnAnywhereMessage.homeRecentDeckNotLearned)
      : _formatMinute(learned.toLocal());
  return messages
      .message(LearnAnywhereMessage.homeRecentDeckDates)
      .replaceAll('{edited}', editedText)
      .replaceAll('{learned}', learnedText);
}

/// Formats [when] as `YYYY-MM-DD HH:MM`: the minute is precise enough to tell
/// this morning from last night, and the seconds would only be noise here.
String _formatMinute(DateTime when) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${when.year}-${two(when.month)}-${two(when.day)} '
      '${two(when.hour)}:${two(when.minute)}';
}
