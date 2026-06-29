import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// Desktop About page with legacy and conversion credits.
final class AboutPage extends StatelessWidget {
  /// Creates the About page.
  const AboutPage({this.onClose, super.key});

  /// Called when the user closes this page.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: LearnAnywhereTokens.smallRadius,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: LearnAnywhereTokens.gapMedium),
                        Expanded(
                          child: Text(
                            messages.message(
                              LearnAnywhereMessage.routeAboutTitle,
                            ),
                            style: textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LearnAnywhereTokens.gapLarge),
                    Text(
                      messages.message(LearnAnywhereMessage.aboutIntro),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: LearnAnywhereTokens.gapMedium),
                    _CreditPanel(
                      label: messages.message(
                        LearnAnywhereMessage.aboutOriginalCredit,
                      ),
                    ),
                    const SizedBox(height: LearnAnywhereTokens.gapSmall),
                    Text(
                      messages.message(
                        LearnAnywhereMessage.aboutConversionCredit,
                      ),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: LearnAnywhereTokens.gapLarge),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: LearnAnywhereTokens.gapMedium),
                    Text(
                      messages.message(
                        LearnAnywhereMessage.aboutVersionHistory,
                      ),
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: LearnAnywhereTokens.gapSmall),
                    _VersionHistoryItem(
                      label: messages.message(
                        LearnAnywhereMessage.aboutVersionCurrent,
                      ),
                    ),
                    const SizedBox(height: LearnAnywhereTokens.gapSmall),
                    _VersionHistoryItem(
                      label: messages.message(
                        LearnAnywhereMessage.aboutVersionPrevious,
                      ),
                    ),
                    if (onClose != null) ...<Widget>[
                      const SizedBox(height: LearnAnywhereTokens.gapLarge),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: onClose,
                          child: Text(
                            messages.message(LearnAnywhereMessage.actionClose),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _CreditPanel extends StatelessWidget {
  const _CreditPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: LearnAnywhereTokens.smallRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.history_edu, color: colorScheme.secondary),
            const SizedBox(width: LearnAnywhereTokens.gapSmall),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _VersionHistoryItem extends StatelessWidget {
  const _VersionHistoryItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.check_circle_outline, color: colorScheme.primary, size: 20),
        const SizedBox(width: LearnAnywhereTokens.gapSmall),
        Expanded(child: Text(label)),
      ],
    );
  }
}
