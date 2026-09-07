import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';
import 'package:path/path.dart' as p;

import '../file_operations/desktop_file_service.dart';

/// Applies the reference mask to [paths], returning one result per path.
typedef MaskSyncApplyCallback =
    Future<List<MaskWriteResult>> Function(List<String> paths);

/// Re-reads the same folder against the same reference, returning fresh
/// entries.
typedef MaskSyncRescanCallback = Future<List<MaskSyncEntry>> Function();

/// Review dialog for tier-2 cross-directory mask sync (Step 7).
///
/// Lists every `.inf`/`.vok` copy of the mask found under the chosen folder
/// with its status and lets the user select which updatable copies to apply.
/// Only [MaskSyncStatus.willUpdate] copies are selectable; up-to-date,
/// would-break, and same-revision "differs" copies are shown for information
/// and never merged.
///
/// Applying does **not** close the dialog. The selection is written through
/// [onApply], the folder is read again through [onRescan], and every row is
/// rebuilt from that fresh reading — so a copy that was written flips to
/// **Up to date** under its own folder path, and one whose write failed stays
/// **Will update** and is visibly still outstanding. That on-screen evidence
/// is the point: when three folders hold same-named copies of one mask, a
/// bare "Synced 2 copies" cannot say *which* two.
///
/// The dialog stays a presentation widget and knows nothing of the file
/// service; the shell supplies both callbacks, closing over the service, the
/// scan root and the reference.
final class MaskSyncDialog extends StatefulWidget {
  /// Creates the sync review dialog.
  const MaskSyncDialog({
    required this.entries,
    required this.referenceName,
    required this.referenceRevision,
    required this.onApply,
    required this.onRescan,
    this.referenceSourcePath,
    this.onWritten,
    this.onFailed,
    super.key,
  });

  /// The scanned copies to review, as of the last scan.
  final List<MaskSyncEntry> entries;

  /// Writes the reference mask to the ticked paths.
  final MaskSyncApplyCallback onApply;

  /// Reads the same folder again after a write, for the same reference.
  final MaskSyncRescanCallback onRescan;

  /// Called after each apply round with the paths whose write landed.
  ///
  /// The ledger is kept by the caller rather than in this widget's state,
  /// because Escape and the barrier tear the state down without a pop value
  /// and what was written has to survive every close route alike.
  final ValueChanged<List<String>>? onWritten;

  /// Called when an apply round fails outright — typically a re-scan of a
  /// folder that has become unreadable since the dialog opened.
  final void Function(Object error, StackTrace stackTrace)? onFailed;

  /// The reference mask's own name, shown so the user knows what is about to
  /// be applied to the checked copies.
  final String referenceName;

  /// The reference mask's own revision, shown next to its name so two
  /// same-named references (e.g. an edited-but-unsaved mask) are
  /// distinguishable.
  final int referenceRevision;

  /// The reference's own source file, when it has one (the open deck may be
  /// unsaved).
  final String? referenceSourcePath;

  /// Shows the dialog; returns the paths actually written across every apply
  /// round of the visit.
  ///
  /// Closing without writing anything returns an **empty list**, never `null`:
  /// the caller has to tell "nothing was written" apart from "the command was
  /// never run", and Cancel, Escape and the barrier must be indistinguishable
  /// to the learner.
  static Future<List<String>> show(
    BuildContext context,
    List<MaskSyncEntry> entries, {
    required String referenceName,
    required int referenceRevision,
    required MaskSyncApplyCallback onApply,
    required MaskSyncRescanCallback onRescan,
    String? referenceSourcePath,
  }) async {
    // Insertion-ordered and de-duplicated: a row can only be applied twice if
    // its first write failed, and a failure contributes nothing here anyway.
    final Set<String> written = <String>{};
    Object? failure;
    StackTrace? failureStack;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => MaskSyncDialog(
        entries: entries,
        referenceName: referenceName,
        referenceRevision: referenceRevision,
        referenceSourcePath: referenceSourcePath,
        onApply: onApply,
        onRescan: onRescan,
        onWritten: written.addAll,
        onFailed: (Object error, StackTrace stackTrace) {
          failure = error;
          failureStack = stackTrace;
        },
      ),
    );
    // An apply round is driven from a button callback, so a throw inside it
    // reaches no caller on its own. Carrying it out here puts it back on the
    // caller's awaited path, where the shell reports file errors in the UI
    // language — copies written before the failure are still on disk, they
    // are just reported as an error rather than as a count.
    if (failure != null) {
      Error.throwWithStackTrace(failure!, failureStack!);
    }
    return written.toList();
  }

  @override
  State<MaskSyncDialog> createState() => _MaskSyncDialogState();
}

class _MaskSyncDialogState extends State<MaskSyncDialog> {
  // Every update must be explicitly opted into; a single misclick on Apply
  // must never mass-overwrite every willUpdate copy found under the folder.
  final Set<String> _selected = <String>{};

  /// The rows on screen: the scan the dialog opened on, then each re-scan.
  late List<MaskSyncEntry> _entries = widget.entries;

  /// True from the moment Apply is pressed until the re-scan behind it has
  /// landed, so a second Apply cannot race the scan the first is waiting for.
  bool _busy = false;

  /// Writes the ticked rows, then rebuilds every row from a fresh reading of
  /// the folder.
  Future<void> _apply() async {
    // Row order, not set order, so the shell writes them in the order they
    // are listed on screen.
    final List<String> paths = <String>[
      for (final MaskSyncEntry entry in _entries)
        if (_selected.contains(entry.path)) entry.path,
    ];
    if (paths.isEmpty) {
      return;
    }
    setState(() => _busy = true);
    try {
      final List<MaskWriteResult> results = await widget.onApply(paths);
      widget.onWritten?.call(<String>[
        for (final MaskWriteResult result in results)
          if (result.succeeded) result.path,
      ]);
      final List<MaskSyncEntry> fresh = await widget.onRescan();
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = fresh;
        // Re-derived from the fresh entries alone. A copy that is now up to
        // date is no longer selectable and so cannot be applied twice, and
        // nothing is ever preselected — that rule exists so a misclick on
        // Apply cannot mass-overwrite, and a re-scan must not quietly
        // reintroduce a preselection.
        _selected.clear();
        _busy = false;
      });
    } on Object catch (error, stackTrace) {
      // Rows can only stay honest for as long as the folder can be read. A
      // stale list would go on saying "Will update" about copies that may
      // well have been written — the exact lie this dialog exists to end —
      // so the visit ends here and the shell reports the failure instead.
      if (widget.onFailed == null) {
        rethrow;
      }
      widget.onFailed!(error, stackTrace);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      // Whatever happened, the buttons are given back.
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ThemeData theme = Theme.of(context);
    final String? sourcePath = widget.referenceSourcePath;
    // Escape and the barrier are closed off for as long as a write is in
    // flight, for the same reason the buttons are: the visit must not end
    // between the write and the re-scan that reports on it.
    return PopScope<void>(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(messages.message(LearnAnywhereMessage.maskSyncTitle)),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  messages
                      .message(LearnAnywhereMessage.maskSyncReferenceLabel)
                      .replaceAll('{name}', widget.referenceName)
                      .replaceAll(
                        '{revision}',
                        widget.referenceRevision.toString(),
                      ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (sourcePath != null)
                  Text(
                    messages
                        .message(LearnAnywhereMessage.maskSyncReferenceSource)
                        .replaceAll('{path}', sourcePath),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 8),
                for (final MaskSyncEntry entry in _entries)
                  _row(context, messages, theme, entry),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
          ),
          FilledButton(
            // Applying keeps the dialog open; the rows report the outcome
            // themselves once the re-scan behind this press lands.
            onPressed: _busy || _selected.isEmpty ? null : _apply,
            child: Text(messages.message(LearnAnywhereMessage.maskSyncApply)),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    LearnAnywhereLocalizations messages,
    ThemeData theme,
    MaskSyncEntry entry,
  ) {
    final bool selectable = entry.isUpdatable;
    // Dimmed by color swap, never by Opacity: opacity composites toward the
    // background with no defined stopping point and would drag Dark Blue's
    // row text below the contrast floor it otherwise clears comfortably.
    final Color? rowForeground = selectable
        ? null
        : LearnAnywhereChromeTheme.mutedForegroundOf(theme);
    void toggle() {
      setState(() {
        if (_selected.contains(entry.path)) {
          _selected.remove(entry.path);
        } else {
          _selected.add(entry.path);
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: selectable ? toggle : null,
            child: Row(
              children: <Widget>[
                // The row's own InkWell owns the tap when selectable, so the
                // checkbox is excluded from hit-testing to avoid the two
                // handlers racing over the same click; its semantics stay
                // live for assistive tech.
                IgnorePointer(
                  ignoring: selectable,
                  child: Checkbox(
                    value: _selected.contains(entry.path),
                    onChanged: selectable ? (bool? value) => toggle() : null,
                  ),
                ),
                Expanded(
                  child: Tooltip(
                    message: entry.path,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // The file name is the identifying part, so it goes on
                        // its own un-ellipsized line; only the (usually much
                        // longer) folder path below is left to truncate.
                        Text(
                          '${_fileNameOf(entry.path)}  '
                          '(rev ${entry.revision})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: rowForeground,
                          ),
                        ),
                        Text(
                          _folderOf(entry.path),
                          // Always the muted foreground, selectable row or
                          // not: it is secondary info either way, and a bare
                          // onSurfaceVariant is the same sub-4.5:1 color the
                          // status label was moved off of in Dark Blue.
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LearnAnywhereChromeTheme.mutedForegroundOf(
                              theme,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  _statusLabel(messages, entry.status),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _statusColor(theme, entry.status),
                  ),
                ),
              ],
            ),
          ),
          // Breaking reasons stay at full strength even on a dimmed
          // (would-break) row: dimming must not quiet a warning.
          for (final MaskBreakingReason reason in entry.reasons)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 2),
              child: Text(
                '• ${describeBreakingReason(messages, reason)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(
    LearnAnywhereLocalizations messages,
    MaskSyncStatus status,
  ) {
    return messages.message(switch (status) {
      MaskSyncStatus.upToDate => LearnAnywhereMessage.maskSyncStatusUpToDate,
      MaskSyncStatus.willUpdate => LearnAnywhereMessage.maskSyncStatusWillUpdate,
      MaskSyncStatus.wouldBreak => LearnAnywhereMessage.maskSyncStatusWouldBreak,
      MaskSyncStatus.differs => LearnAnywhereMessage.maskSyncStatusDiffers,
      MaskSyncStatus.newer => LearnAnywhereMessage.maskSyncStatusNewer,
    });
  }

  Color _statusColor(ThemeData theme, MaskSyncStatus status) {
    return switch (status) {
      MaskSyncStatus.upToDate => LearnAnywhereChromeTheme.mutedForegroundOf(
        theme,
      ),
      MaskSyncStatus.willUpdate => theme.colorScheme.primary,
      MaskSyncStatus.wouldBreak => theme.colorScheme.error,
      MaskSyncStatus.differs => theme.colorScheme.tertiary,
      MaskSyncStatus.newer => theme.colorScheme.tertiary,
    };
  }

  /// The last path segment, parsed with the host's path rules.
  ///
  /// Scan results always come from a live directory listing on the running
  /// platform, so host rules are the correct ones: on Windows both `/` and `\`
  /// separate, on Linux only `/` does — a Linux file named `a\b.vok` keeps its
  /// backslash instead of being split on it.
  String _fileNameOf(String path) => p.basename(path);

  /// Everything before the last path segment, or the whole path when it has
  /// no separator.
  String _folderOf(String path) {
    final String directory = p.dirname(path);
    return directory == '.' && !path.startsWith('.') ? path : directory;
  }
}

/// Localizes a [MaskBreakingReason] from the app catalog using its structured
/// fields, rather than its English [MaskBreakingReason.describe] fallback.
///
/// Shared by the tier-1 propagation dialog and the tier-2 sync dialog so the
/// two present identical, translated wording.
String describeBreakingReason(
  LearnAnywhereLocalizations messages,
  MaskBreakingReason reason,
) {
  final String category = reason.categoryName.isEmpty
      ? '#${reason.categoryId}'
      : reason.categoryName;
  final String field = reason.fieldName.isEmpty
      ? '#${reason.fieldId}'
      : reason.fieldName;
  return switch (reason.kind) {
    MaskBreakingKind.categoryDeleted => messages
        .message(LearnAnywhereMessage.maskBreakCategoryDeleted)
        .replaceAll('{category}', category)
        .replaceAll('{count}', reason.affectedUnits.toString()),
    MaskBreakingKind.fieldDeleted => messages
        .message(LearnAnywhereMessage.maskBreakFieldDeleted)
        .replaceAll('{field}', field)
        .replaceAll('{category}', category)
        .replaceAll('{count}', reason.affectedUnits.toString()),
    MaskBreakingKind.fieldLengthTooShort => messages
        .message(LearnAnywhereMessage.maskBreakFieldTooShort)
        .replaceAll('{field}', field)
        .replaceAll('{category}', category)
        .replaceAll('{length}', (reason.newLength ?? 0).toString())
        .replaceAll('{count}', reason.affectedUnits.toString()),
  };
}
