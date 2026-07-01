import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'desktop_query_options.dart';

/// Desktop query-options page.
final class QueryOptionsPage extends StatelessWidget {
  /// Creates query options controls.
  const QueryOptionsPage({
    required this.options,
    required this.onChanged,
    this.onClose,
    super.key,
  });

  /// Current query options.
  final DesktopQueryOptions options;

  /// Called when options change.
  final ValueChanged<DesktopQueryOptions> onChanged;

  /// Called when the user closes this page.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final Widget page = _buildPage(context, messages);
    final VoidCallback? close = onClose;
    if (close == null) {
      return page;
    }
    // The Close button is styled as the screen's default action, so Enter
    // should activate it the same way Esc (handled globally in main.dart)
    // already does.
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _CloseIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CloseIntent: CallbackAction<_CloseIntent>(
            onInvoke: (_) {
              close();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: page),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    LearnAnywhereLocalizations messages,
  ) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        children: <Widget>[
          Text(
            messages.message(LearnAnywhereMessage.queryOptionsTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: LearnAnywhereTokens.gapMedium),
          _SwitchOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionWrongInputCorrectable,
            ),
            value: options.wrongInputCorrectable,
            onChanged: (bool value) {
              onChanged(options.copyWith(wrongInputCorrectable: value));
            },
          ),
          _SwitchOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionCompleteInputRequired,
            ),
            value: options.completeInputRequired,
            onChanged: (bool value) {
              onChanged(options.copyWith(completeInputRequired: value));
            },
          ),
          _SwitchOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionCaseSensitive,
            ),
            value: options.caseSensitive,
            onChanged: (bool value) {
              onChanged(options.copyWith(caseSensitive: value));
            },
          ),
          _SwitchOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionAccentSensitive,
            ),
            value: options.accentSensitive,
            onChanged: (bool value) {
              onChanged(options.copyWith(accentSensitive: value));
            },
          ),
          _SwitchOption(
            title: messages.message(LearnAnywhereMessage.queryOptionShowClock),
            value: options.showClock,
            onChanged: (bool value) {
              onChanged(options.copyWith(showClock: value));
            },
          ),
          _NumberOption(
            title: messages.message(LearnAnywhereMessage.queryOptionTimeLimit),
            value: options.timeLimitSeconds,
            onChanged: (int value) {
              onChanged(options.copyWith(timeLimitSeconds: value));
            },
          ),
          _SwitchOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionMinimumAttemptsGuard,
            ),
            value: options.minimumAttemptsGuardEnabled,
            onChanged: (bool value) {
              onChanged(options.copyWith(minimumAttemptsGuardEnabled: value));
            },
          ),
          _NumberOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionMinimumAttempts,
            ),
            value: options.minAttempts,
            minimum: 1,
            onChanged: (int value) {
              onChanged(options.copyWith(minAttempts: value));
            },
          ),
          _SwitchOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionWrongAnswerCeiling,
            ),
            value: options.wrongAnswerCeilingEnabled,
            onChanged: (bool value) {
              onChanged(options.copyWith(wrongAnswerCeilingEnabled: value));
            },
          ),
          _NumberOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionWrongAnswerCeilingValue,
            ),
            value: options.wrongAnswerCeiling,
            minimum: 1,
            onChanged: (int value) {
              onChanged(options.copyWith(wrongAnswerCeiling: value));
            },
          ),
          if (onClose != null) ...<Widget>[
            const SizedBox(height: LearnAnywhereTokens.gapLarge),
            Align(
              alignment: Alignment.centerLeft,
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
    );
  }
}

final class _CloseIntent extends Intent {
  const _CloseIntent();
}

final class _SwitchOption extends StatelessWidget {
  const _SwitchOption({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

final class _NumberOption extends StatefulWidget {
  const _NumberOption({
    required this.title,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
  });

  final String title;
  final int value;
  final int minimum;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberOption> createState() => _NumberOptionState();
}

final class _NumberOptionState extends State<_NumberOption> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumberOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String text = widget.value.toString();
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LearnAnywhereTokens.gapMedium,
        vertical: LearnAnywhereTokens.gapSmall,
      ),
      child: SizedBox(
        width: 320,
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(labelText: widget.title),
          onChanged: (String value) {
            final int parsed = int.tryParse(value) ?? widget.minimum;
            widget.onChanged(parsed < widget.minimum ? widget.minimum : parsed);
          },
        ),
      ),
    );
  }
}
