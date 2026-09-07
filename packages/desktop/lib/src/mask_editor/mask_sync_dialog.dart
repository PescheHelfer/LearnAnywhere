import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';
import 'package:path/path.dart' as p;

import '../file_operations/desktop_file_service.dart';

/// Review dialog for tier-2 cross-directory mask sync (Step 7).
///
/// Lists every `.inf`/`.vok` copy of the mask found under the chosen folder
/// with its status, lets the user select which updatable copies to apply, and
/// returns the selected paths (or `null` on cancel). Only [MaskSyncStatus
/// .willUpdate] copies are selectable; up-to-date, would-break, and
/// same-revision "differs" copies are shown for information and never merged.
final class MaskSyncDialog extends StatefulWidget {
  /// Creates the sync review dialog.
  const MaskSyncDialog({
    required this.entries,
    required this.referenceName,
    required this.referenceRevision,
    this.referenceSourcePath,
    super.key,
  });

  /// The scanned copies to review.
  final List<MaskSyncEntry> entries;

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

  /// Shows the dialog; returns the selected paths, or `null` when cancelled.
  static Future<List<String>?> show(
    BuildContext context,
    List<MaskSyncEntry> entries, {
    required String referenceName,
    required int referenceRevision,
    String? referenceSourcePath,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => MaskSyncDialog(
        entries: entries,
        referenceName: referenceName,
        referenceRevision: referenceRevision,
        referenceSourcePath: referenceSourcePath,
      ),
    );
  }

  @override
  State<MaskSyncDialog> createState() => _MaskSyncDialogState();
}

class _MaskSyncDialogState extends State<MaskSyncDialog> {
  // Every update must be explicitly opted into; a single misclick on Apply
  // must never mass-overwrite every willUpdate copy found under the folder.
  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ThemeData theme = Theme.of(context);
    final String? sourcePath = widget.referenceSourcePath;
    return AlertDialog(
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
              for (final MaskSyncEntry entry in widget.entries)
                _row(context, messages, theme, entry),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(messages.message(LearnAnywhereMessage.actionCancel)),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
          child: Text(messages.message(LearnAnywhereMessage.maskSyncApply)),
        ),
      ],
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
