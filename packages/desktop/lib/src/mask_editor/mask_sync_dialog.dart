import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

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
  const MaskSyncDialog({required this.entries, super.key});

  /// The scanned copies to review.
  final List<MaskSyncEntry> entries;

  /// Shows the dialog; returns the selected paths, or `null` when cancelled.
  static Future<List<String>?> show(
    BuildContext context,
    List<MaskSyncEntry> entries,
  ) {
    return showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => MaskSyncDialog(entries: entries),
    );
  }

  @override
  State<MaskSyncDialog> createState() => _MaskSyncDialogState();
}

class _MaskSyncDialogState extends State<MaskSyncDialog> {
  late final Set<String> _selected = <String>{
    for (final MaskSyncEntry entry in widget.entries)
      if (entry.isUpdatable) entry.path,
  };

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ThemeData theme = Theme.of(context);
    return AlertDialog(
      title: Text(messages.message(LearnAnywhereMessage.maskSyncTitle)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                value: _selected.contains(entry.path),
                onChanged: selectable
                    ? (bool? value) {
                        setState(() {
                          if (value ?? false) {
                            _selected.add(entry.path);
                          } else {
                            _selected.remove(entry.path);
                          }
                        });
                      }
                    : null,
              ),
              Expanded(
                child: Text(
                  '${_fileName(entry.path)}  (rev ${entry.revision})',
                  style: theme.textTheme.bodyMedium,
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
          for (final MaskBreakingReason reason in entry.reasons)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 2),
              child: Text(
                '• ${reason.describe()}',
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
    });
  }

  Color _statusColor(ThemeData theme, MaskSyncStatus status) {
    return switch (status) {
      MaskSyncStatus.upToDate => theme.colorScheme.outline,
      MaskSyncStatus.willUpdate => theme.colorScheme.primary,
      MaskSyncStatus.wouldBreak => theme.colorScheme.error,
      MaskSyncStatus.differs => theme.colorScheme.tertiary,
    };
  }

  String _fileName(String path) {
    final int slash = path.lastIndexOf('/');
    final int backslash = path.lastIndexOf(r'\');
    final int separator = slash > backslash ? slash : backslash;
    return separator < 0 ? path : path.substring(separator + 1);
  }
}
