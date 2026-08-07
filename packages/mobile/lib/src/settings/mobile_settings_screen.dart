import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learn_anywhere_core/core.dart';
import 'package:learn_anywhere_ui_kit/learn_anywhere_ui_kit.dart';

import '../mobile_app_scope.dart';
import '../mobile_app_theme.dart';
import '../mobile_file_service.dart';
import '../mobile_prefs.dart';
import '../widgets/mobile_form_rows.dart';

/// Mobile settings screen: theme, language, and the guardrails that keep
/// think-only Drill sessions from mastering a unit on one lucky "Knew it".
///
/// Theme and language apply and persist immediately, mirroring desktop's
/// Options menu; the guardrails persist to core's JSON settings file. Reads
/// the current theme/locale/guardrails through [MobileAppScope] (not as
/// constructor props) so this screen's own display stays live even though
/// its route, like every pushed route, is built once and cached.
final class MobileSettingsScreen extends StatefulWidget {
  /// Creates the mobile settings screen.
  const MobileSettingsScreen({
    required this.prefs,
    required this.fileService,
    super.key,
  });

  /// Preferences store for theme and language.
  final MobilePrefs prefs;

  /// File service used to persist guardrail settings.
  final MobileFileService fileService;

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

final class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
  void _setTheme(MobileAppTheme value) {
    widget.prefs.setTheme(value.name);
    MobileAppScope.of(context).onThemeChanged(value);
  }

  void _setLocale(Locale value) {
    widget.prefs.setLocale(value.languageCode);
    MobileAppScope.of(context).onLocaleChanged(value);
  }

  void _applyGuardSettings(LearnAnywhereSettings next) {
    unawaited(widget.fileService.saveSettings(next));
    MobileAppScope.of(context).onGuardSettingsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final LearnAnywhereLocalizations messages = LearnAnywhereLocalizations.of(
      context,
    );
    final MobileAppScope scope = MobileAppScope.of(context);
    final LearnAnywhereSettings guardSettings = scope.guardSettings;
    return Scaffold(
      appBar: AppBar(
        title: Text(messages.message(LearnAnywhereMessage.mobileSettingsTitle)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LearnAnywhereTokens.gapLarge),
          children: <Widget>[
            Text(
              messages.message(LearnAnywhereMessage.themeLabel),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioGroup<MobileAppTheme>(
              groupValue: scope.theme,
              onChanged: (MobileAppTheme? value) {
                if (value != null) {
                  _setTheme(value);
                }
              },
              child: Column(
                children: <Widget>[
                  for (final MobileAppTheme theme in MobileAppTheme.values)
                    RadioListTile<MobileAppTheme>(
                      contentPadding: EdgeInsets.zero,
                      title: MenuAcceleratorDisplayLabel(
                        messages.message(_themeLabel(theme)),
                      ),
                      value: theme,
                    ),
                ],
              ),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            Text(
              messages.message(LearnAnywhereMessage.languageLabel),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RadioGroup<Locale>(
              groupValue: scope.locale,
              onChanged: (Locale? value) {
                if (value != null) {
                  _setLocale(value);
                }
              },
              child: Column(
                children: <Widget>[
                  RadioListTile<Locale>(
                    contentPadding: EdgeInsets.zero,
                    title: MenuAcceleratorDisplayLabel(
                      messages.message(LearnAnywhereMessage.languageEnglish),
                    ),
                    value: const Locale('en'),
                  ),
                  RadioListTile<Locale>(
                    contentPadding: EdgeInsets.zero,
                    title: MenuAcceleratorDisplayLabel(
                      messages.message(LearnAnywhereMessage.languageGerman),
                    ),
                    value: const Locale('de'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LearnAnywhereTokens.gapMedium),
            MobileToggleRow(
              label: messages.message(
                LearnAnywhereMessage.queryOptionMinimumAttemptsGuard,
              ),
              value: guardSettings.minimumAttemptsGuardEnabled,
              onChanged: (bool value) {
                _applyGuardSettings(
                  guardSettings.copyWith(minimumAttemptsGuardEnabled: value),
                );
              },
            ),
            MobileNumberRow(
              label: messages.message(
                LearnAnywhereMessage.queryOptionMinimumAttempts,
              ),
              value: guardSettings.minAttempts,
              minimum: 1,
              enabled: guardSettings.minimumAttemptsGuardEnabled,
              onChanged: (int value) {
                _applyGuardSettings(guardSettings.copyWith(minAttempts: value));
              },
            ),
            MobileToggleRow(
              label: messages.message(
                LearnAnywhereMessage.queryOptionWrongAnswerCeiling,
              ),
              value: guardSettings.wrongAnswerCeilingEnabled,
              onChanged: (bool value) {
                _applyGuardSettings(
                  guardSettings.copyWith(wrongAnswerCeilingEnabled: value),
                );
              },
            ),
            MobileNumberRow(
              label: messages.message(
                LearnAnywhereMessage.queryOptionWrongAnswerCeilingValue,
              ),
              value: guardSettings.wrongAnswerCeiling,
              minimum: 1,
              enabled: guardSettings.wrongAnswerCeilingEnabled,
              onChanged: (int value) {
                _applyGuardSettings(
                  guardSettings.copyWith(wrongAnswerCeiling: value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

LearnAnywhereMessage _themeLabel(MobileAppTheme theme) {
  return switch (theme) {
    MobileAppTheme.system => LearnAnywhereMessage.themeSystem,
    MobileAppTheme.light => LearnAnywhereMessage.themeLight,
    MobileAppTheme.dark => LearnAnywhereMessage.themeDark,
    MobileAppTheme.darkBlue => LearnAnywhereMessage.themeDarkBlue,
    MobileAppTheme.lightBlue => LearnAnywhereMessage.themeLightBlue,
  };
}
