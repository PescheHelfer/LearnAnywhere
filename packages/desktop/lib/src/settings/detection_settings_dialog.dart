import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

/// What the detection settings dialog hands back: the switch and the rule's
/// three thresholds.
typedef DetectionSettings = ({bool enabled, DetectionThresholds thresholds});

/// Options ▸ Statistics ▸ Detect difficult units: shows the detection switch
/// and the three thresholds, starting from [enabled] and [thresholds].
///
/// Completes with the learner's choice on OK, or null on Cancel. OK is
/// offered only while every threshold holds a whole number within its range
/// ([DetectionThresholds]), so what comes back is always valid.
Future<DetectionSettings?> showDetectionSettingsDialog(
  BuildContext context, {
  required bool enabled,
  required DetectionThresholds thresholds,
}) {
  return showDialog<DetectionSettings>(
    context: context,
    builder: (BuildContext context) =>
        _DetectionSettingsDialog(enabled: enabled, thresholds: thresholds),
  );
}

final class _DetectionSettingsDialog extends StatefulWidget {
  const _DetectionSettingsDialog({
    required this.enabled,
    required this.thresholds,
  });

  final bool enabled;
  final DetectionThresholds thresholds;

  @override
  State<_DetectionSettingsDialog> createState() =>
      _DetectionSettingsDialogState();
}

final class _DetectionSettingsDialogState
    extends State<_DetectionSettingsDialog> {
  late bool _enabled = widget.enabled;
  late final TextEditingController _minWrong = TextEditingController(
    text: widget.thresholds.minWrong.toString(),
  );
  late final TextEditingController _minWrongRate = TextEditingController(
    text: widget.thresholds.minWrongRatePercent.toString(),
  );
  late final TextEditingController _minAttempts = TextEditingController(
    text: widget.thresholds.minAttemptsWithoutCorrect.toString(),
  );

  @override
  void dispose() {
    _minWrong.dispose();
    _minWrongRate.dispose();
    _minAttempts.dispose();
    super.dispose();
  }

  /// The thresholds as typed, or null while any field holds no number within
  /// its range.
  DetectionThresholds? get _thresholds {
    final DetectionThresholds typed = DetectionThresholds(
      minWrong: int.tryParse(_minWrong.text) ?? -1,
      minWrongRatePercent: int.tryParse(_minWrongRate.text) ?? -1,
      minAttemptsWithoutCorrect: int.tryParse(_minAttempts.text) ?? -1,
    );
    return typed.isInRange ? typed : null;
  }

  void _resetThresholds() {
    const DetectionThresholds defaults = DetectionThresholds.defaults;
    setState(() {
      _minWrong.text = defaults.minWrong.toString();
      _minWrongRate.text = defaults.minWrongRatePercent.toString();
      _minAttempts.text = defaults.minAttemptsWithoutCorrect.toString();
    });
  }

  void _submit() {
    final DetectionThresholds? thresholds = _thresholds;
    if (thresholds != null) {
      Navigator.of(context).pop((enabled: _enabled, thresholds: thresholds));
    }
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final bool valid = _thresholds != null;
    Widget field(
      TextEditingController controller,
      LearnAnywhereMessage label,
      ThresholdRange range,
    ) {
      String withRange(LearnAnywhereMessage message) => messages
          .message(message)
          .replaceAll('{min}', range.min.toString())
          .replaceAll('{max}', range.max.toString());
      return Padding(
        padding: const EdgeInsets.only(top: LearnAnywhereTokens.gapMedium),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: withRange(label),
            errorText: range.contains(int.tryParse(controller.text))
                ? null
                : withRange(LearnAnywhereMessage.detectDifficultOutOfRange),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    return AlertDialog(
      title: Text(messages.message(LearnAnywhereMessage.detectDifficultTitle)),
      content: SizedBox(
        width: LearnAnywhereZoom.scaleBox(context, 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                autofocus: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  messages.message(
                    LearnAnywhereMessage.detectDifficultEnabled,
                  ),
                ),
                value: _enabled,
                onChanged: (bool value) => setState(() => _enabled = value),
              ),
              Text(
                messages.message(LearnAnywhereMessage.detectDifficultHint),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              field(
                _minWrong,
                LearnAnywhereMessage.detectDifficultMinWrong,
                DetectionThresholds.minWrongRange,
              ),
              field(
                _minWrongRate,
                LearnAnywhereMessage.detectDifficultMinWrongRate,
                DetectionThresholds.minWrongRatePercentRange,
              ),
              field(
                _minAttempts,
                LearnAnywhereMessage.detectDifficultMinAttempts,
                DetectionThresholds.minAttemptsWithoutCorrectRange,
              ),
              const SizedBox(height: LearnAnywhereTokens.gapMedium),
              OutlinedButton.icon(
                onPressed: _resetThresholds,
                icon: const Icon(Icons.restart_alt),
                label: Text(
                  messages.message(LearnAnywhereMessage.detectDifficultReset),
                ),
              ),
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
          onPressed: valid ? _submit : null,
          child: Text(messages.message(LearnAnywhereMessage.actionOk)),
        ),
      ],
    );
  }
}
