import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import 'desktop_query_options.dart';

/// Called with the updated English and German level-name lists.
typedef LevelNamesChanged = void Function(
  List<String> levelNamesEn,
  List<String> levelNamesDe,
);

/// Desktop query-options page.
final class QueryOptionsPage extends StatelessWidget {
  /// Creates query options controls.
  const QueryOptionsPage({
    required this.options,
    required this.onChanged,
    this.levelNamesEn = kDefaultLevelNamesEn,
    this.levelNamesDe = kDefaultLevelNamesDe,
    this.onLevelNamesChanged,
    this.onClose,
    super.key,
  });

  /// Current query options.
  final DesktopQueryOptions options;

  /// Called when options change.
  final ValueChanged<DesktopQueryOptions> onChanged;

  /// Current English Level-Learning level names (engine level 3 → 0).
  final List<String> levelNamesEn;

  /// Current German Level-Learning level names (engine level 3 → 0).
  final List<String> levelNamesDe;

  /// Called when the user edits the Level-Learning level names.
  final LevelNamesChanged? onLevelNamesChanged;

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
            title: messages.message(
              LearnAnywhereMessage.queryOptionAlmostEnabled,
            ),
            value: options.almostEnabled,
            onChanged: (bool value) {
              onChanged(options.copyWith(almostEnabled: value));
            },
          ),
          _NumberOption(
            title: messages.message(
              LearnAnywhereMessage.queryOptionAlmostThreshold,
            ),
            value: (options.almostThreshold * 100).round(),
            minimum: 1,
            maximum: 100,
            onChanged: (int value) {
              onChanged(
                options.copyWith(
                  almostThreshold: value.clamp(1, 100) / 100,
                ),
              );
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
          const SizedBox(height: LearnAnywhereTokens.gapLarge),
          _LevelNamesPanel(
            levelNamesEn: levelNamesEn,
            levelNamesDe: levelNamesDe,
            onChanged: onLevelNamesChanged,
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

/// Editor for the four Level-Learning level names, per language, with a
/// space-launch preset and a reset-to-defaults action. Names are user data;
/// only the surrounding chrome is localized.
final class _LevelNamesPanel extends StatefulWidget {
  const _LevelNamesPanel({
    required this.levelNamesEn,
    required this.levelNamesDe,
    required this.onChanged,
  });

  final List<String> levelNamesEn;
  final List<String> levelNamesDe;
  final LevelNamesChanged? onChanged;

  @override
  State<_LevelNamesPanel> createState() => _LevelNamesPanelState();
}

final class _LevelNamesPanelState extends State<_LevelNamesPanel> {
  late List<TextEditingController> _en;
  late List<TextEditingController> _de;

  @override
  void initState() {
    super.initState();
    _en = _controllersFrom(widget.levelNamesEn);
    _de = _controllersFrom(widget.levelNamesDe);
  }

  List<TextEditingController> _controllersFrom(List<String> names) {
    return <TextEditingController>[
      for (int i = 0; i < levelNameCount; i++)
        TextEditingController(text: i < names.length ? names[i] : ''),
    ];
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[..._en, ..._de]) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged?.call(
      <String>[for (final TextEditingController c in _en) c.text],
      <String>[for (final TextEditingController c in _de) c.text],
    );
  }

  void _applyLists(List<String> en, List<String> de) {
    for (int i = 0; i < levelNameCount; i++) {
      _en[i].text = i < en.length ? en[i] : '';
      _de[i].text = i < de.length ? de[i] : '';
    }
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          messages.message(LearnAnywhereMessage.learnLevelNamesTitle),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapSmall),
        Text(
          messages.message(LearnAnywhereMessage.learnLevelNamesOrderHint),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Wrap(
          spacing: LearnAnywhereTokens.gapLarge,
          runSpacing: LearnAnywhereTokens.gapMedium,
          children: <Widget>[
            _LevelNameColumn(
              title: messages.message(
                LearnAnywhereMessage.learnLevelNamesEnglish,
              ),
              controllers: _en,
              onChanged: _emit,
            ),
            _LevelNameColumn(
              title: messages.message(
                LearnAnywhereMessage.learnLevelNamesGerman,
              ),
              controllers: _de,
              onChanged: _emit,
            ),
          ],
        ),
        const SizedBox(height: LearnAnywhereTokens.gapMedium),
        Wrap(
          spacing: LearnAnywhereTokens.gapSmall,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () => _applyLists(
                kSpaceLaunchLevelNamesEn,
                kSpaceLaunchLevelNamesDe,
              ),
              icon: const Icon(Icons.rocket_launch),
              label: Text(
                messages.message(
                  LearnAnywhereMessage.learnLevelNamesApplyPreset,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _applyLists(
                kDefaultLevelNamesEn,
                kDefaultLevelNamesDe,
              ),
              icon: const Icon(Icons.restart_alt),
              label: Text(
                messages.message(LearnAnywhereMessage.learnLevelNamesReset),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One language column of four level-name fields (most support at the top).
final class _LevelNameColumn extends StatelessWidget {
  const _LevelNameColumn({
    required this.title,
    required this.controllers,
    required this.onChanged,
  });

  final String title;
  final List<TextEditingController> controllers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: LearnAnywhereZoom.scale(context, 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: LearnAnywhereTokens.gapSmall),
          for (int i = 0; i < controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(
                bottom: LearnAnywhereTokens.gapSmall,
              ),
              child: TextField(
                controller: controllers[i],
                maxLength: 20,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
        ],
      ),
    );
  }
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
    this.maximum,
  });

  final String title;
  final int value;
  final int minimum;
  final int? maximum;
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
        width: LearnAnywhereZoom.scale(context, 320),
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(labelText: widget.title),
          onChanged: (String value) {
            var parsed = int.tryParse(value) ?? widget.minimum;
            if (parsed < widget.minimum) {
              parsed = widget.minimum;
            }
            final int? maximum = widget.maximum;
            if (maximum != null && parsed > maximum) {
              parsed = maximum;
            }
            widget.onChanged(parsed);
          },
        ),
      ),
    );
  }
}
