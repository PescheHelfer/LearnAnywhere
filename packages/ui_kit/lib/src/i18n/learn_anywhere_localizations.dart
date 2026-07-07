import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:learn_anywhere_core/core.dart';

/// Flutter localization adapter backed by core message catalogs.
final class LearnAnywhereLocalizations {
  /// Creates localizations for [locale].
  const LearnAnywhereLocalizations(this.locale);

  /// Active locale.
  final Locale locale;

  /// Supported Flutter locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  /// Delegates required by Learn Anywhere Material apps.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        _LearnAnywhereLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// Reads localizations from [context].
  static LearnAnywhereLocalizations of(BuildContext context) {
    return Localizations.of<LearnAnywhereLocalizations>(
      context,
      LearnAnywhereLocalizations,
    )!;
  }

  /// Resolves [message] for the active locale.
  String message(LearnAnywhereMessage message) {
    return LearnAnywhereCatalog.message(message, locale.languageCode);
  }

  /// Application title.
  String get appTitle => message(LearnAnywhereMessage.appTitle);
}

final class _LearnAnywhereLocalizationsDelegate
    extends LocalizationsDelegate<LearnAnywhereLocalizations> {
  const _LearnAnywhereLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return LearnAnywhereCatalog.supportedLanguageCodes.contains(
      locale.languageCode,
    );
  }

  @override
  Future<LearnAnywhereLocalizations> load(Locale locale) async {
    return LearnAnywhereLocalizations(locale);
  }

  @override
  bool shouldReload(_LearnAnywhereLocalizationsDelegate old) => false;
}
