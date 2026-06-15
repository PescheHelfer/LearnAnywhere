/// Framework-independent message keys and catalogs for Learn Anywhere.
library;

/// Supported Learn Anywhere UI languages.
enum LearnAnywhereLanguage {
  /// English UI.
  english('en'),

  /// German UI.
  german('de');

  const LearnAnywhereLanguage(this.code);

  /// BCP-47 language code.
  final String code;

  /// Resolves a supported language by code, falling back to English.
  static LearnAnywhereLanguage fromCode(String code) {
    return switch (code.toLowerCase()) {
      'de' => LearnAnywhereLanguage.german,
      _ => LearnAnywhereLanguage.english,
    };
  }
}

/// Message identifiers for app-level UI strings.
enum LearnAnywhereMessage {
  /// Application title.
  appTitle,

  /// Desktop shell readiness text.
  desktopShellReady,

  /// Mobile shell readiness text.
  mobileShellReady,

  /// Super-query completion message.
  superQueryCompleted,
}

/// Localized message catalog for framework-independent strings.
final class LearnAnywhereCatalog {
  const LearnAnywhereCatalog._();

  static const Map<LearnAnywhereLanguage, Map<LearnAnywhereMessage, String>>
  _messages = <LearnAnywhereLanguage, Map<LearnAnywhereMessage, String>>{
    LearnAnywhereLanguage.english: <LearnAnywhereMessage, String>{
      LearnAnywhereMessage.appTitle: 'Learn Anywhere',
      LearnAnywhereMessage.desktopShellReady: 'Desktop shell ready',
      LearnAnywhereMessage.mobileShellReady: 'Mobile shell ready',
      LearnAnywhereMessage.superQueryCompleted:
          'You have now mastered all learning units in the selected range. Congratulations!',
    },
    LearnAnywhereLanguage.german: <LearnAnywhereMessage, String>{
      LearnAnywhereMessage.appTitle: 'Learn Anywhere',
      LearnAnywhereMessage.desktopShellReady: 'Desktop-Shell bereit',
      LearnAnywhereMessage.mobileShellReady: 'Mobile-Shell bereit',
      LearnAnywhereMessage.superQueryCompleted:
          'Sie beherrschen nun alle Lerneinheiten im gewaehlten Bereich! Herzlichen Glueckwunsch!',
    },
  };

  /// Supported language codes.
  static List<String> get supportedLanguageCodes {
    return LearnAnywhereLanguage.values
        .map((LearnAnywhereLanguage language) => language.code)
        .toList(growable: false);
  }

  /// Returns a localized message for [message] and [languageCode].
  static String message(LearnAnywhereMessage message, String languageCode) {
    final LearnAnywhereLanguage language = LearnAnywhereLanguage.fromCode(
      languageCode,
    );
    return _messages[language]![message] ??
        _messages[LearnAnywhereLanguage.english]![message]!;
  }
}
