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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
        // Capped and left-aligned, so a switch stays within reach of its label
        // however wide the window is.
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: LearnAnywhereZoom.scaleBox(context, _maxWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _children(context, messages),
            ),
          ),
        ),
      ),
    );
  }

  /// The widest the options column grows: room for the two level-name
  /// columns, and for the longest German label beside its switch.
  static const double _maxWidth = 640;

  List<Widget> _children(
    BuildContext context,
    LearnAnywhereLocalizations messages,
  ) {
    return <Widget>[
      Text(
        messages.message(LearnAnywhereMessage.queryOptionsTitle),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      _GroupHeading(
        messages.message(LearnAnywhereMessage.queryOptionsAnswerMatching),
      ),
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
        enabled: options.almostEnabled,
        onChanged: (int value) {
          onChanged(
            options.copyWith(
              almostThreshold: value.clamp(1, 100) / 100,
            ),
          );
        },
      ),
      _GroupHeading(
        messages.message(LearnAnywhereMessage.queryOptionsGuardrails),
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
        enabled: options.minimumAttemptsGuardEnabled,
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
        enabled: options.wrongAnswerCeilingEnabled,
        onChanged: (int value) {
          onChanged(options.copyWith(wrongAnswerCeiling: value));
        },
      ),
      // The four time pills and the limit that acts on one of them: four
      // similar names need the group and their tooltips to be told apart.
      _GroupHeading(
        messages.message(LearnAnywhereMessage.queryOptionsTimeDisplay),
      ),
      _SwitchOption(
        title: messages.message(
          LearnAnywhereMessage.queryOptionShowUnitTime,
        ),
        tooltip: messages.message(
          LearnAnywhereMessage.queryOptionShowUnitTimeTooltip,
        ),
        value: options.showUnitTime,
        onChanged: (bool value) {
          onChanged(options.copyWith(showUnitTime: value));
        },
      ),
      _SwitchOption(
        title: messages.message(
          LearnAnywhereMessage.queryOptionShowSittingTime,
        ),
        tooltip: messages.message(
          LearnAnywhereMessage.queryOptionShowSittingTimeTooltip,
        ),
        value: options.showSittingTime,
        onChanged: (bool value) {
          onChanged(options.copyWith(showSittingTime: value));
        },
      ),
      _SwitchOption(
        title: messages.message(
          LearnAnywhereMessage.queryOptionShowStatisticsTime,
        ),
        tooltip: messages.message(
          LearnAnywhereMessage.queryOptionShowStatisticsTimeTooltip,
        ),
        value: options.showStatisticsTime,
        onChanged: (bool value) {
          onChanged(options.copyWith(showStatisticsTime: value));
        },
      ),
      _SwitchOption(
        title: messages.message(
          LearnAnywhereMessage.queryOptionShowTotalTime,
        ),
        tooltip: messages.message(
          LearnAnywhereMessage.queryOptionShowTotalTimeTooltip,
        ),
        value: options.showTotalTime,
        onChanged: (bool value) {
          onChanged(options.copyWith(showTotalTime: value));
        },
      ),
      _NumberOption(
        title: messages.message(LearnAnywhereMessage.queryOptionTimeLimit),
        tooltip: messages.message(
          LearnAnywhereMessage.queryOptionTimeLimitTooltip,
        ),
        value: options.timeLimitSeconds,
        enabled: options.showUnitTime,
        onChanged: (int value) {
          onChanged(options.copyWith(timeLimitSeconds: value));
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
    ];
  }
}

/// A group's title. Every option sits under one, so no row reads as part of a
/// group it does not belong to.
final class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: LearnAnywhereTokens.gapLarge,
        bottom: LearnAnywhereTokens.gapSmall,
      ),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
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
      width: LearnAnywhereZoom.scaleBox(context, 260),
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
    this.tooltip,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// What the option does, where its title alone cannot say.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return _withTooltip(
      tooltip,
      SwitchListTile(title: Text(title), value: value, onChanged: onChanged),
    );
  }
}

/// [child] with [tooltip] on hover, or unchanged when there is none.
Widget _withTooltip(String? tooltip, Widget child) {
  return tooltip == null ? child : Tooltip(message: tooltip, child: child);
}

final class _NumberOption extends StatefulWidget {
  const _NumberOption({
    required this.title,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
    this.maximum,
    this.tooltip,
    this.enabled = true,
  });

  final String title;
  final int value;
  final int minimum;
  final int? maximum;
  final ValueChanged<int> onChanged;

  /// False while the switch this value belongs to is off: the value is kept
  /// and shown, but greyed out, because it has no effect.
  final bool enabled;

  /// What the option does, where its title alone cannot say.
  final String? tooltip;

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
        width: LearnAnywhereZoom.scaleBox(context, 320),
        child: _withTooltip(
          widget.tooltip,
          TextField(
            controller: _controller,
            enabled: widget.enabled,
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
      ),
    );
  }
}
