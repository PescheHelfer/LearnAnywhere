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

  /// Home route title.
  desktopHomeTitle,

  /// Home route body.
  desktopHomeBody,

  /// File menu label.
  menuFile,

  /// New deck command.
  fileNewDeck,

  /// Open deck command.
  fileOpenDeck,

  /// Add or merge deck command.
  fileAddMergeDeck,

  /// Save command.
  fileSave,

  /// Save as command.
  fileSaveAs,

  /// Clear units command.
  fileClearUnits,

  /// Load mask command.
  fileLoadMask,

  /// Save mask command.
  fileSaveMask,

  /// Exit command.
  fileExit,

  /// Edit menu label.
  menuEdit,

  /// Mask editor menu label.
  menuMaskEditor,

  /// Learn menu label.
  menuLearn,

  /// Query options menu label.
  menuQueryOptions,

  /// Statistics menu label.
  menuStatistics,

  /// Lexicon menu label.
  menuLexicon,

  /// List menu label.
  menuList,

  /// Help menu label.
  menuHelp,

  /// About command.
  helpAbout,

  /// Theme control label.
  themeLabel,

  /// System theme option.
  themeSystem,

  /// Light theme option.
  themeLight,

  /// Dark theme option.
  themeDark,

  /// Language control label.
  languageLabel,

  /// English language option.
  languageEnglish,

  /// German language option.
  languageGerman,

  /// File operations placeholder title.
  routeFileOperationsTitle,

  /// File operations placeholder body.
  routeFileOperationsBody,

  /// Editor placeholder title.
  routeEditorTitle,

  /// Editor placeholder body.
  routeEditorBody,

  /// Mask editor placeholder title.
  routeMaskEditorTitle,

  /// Mask editor placeholder body.
  routeMaskEditorBody,

  /// Learn placeholder title.
  routeLearnTitle,

  /// Learn placeholder body.
  routeLearnBody,

  /// Query options placeholder title.
  routeQueryOptionsTitle,

  /// Query options placeholder body.
  routeQueryOptionsBody,

  /// Statistics placeholder title.
  routeStatisticsTitle,

  /// Statistics placeholder body.
  routeStatisticsBody,

  /// Lexicon placeholder title.
  routeLexiconTitle,

  /// Lexicon placeholder body.
  routeLexiconBody,

  /// List placeholder title.
  routeListTitle,

  /// List placeholder body.
  routeListBody,

  /// About placeholder title.
  routeAboutTitle,

  /// About placeholder body.
  routeAboutBody,

  /// Desktop bottom shortcut hint bar text.
  desktopHintBar,

  /// Unit editor empty-state title.
  editorEmptyTitle,

  /// Unit editor empty-state body.
  editorEmptyBody,

  /// Unit editor unit header.
  editorUnitHeader,

  /// Unit editor formatting toolbar label.
  editorFormatting,

  /// Unit editor previous action.
  editorPrevious,

  /// Unit editor next action.
  editorNext,

  /// Unit editor jump action.
  editorJump,

  /// Unit editor insert-before action.
  editorInsertBefore,

  /// Unit editor delete action.
  editorDelete,

  /// Unit editor search action.
  editorSearch,

  /// Unit editor done action.
  editorDone,

  /// Unit editor cancel action.
  editorCancel,

  /// Unit editor bold action.
  editorBold,

  /// Unit editor italic action.
  editorItalic,

  /// Unit editor underline action.
  editorUnderline,

  /// Unit editor foreground color action.
  editorColor,

  /// Unit editor highlight action.
  editorHighlight,

  /// Unit editor clear formatting action.
  editorClearFormatting,

  /// Unit editor category chooser title.
  editorChooseCategoryTitle,

  /// Unit editor jump dialog title.
  editorJumpTitle,

  /// Unit editor jump input label.
  editorJumpLabel,

  /// Unit editor search dialog title.
  editorSearchTitle,

  /// Unit editor search input label.
  editorSearchQuery,

  /// Unit editor search results title.
  editorSearchResults,

  /// Unit editor no matches message.
  editorNoMatches,

  /// Unit editor delete confirmation message.
  editorDeleteConfirm,

  /// Unit editor help title.
  editorHelpTitle,

  /// Unit editor missing categories message.
  editorNoCategories,

  /// Mask name field label.
  maskEditorMaskName,

  /// Direction 1 field label.
  maskEditorDirection1,

  /// Direction 2 field label.
  maskEditorDirection2,

  /// Categories section title.
  maskEditorCategories,

  /// Add category action.
  maskEditorAddCategory,

  /// Delete category action.
  maskEditorDeleteCategory,

  /// Category name field label.
  maskEditorCategoryName,

  /// Fields section title.
  maskEditorFields,

  /// Add field action.
  maskEditorAddField,

  /// Delete field action.
  maskEditorDeleteField,

  /// Field name column label.
  maskEditorFieldName,

  /// Field length column label.
  maskEditorFieldLength,

  /// Equal-group column label.
  maskEditorEqualGroup,

  /// Role direction 1 column label.
  maskEditorRole1,

  /// Role direction 2 column label.
  maskEditorRole2,

  /// Category count helper text.
  maskEditorCategoryCount,

  /// Field count helper text.
  maskEditorFieldCount,

  /// Limit reached text.
  maskEditorLimitReached,

  /// Current deck path label.
  fileStatusDeck,

  /// Current statistics path label.
  fileStatusStats,

  /// No file path placeholder.
  fileStatusUnsaved,

  /// Unit count label.
  fileStatusUnits,

  /// Confirm destructive action title.
  confirmTitle,

  /// Confirm new deck message.
  confirmNewDeck,

  /// Confirm clear units message.
  confirmClearUnits,

  /// Confirm load mask message.
  confirmLoadMask,

  /// Cancel action.
  actionCancel,

  /// Continue action.
  actionContinue,

  /// File operation success title.
  fileOperationDone,

  /// File operation failure title.
  fileOperationFailed,

  /// New deck success message.
  fileNewDeckDone,

  /// Open deck success message.
  fileOpenDeckDone,

  /// Merge deck success message.
  fileMergeDeckDone,

  /// Save deck success message.
  fileSaveDeckDone,

  /// Clear units success message.
  fileClearUnitsDone,

  /// Load mask success message.
  fileLoadMaskDone,

  /// Save mask success message.
  fileSaveMaskDone,

  /// Auto-loaded statistics message.
  fileAutoLoadedStats,

  /// Exit request message.
  fileExitRequested,
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
      LearnAnywhereMessage.desktopHomeTitle: 'Workspace',
      LearnAnywhereMessage.desktopHomeBody: 'Desktop shell ready',
      LearnAnywhereMessage.menuFile: 'File',
      LearnAnywhereMessage.fileNewDeck: 'New deck',
      LearnAnywhereMessage.fileOpenDeck: 'Open deck...',
      LearnAnywhereMessage.fileAddMergeDeck: 'Add/merge deck...',
      LearnAnywhereMessage.fileSave: 'Save',
      LearnAnywhereMessage.fileSaveAs: 'Save As...',
      LearnAnywhereMessage.fileClearUnits: 'Clear units in memory...',
      LearnAnywhereMessage.fileLoadMask: 'Load mask...',
      LearnAnywhereMessage.fileSaveMask: 'Save mask...',
      LearnAnywhereMessage.fileExit: 'Exit',
      LearnAnywhereMessage.menuEdit: 'Edit',
      LearnAnywhereMessage.menuMaskEditor: 'Mask Editor',
      LearnAnywhereMessage.menuLearn: 'Learn',
      LearnAnywhereMessage.menuQueryOptions: 'Query Options',
      LearnAnywhereMessage.menuStatistics: 'Statistics',
      LearnAnywhereMessage.menuLexicon: 'Lexicon',
      LearnAnywhereMessage.menuList: 'List',
      LearnAnywhereMessage.menuHelp: 'Help',
      LearnAnywhereMessage.helpAbout: 'About',
      LearnAnywhereMessage.themeLabel: 'Theme',
      LearnAnywhereMessage.themeSystem: 'System',
      LearnAnywhereMessage.themeLight: 'Light',
      LearnAnywhereMessage.themeDark: 'Dark',
      LearnAnywhereMessage.languageLabel: 'Language',
      LearnAnywhereMessage.languageEnglish: 'English',
      LearnAnywhereMessage.languageGerman: 'German',
      LearnAnywhereMessage.routeFileOperationsTitle: 'File operations',
      LearnAnywhereMessage.routeFileOperationsBody:
          'File commands are ready to be wired in the next Phase 2 steps.',
      LearnAnywhereMessage.routeEditorTitle: 'Editor',
      LearnAnywhereMessage.routeEditorBody:
          'The deck/unit editor will be implemented in Phase 2 Step 4.',
      LearnAnywhereMessage.routeMaskEditorTitle: 'Mask Editor',
      LearnAnywhereMessage.routeMaskEditorBody:
          'The integrated mask editor will be implemented in Phase 2 Step 2.',
      LearnAnywhereMessage.routeLearnTitle: 'Learn',
      LearnAnywhereMessage.routeLearnBody:
          'Practice and super-query sessions will be implemented in Phase 2 Step 5.',
      LearnAnywhereMessage.routeQueryOptionsTitle: 'Query Options',
      LearnAnywhereMessage.routeQueryOptionsBody:
          'Learning option toggles will be implemented with the session screen.',
      LearnAnywhereMessage.routeStatisticsTitle: 'Statistics',
      LearnAnywhereMessage.routeStatisticsBody:
          'Statistics tables and charts will be implemented in Phase 2 Step 6.',
      LearnAnywhereMessage.routeLexiconTitle: 'Lexicon',
      LearnAnywhereMessage.routeLexiconBody:
          'Memory and file-oriented search will be implemented in Phase 2 Step 7.',
      LearnAnywhereMessage.routeListTitle: 'List',
      LearnAnywhereMessage.routeListBody:
          'Printer-friendly lists are deferred to a later version.',
      LearnAnywhereMessage.routeAboutTitle: 'About',
      LearnAnywhereMessage.routeAboutBody:
          'Learn Anywhere is a modern conversion of Lern PC plus.',
      LearnAnywhereMessage.desktopHintBar:
          'F1 Help   F2 Back   F3 Next   F5 Search   F6 Jump   F7 Delete   F8 Insert   F10 Done   Esc Cancel',
      LearnAnywhereMessage.editorEmptyTitle: 'No learning units',
      LearnAnywhereMessage.editorEmptyBody:
          'Insert a unit to begin editing this deck.',
      LearnAnywhereMessage.editorUnitHeader:
          'Unit {index} of {total} - {category}',
      LearnAnywhereMessage.editorFormatting: 'Formatting',
      LearnAnywhereMessage.editorPrevious: 'Previous',
      LearnAnywhereMessage.editorNext: 'Next',
      LearnAnywhereMessage.editorJump: 'Jump',
      LearnAnywhereMessage.editorInsertBefore: 'Insert before',
      LearnAnywhereMessage.editorDelete: 'Delete',
      LearnAnywhereMessage.editorSearch: 'Search',
      LearnAnywhereMessage.editorDone: 'Done',
      LearnAnywhereMessage.editorCancel: 'Cancel',
      LearnAnywhereMessage.editorBold: 'Bold',
      LearnAnywhereMessage.editorItalic: 'Italic',
      LearnAnywhereMessage.editorUnderline: 'Underline',
      LearnAnywhereMessage.editorColor: 'Text color',
      LearnAnywhereMessage.editorHighlight: 'Highlight',
      LearnAnywhereMessage.editorClearFormatting: 'Clear formatting',
      LearnAnywhereMessage.editorChooseCategoryTitle: 'Choose category',
      LearnAnywhereMessage.editorJumpTitle: 'Jump to unit',
      LearnAnywhereMessage.editorJumpLabel: 'Unit number',
      LearnAnywhereMessage.editorSearchTitle: 'Search units',
      LearnAnywhereMessage.editorSearchQuery: 'Search text',
      LearnAnywhereMessage.editorSearchResults: 'Search results',
      LearnAnywhereMessage.editorNoMatches: 'No matching units found.',
      LearnAnywhereMessage.editorDeleteConfirm:
          'Delete the current learning unit?',
      LearnAnywhereMessage.editorHelpTitle: 'Editor shortcuts',
      LearnAnywhereMessage.editorNoCategories:
          'The current mask has no categories.',
      LearnAnywhereMessage.maskEditorMaskName: 'Mask name',
      LearnAnywhereMessage.maskEditorDirection1: 'Direction 1 label',
      LearnAnywhereMessage.maskEditorDirection2: 'Direction 2 label',
      LearnAnywhereMessage.maskEditorCategories: 'Categories',
      LearnAnywhereMessage.maskEditorAddCategory: 'Add category',
      LearnAnywhereMessage.maskEditorDeleteCategory: 'Delete category',
      LearnAnywhereMessage.maskEditorCategoryName: 'Category name',
      LearnAnywhereMessage.maskEditorFields: 'Fields',
      LearnAnywhereMessage.maskEditorAddField: 'Add field',
      LearnAnywhereMessage.maskEditorDeleteField: 'Delete field',
      LearnAnywhereMessage.maskEditorFieldName: 'Field name',
      LearnAnywhereMessage.maskEditorFieldLength: 'Length',
      LearnAnywhereMessage.maskEditorEqualGroup: 'Equal group',
      LearnAnywhereMessage.maskEditorRole1: 'Role dir 1',
      LearnAnywhereMessage.maskEditorRole2: 'Role dir 2',
      LearnAnywhereMessage.maskEditorCategoryCount: 'Categories: {count}/20',
      LearnAnywhereMessage.maskEditorFieldCount: 'Fields: {count}/20',
      LearnAnywhereMessage.maskEditorLimitReached: 'Limit reached',
      LearnAnywhereMessage.fileStatusDeck: 'Deck',
      LearnAnywhereMessage.fileStatusStats: 'Statistics',
      LearnAnywhereMessage.fileStatusUnsaved: 'Unsaved',
      LearnAnywhereMessage.fileStatusUnits: 'Units',
      LearnAnywhereMessage.confirmTitle: 'Please confirm',
      LearnAnywhereMessage.confirmNewDeck:
          'Create a new deck? Current in-memory units will be cleared.',
      LearnAnywhereMessage.confirmClearUnits:
          'Clear all units in memory? This does not delete any file.',
      LearnAnywhereMessage.confirmLoadMask:
          'Load a new mask? Current in-memory units will be cleared.',
      LearnAnywhereMessage.actionCancel: 'Cancel',
      LearnAnywhereMessage.actionContinue: 'Continue',
      LearnAnywhereMessage.fileOperationDone: 'Done',
      LearnAnywhereMessage.fileOperationFailed: 'File operation failed',
      LearnAnywhereMessage.fileNewDeckDone: 'New deck created.',
      LearnAnywhereMessage.fileOpenDeckDone: 'Deck opened.',
      LearnAnywhereMessage.fileMergeDeckDone: 'Deck merged.',
      LearnAnywhereMessage.fileSaveDeckDone: 'Deck saved.',
      LearnAnywhereMessage.fileClearUnitsDone: 'Units cleared.',
      LearnAnywhereMessage.fileLoadMaskDone: 'Mask loaded.',
      LearnAnywhereMessage.fileSaveMaskDone: 'Mask saved.',
      LearnAnywhereMessage.fileAutoLoadedStats: 'Statistics sidecar loaded.',
      LearnAnywhereMessage.fileExitRequested: 'Exit requested.',
    },
    LearnAnywhereLanguage.german: <LearnAnywhereMessage, String>{
      LearnAnywhereMessage.appTitle: 'Learn Anywhere',
      LearnAnywhereMessage.desktopShellReady: 'Desktop-Shell bereit',
      LearnAnywhereMessage.mobileShellReady: 'Mobile-Shell bereit',
      LearnAnywhereMessage.superQueryCompleted:
          'Sie beherrschen nun alle Lerneinheiten im gewaehlten Bereich! Herzlichen Glueckwunsch!',
      LearnAnywhereMessage.desktopHomeTitle: 'Arbeitsbereich',
      LearnAnywhereMessage.desktopHomeBody: 'Desktop-Shell bereit',
      LearnAnywhereMessage.menuFile: 'Datei',
      LearnAnywhereMessage.fileNewDeck: 'Neue Lern-Datei',
      LearnAnywhereMessage.fileOpenDeck: 'Lern-Datei laden...',
      LearnAnywhereMessage.fileAddMergeDeck: 'Lern-Datei hinzuladen...',
      LearnAnywhereMessage.fileSave: 'Speichern',
      LearnAnywhereMessage.fileSaveAs: 'Speichern unter...',
      LearnAnywhereMessage.fileClearUnits:
          'Lerneinheiten im Speicher loeschen...',
      LearnAnywhereMessage.fileLoadMask: 'Neue Masken-Datei laden...',
      LearnAnywhereMessage.fileSaveMask: 'Masken-Datei speichern...',
      LearnAnywhereMessage.fileExit: 'Beenden',
      LearnAnywhereMessage.menuEdit: 'Edit',
      LearnAnywhereMessage.menuMaskEditor: 'Mask Editor',
      LearnAnywhereMessage.menuLearn: 'Lern',
      LearnAnywhereMessage.menuQueryOptions: 'Abfrage',
      LearnAnywhereMessage.menuStatistics: 'Statistik',
      LearnAnywhereMessage.menuLexicon: 'Lexikon',
      LearnAnywhereMessage.menuList: 'Liste',
      LearnAnywhereMessage.menuHelp: 'Hilfe',
      LearnAnywhereMessage.helpAbout: 'Programminfo',
      LearnAnywhereMessage.themeLabel: 'Darstellung',
      LearnAnywhereMessage.themeSystem: 'System',
      LearnAnywhereMessage.themeLight: 'Hell',
      LearnAnywhereMessage.themeDark: 'Dunkel',
      LearnAnywhereMessage.languageLabel: 'Sprache',
      LearnAnywhereMessage.languageEnglish: 'Englisch',
      LearnAnywhereMessage.languageGerman: 'Deutsch',
      LearnAnywhereMessage.routeFileOperationsTitle: 'Dateioperationen',
      LearnAnywhereMessage.routeFileOperationsBody:
          'Die Datei-Befehle werden in den naechsten Phase-2-Schritten verdrahtet.',
      LearnAnywhereMessage.routeEditorTitle: 'Editor',
      LearnAnywhereMessage.routeEditorBody:
          'Der Lerneinheiten-Editor wird in Phase 2 Schritt 4 implementiert.',
      LearnAnywhereMessage.routeMaskEditorTitle: 'Mask Editor',
      LearnAnywhereMessage.routeMaskEditorBody:
          'Der integrierte Masken-Editor wird in Phase 2 Schritt 2 implementiert.',
      LearnAnywhereMessage.routeLearnTitle: 'Lern',
      LearnAnywhereMessage.routeLearnBody:
          'Ueben und Super-Abfrage werden in Phase 2 Schritt 5 implementiert.',
      LearnAnywhereMessage.routeQueryOptionsTitle: 'Abfrage',
      LearnAnywhereMessage.routeQueryOptionsBody:
          'Abfrageoptionen werden mit der Lernsitzung implementiert.',
      LearnAnywhereMessage.routeStatisticsTitle: 'Statistik',
      LearnAnywhereMessage.routeStatisticsBody:
          'Statistiktabellen und Diagramme werden in Phase 2 Schritt 6 implementiert.',
      LearnAnywhereMessage.routeLexiconTitle: 'Lexikon',
      LearnAnywhereMessage.routeLexiconBody:
          'Speicher- und Datei-Suche werden in Phase 2 Schritt 7 implementiert.',
      LearnAnywhereMessage.routeListTitle: 'Liste',
      LearnAnywhereMessage.routeListBody:
          'Druckfreundliche Listen sind fuer eine spaetere Version vorgesehen.',
      LearnAnywhereMessage.routeAboutTitle: 'Programminfo',
      LearnAnywhereMessage.routeAboutBody:
          'Learn Anywhere ist eine moderne Umsetzung von Lern PC plus.',
      LearnAnywhereMessage.desktopHintBar:
          'F1 Hilfe   F2 Zurueck   F3 Weiter   F5 Suche   F6 Sprung   F7 Loeschen   F8 Einfuegen   F10 Fertig   Esc Abbruch',
      LearnAnywhereMessage.editorEmptyTitle: 'Keine Lerneinheiten',
      LearnAnywhereMessage.editorEmptyBody:
          'Fuegen Sie eine Lerneinheit ein, um diese Lern-Datei zu bearbeiten.',
      LearnAnywhereMessage.editorUnitHeader:
          'Einheit {index} von {total} - {category}',
      LearnAnywhereMessage.editorFormatting: 'Formatierung',
      LearnAnywhereMessage.editorPrevious: 'Zurueck',
      LearnAnywhereMessage.editorNext: 'Weiter',
      LearnAnywhereMessage.editorJump: 'Sprung',
      LearnAnywhereMessage.editorInsertBefore: 'Einfuegen',
      LearnAnywhereMessage.editorDelete: 'Loeschen',
      LearnAnywhereMessage.editorSearch: 'Suche',
      LearnAnywhereMessage.editorDone: 'Fertig',
      LearnAnywhereMessage.editorCancel: 'Abbruch',
      LearnAnywhereMessage.editorBold: 'Fett',
      LearnAnywhereMessage.editorItalic: 'Kursiv',
      LearnAnywhereMessage.editorUnderline: 'Unterstrichen',
      LearnAnywhereMessage.editorColor: 'Textfarbe',
      LearnAnywhereMessage.editorHighlight: 'Markierung',
      LearnAnywhereMessage.editorClearFormatting: 'Formatierung loeschen',
      LearnAnywhereMessage.editorChooseCategoryTitle: 'Kategorie waehlen',
      LearnAnywhereMessage.editorJumpTitle: 'Zu Einheit springen',
      LearnAnywhereMessage.editorJumpLabel: 'Einheitsnummer',
      LearnAnywhereMessage.editorSearchTitle: 'Lerneinheiten suchen',
      LearnAnywhereMessage.editorSearchQuery: 'Suchtext',
      LearnAnywhereMessage.editorSearchResults: 'Suchergebnisse',
      LearnAnywhereMessage.editorNoMatches:
          'Keine passenden Lerneinheiten gefunden.',
      LearnAnywhereMessage.editorDeleteConfirm:
          'Aktuelle Lerneinheit loeschen?',
      LearnAnywhereMessage.editorHelpTitle: 'Editor-Tasten',
      LearnAnywhereMessage.editorNoCategories:
          'Die aktuelle Maske hat keine Kategorien.',
      LearnAnywhereMessage.maskEditorMaskName: 'Maskenname',
      LearnAnywhereMessage.maskEditorDirection1: 'Abfrage 1',
      LearnAnywhereMessage.maskEditorDirection2: 'Abfrage 2',
      LearnAnywhereMessage.maskEditorCategories: 'Kategorien',
      LearnAnywhereMessage.maskEditorAddCategory: 'Kategorie hinzufuegen',
      LearnAnywhereMessage.maskEditorDeleteCategory: 'Kategorie loeschen',
      LearnAnywhereMessage.maskEditorCategoryName: 'Kategoriename',
      LearnAnywhereMessage.maskEditorFields: 'Felder',
      LearnAnywhereMessage.maskEditorAddField: 'Feld hinzufuegen',
      LearnAnywhereMessage.maskEditorDeleteField: 'Feld loeschen',
      LearnAnywhereMessage.maskEditorFieldName: 'Feldname',
      LearnAnywhereMessage.maskEditorFieldLength: 'Laenge',
      LearnAnywhereMessage.maskEditorEqualGroup: 'Gleich-Gruppe',
      LearnAnywhereMessage.maskEditorRole1: 'Rolle 1',
      LearnAnywhereMessage.maskEditorRole2: 'Rolle 2',
      LearnAnywhereMessage.maskEditorCategoryCount: 'Kategorien: {count}/20',
      LearnAnywhereMessage.maskEditorFieldCount: 'Felder: {count}/20',
      LearnAnywhereMessage.maskEditorLimitReached: 'Grenze erreicht',
      LearnAnywhereMessage.fileStatusDeck: 'Lern-Datei',
      LearnAnywhereMessage.fileStatusStats: 'Statistik',
      LearnAnywhereMessage.fileStatusUnsaved: 'Ungespeichert',
      LearnAnywhereMessage.fileStatusUnits: 'Lerneinheiten',
      LearnAnywhereMessage.confirmTitle: 'Bitte bestaetigen',
      LearnAnywhereMessage.confirmNewDeck:
          'Neue Lern-Datei erstellen? Aktuelle Lerneinheiten im Speicher werden geloescht.',
      LearnAnywhereMessage.confirmClearUnits:
          'Alle Lerneinheiten im Speicher loeschen? Es wird keine Datei geloescht.',
      LearnAnywhereMessage.confirmLoadMask:
          'Neue Maske laden? Aktuelle Lerneinheiten im Speicher werden geloescht.',
      LearnAnywhereMessage.actionCancel: 'Abbruch',
      LearnAnywhereMessage.actionContinue: 'Weiter',
      LearnAnywhereMessage.fileOperationDone: 'Fertig',
      LearnAnywhereMessage.fileOperationFailed: 'Dateioperation fehlgeschlagen',
      LearnAnywhereMessage.fileNewDeckDone: 'Neue Lern-Datei erstellt.',
      LearnAnywhereMessage.fileOpenDeckDone: 'Lern-Datei geladen.',
      LearnAnywhereMessage.fileMergeDeckDone: 'Lern-Datei hinzugefuegt.',
      LearnAnywhereMessage.fileSaveDeckDone: 'Lern-Datei gespeichert.',
      LearnAnywhereMessage.fileClearUnitsDone: 'Lerneinheiten geloescht.',
      LearnAnywhereMessage.fileLoadMaskDone: 'Maske geladen.',
      LearnAnywhereMessage.fileSaveMaskDone: 'Maske gespeichert.',
      LearnAnywhereMessage.fileAutoLoadedStats: 'Statistik-Datei geladen.',
      LearnAnywhereMessage.fileExitRequested: 'Beenden angefordert.',
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
