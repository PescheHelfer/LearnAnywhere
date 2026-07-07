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

  /// Mobile open deck action.
  mobileOpenDeck,

  /// Mobile no-deck title.
  mobileNoDeckTitle,

  /// Mobile no-deck body.
  mobileNoDeckBody,

  /// Mobile deck loaded status.
  mobileDeckLoaded,

  /// Mobile deck load failure status.
  mobileDeckLoadFailed,

  /// Mobile unit count label.
  mobileUnits,

  /// Mobile next action.
  mobileNext,

  /// Mobile rating prompt.
  mobileRatePrompt,

  /// Super-query completion message.
  superQueryCompleted,

  /// Home route title.
  desktopHomeTitle,

  /// Home screen: no file loaded message.
  homeNoFileLoaded,

  /// Home screen: mask name label.
  homeMaskName,

  /// Home screen: last loaded deck path label.
  homeLastDeck,

  /// Home screen: last loaded mask path label.
  homeLastMask,

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

  /// Load mask command.
  fileLoadMask,

  /// Save mask command.
  fileSaveMask,

  /// Save mask as command.
  fileSaveMaskAs,

  /// Exit command.
  fileExit,

  /// Edit menu label.
  menuEdit,

  /// Edit submenu: unit editor entry.
  menuEditUnitEditor,

  /// Edit submenu: search unit entry.
  menuEditSearchUnit,

  /// Edit submenu: jump to number entry.
  menuEditJumpToNumber,

  /// Mask editor menu label.
  menuMaskEditor,

  /// Learn menu label.
  menuLearn,

  /// Statistics menu label.
  menuStatistics,

  /// Lexicon menu label.
  menuLexicon,

  /// Help menu label.
  menuHelp,

  /// About command.
  helpAbout,

  /// Options menu label.
  menuOptions,

  /// Options menu: advanced learning options item.
  menuOptionsAdvancedLearning,

  /// Options menu: auto-load statistics toggle.
  menuOptionsAutoLoadStats,

  /// Options menu: auto-save statistics toggle.
  menuOptionsAutoSaveStats,

  /// Theme control label.
  themeLabel,

  /// System theme option.
  themeSystem,

  /// Light theme option.
  themeLight,

  /// Dark theme option.
  themeDark,

  /// Dark Blue theme option.
  themeDarkBlue,

  /// Light Blue theme option.
  themeLightBlue,

  /// Language control label.
  languageLabel,

  /// English language option.
  languageEnglish,

  /// German language option.
  languageGerman,

  /// File operations route title.
  routeFileOperationsTitle,

  /// Mask editor route title.
  routeMaskEditorTitle,

  /// About page title.
  routeAboutTitle,

  /// About page introduction.
  aboutIntro,

  /// About page original program credit.
  aboutOriginalCredit,

  /// About page conversion credit.
  aboutConversionCredit,

  /// About page version history heading.
  aboutVersionHistory,

  /// About page version history entry for 0.1.0.
  aboutVersion010,

  /// About page version history entry for 0.2.0.
  aboutVersion020,

  /// About page version history entry for 0.3.0.
  aboutVersion030,

  /// About page version history entry for 0.3.1.
  aboutVersion031,

  /// Desktop bottom shortcut hint bar text.
  desktopHintBar,

  /// Unit editor empty-state title.
  editorEmptyTitle,

  /// Unit editor empty-state body.
  editorEmptyBody,

  /// Unit editor unit header.
  editorUnitHeader,

  /// Unit editor previous action.
  editorPrevious,

  /// Unit editor next action.
  editorNext,

  /// Unit editor jump action.
  editorJump,

  /// Unit editor insert-before action.
  editorInsertBefore,

  /// Unit editor empty-deck insert action.
  editorInsertUnit,

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

  /// Default (inherited) text color option label.
  colorDefault,

  /// No highlight option label.
  colorNone,

  /// Red color label.
  colorRed,

  /// Blue color label.
  colorBlue,

  /// Green color label.
  colorGreen,

  /// Orange color label.
  colorOrange,

  /// Purple color label.
  colorPurple,

  /// Black color label.
  colorBlack,

  /// White color label.
  colorWhite,

  /// Yellow color label.
  colorYellow,

  /// Cyan color label.
  colorCyan,

  /// Lime color label.
  colorLime,

  /// Pink color label.
  colorPink,

  /// Amber color label.
  colorAmber,

  /// Teal color label.
  colorTeal,

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

  /// Learn empty-state title.
  learnEmptyTitle,

  /// Learn empty-state body.
  learnEmptyBody,

  /// Learn setup title.
  learnSetupTitle,

  /// Learn direction selection label.
  learnDirection,

  /// Learn both directions option.
  learnBothDirections,

  /// Learn start range label.
  learnRangeStart,

  /// Learn end range label.
  learnRangeEnd,

  /// Learn mode label.
  learnMode,

  /// Endless mode label.
  learnModePractice,

  /// Drill mode label.
  learnModeSuperQuery,

  /// Once-through mode label.
  learnModeOnceThrough,

  /// Shuffle units option.
  learnShuffleUnits,

  /// Super status threshold label.
  learnSuperThreshold,

  /// Start or resume session action.
  learnStartSession,

  /// Prompt section label.
  learnPrompt,

  /// Your answer section label.
  learnYourAnswer,

  /// Solution section label.
  learnSolution,

  /// Remarks section label.
  learnRemarks,

  /// Reveal answer action.
  learnReveal,

  /// Check answer action.
  learnCheckAnswer,

  /// Continue session action.
  learnContinue,

  /// Correct answer message.
  learnCorrectMessage,

  /// Wrong answer message.
  learnWrongMessage,

  /// Rating correct option.
  learnRatingCorrect,

  /// Rating wrong option.
  learnRatingWrong,

  /// Rating actually correct option.
  learnRatingActuallyCorrect,

  /// Rating actually wrong option.
  learnRatingActuallyWrong,

  /// Rating no-count option.
  learnRatingNoCount,

  /// Think-only knew-it option.
  learnRatingKnewIt,

  /// Think-only did-not-know option.
  learnRatingDidNotKnow,

  /// Live mastered count label.
  learnLiveMastered,

  /// Live remaining count label.
  learnLiveRemaining,

  /// Live accuracy label.
  learnLiveAccuracy,

  /// Live elapsed-time label.
  learnLiveTime,

  /// Current unit header.
  learnUnitHeader,

  /// Completion extend action.
  learnExtendSession,

  /// Confirm cancel learn session.
  learnCancelConfirm,

  /// "Evaluate as:" label before the rating buttons.
  learnEvaluateAs,

  /// Learning options title.
  queryOptionsTitle,

  /// Wrong input correctable option.
  queryOptionWrongInputCorrectable,

  /// Complete input required option.
  queryOptionCompleteInputRequired,

  /// Case sensitive option.
  queryOptionCaseSensitive,

  /// Accent sensitive option.
  queryOptionAccentSensitive,

  /// Show clock option.
  queryOptionShowClock,

  /// Time limit option.
  queryOptionTimeLimit,

  /// Require typed answers option.
  queryOptionWithAnswerInput,

  /// Minimum-attempts guard option.
  queryOptionMinimumAttemptsGuard,

  /// Minimum attempts value option.
  queryOptionMinimumAttempts,

  /// Wrong-answer ceiling option.
  queryOptionWrongAnswerCeiling,

  /// Wrong-answer ceiling value option.
  queryOptionWrongAnswerCeilingValue,

  /// Statistics page title.
  statisticsTitle,

  /// Statistics keep-practicing tab.
  statisticsKeepPracticing,

  /// Statistics detailed tab.
  statisticsDetailed,

  /// Statistics chart tab.
  statisticsChart,

  /// Statistics direction view label.
  statisticsDirectionView,

  /// Combined direction view label.
  statisticsCombined,

  /// Direction 1 statistics view label.
  statisticsDirection1,

  /// Direction 2 statistics view label.
  statisticsDirection2,

  /// Statistics total units label.
  statisticsTotalUnits,

  /// Statistics practiced units label.
  statisticsQueriedUnits,

  /// Statistics bucket column label.
  statisticsBucket,

  /// Statistics count column label.
  statisticsCount,

  /// Statistics percentage of all column label.
  statisticsPercentAll,

  /// Statistics percentage of practiced column label.
  statisticsPercentQueried,

  /// Statistics unit column label.
  statisticsUnit,

  /// Statistics category column label.
  statisticsCategory,

  /// Statistics hit rate column label.
  statisticsHitRate,

  /// Statistics hit-rate range column label (Detailed view).
  statisticsRange,

  /// Statistics question preview column label (Keep practicing).
  statisticsQuestion,

  /// Statistics answer preview column label (Keep practicing).
  statisticsAnswer,

  /// Practiced-of-total summary line (Detailed view). Placeholders:
  /// {practiced}, {total}, {percent}.
  statisticsPracticedSummary,

  /// Bucket filter section label (Keep practicing).
  statisticsFilterBuckets,

  /// Minimum hit-rate filter field label (Keep practicing).
  statisticsFilterMin,

  /// Maximum hit-rate filter field label (Keep practicing).
  statisticsFilterMax,

  /// Select all visible statistics units action.
  statisticsSelectAll,

  /// Clear selected statistics units action.
  statisticsClearSelection,

  /// Save selected units action.
  statisticsSaveSelected,

  /// Load statistics action.
  statisticsLoad,

  /// Save statistics action.
  statisticsSave,

  /// Save statistics as action.
  fileSaveStatsAs,

  /// Clear statistics action.
  statisticsClear,

  /// Statistics loaded status.
  statisticsLoaded,

  /// Statistics saved status.
  statisticsSaved,

  /// Statistics cleared status.
  statisticsCleared,

  /// Selected units saved status.
  statisticsSelectedSaved,

  /// No selected units message.
  statisticsNoSelection,

  /// Perfect hit-rate bucket.
  statisticsBucketPerfect,

  /// Good hit-rate bucket.
  statisticsBucketGood,

  /// Fair hit-rate bucket.
  statisticsBucketFair,

  /// Unsure hit-rate bucket.
  statisticsBucketUnsure,

  /// Very unsure hit-rate bucket.
  statisticsBucketVeryUnsure,

  /// Never known hit-rate bucket.
  statisticsBucketNeverKnown,

  /// Not yet practiced hit-rate bucket.
  statisticsBucketNotYetQueried,

  /// Lexicon page title.
  lexiconTitle,

  /// Lexicon search text label.
  lexiconSearchText,

  /// Lexicon category scope label.
  lexiconCategoryScope,

  /// Any category option.
  lexiconAnyCategory,

  /// Memory search action.
  lexiconMemorySearch,

  /// File search action.
  lexiconFileSearch,

  /// File search pattern label.
  lexiconFilePattern,

  /// Display only file search mode.
  lexiconDisplayOnly,

  /// Load found units mode.
  lexiconLoadFoundUnits,

  /// Load found units warning.
  lexiconLoadWarning,

  /// Lexicon result count label.
  lexiconResults,

  /// Lexicon no results message.
  lexiconNoResults,

  /// Lexicon source file label.
  lexiconSourceFile,

  /// Lexicon matched fields label.
  lexiconMatchedFields,

  /// Lexicon load results action.
  lexiconLoadResults,

  /// Lexicon loaded results status.
  lexiconLoadedResults,

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

  /// Mask editor: move a category or field up one position.
  maskEditorMoveUp,

  /// Mask editor: move a category or field down one position.
  maskEditorMoveDown,

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

  /// Prompt to create a linked `.inf` when a deck has none.
  confirmCreateLinkedMask,

  /// Status shown after the linked `.inf` mask is saved.
  fileStatusMaskSaved,

  /// Status shown when compatible sibling decks were updated on mask save.
  fileStatusDecksUpdated,

  /// Title of the breaking-propagation dialog.
  propagationBreakingTitle,

  /// Intro line of the breaking-propagation dialog.
  propagationBreakingBody,

  /// Fork action: save the `.inf` as a brand-new mask.
  actionForkMask,

  /// Force action: apply the mask despite data loss.
  actionForceUpdate,

  /// Edit-menu command: sync this mask to copies in other folders.
  menuEditUpdateMaskCopies,

  /// Title of the cross-directory mask-sync review dialog.
  maskSyncTitle,

  /// Sync status: already identical to the current mask.
  maskSyncStatusUpToDate,

  /// Sync status: an older/compatible copy that will be updated.
  maskSyncStatusWillUpdate,

  /// Sync status: a deck that would lose data (excluded).
  maskSyncStatusWouldBreak,

  /// Sync status: differs from the current mask at the same revision.
  maskSyncStatusDiffers,

  /// Button that applies the selected updates.
  maskSyncApply,

  /// Status shown when no copies of the mask were found under the folder.
  maskSyncNoneFound,

  /// Status shown after a sync run, with a `{count}` placeholder.
  maskSyncDone,

  /// Cancel action.
  actionCancel,

  /// Continue action.
  actionContinue,

  /// Clear action.
  actionClear,

  /// Close action.
  actionClose,

  /// Affirmative action (Yes).
  actionYes,

  /// Negative action (No).
  actionNo,

  /// Confirm auto-save overwrite of an existing `.sta`. Placeholder: {name}.
  confirmAutoSaveOverwrite,

  /// Snackbar shown when a stored deck path no longer exists. Placeholder: {path}.
  fileNotFound,

  /// Confirm clear statistics message.
  confirmClearStatistics,

  /// Confirm exit message.
  confirmExit,

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

  /// Native file-picker filter caption for `.vok` deck files.
  filePickerDeckType,

  /// Native file-picker filter caption for `.inf` mask files.
  filePickerMaskType,

  /// Native file-picker filter caption for `.sta` statistics files.
  filePickerStatsType,

  /// Confirm discarding editor changes (unit editor Cancel/Esc).
  confirmDiscardEdits,

  /// Error: a save was requested without a file path.
  errorNoFilePath,

  /// Error: merge refused because the deck belongs to a different mask.
  errorMergeMaskMismatch,

  /// Error: merge refused because converting the incoming units to the
  /// current mask would lose data.
  errorMergeWouldLoseData,

  /// Error: the Lexicon search directory does not exist. Placeholder: {detail}.
  errorSearchDirectoryMissing,

  /// Error: no Lexicon search pattern was provided.
  errorNoSearchPattern,

  /// Error: the Lexicon search pattern lacks a file mask.
  errorPatternNeedsFileMask,

  /// Error: found units belong to different masks and cannot be loaded together.
  lexiconLoadMaskMismatch,

  /// Error: loading found units would lose data when updating them to the
  /// newest mask revision among the source files.
  lexiconLoadWouldLoseData,

  /// Breaking mask change: category deleted. Placeholders: {category}, {count}.
  maskBreakCategoryDeleted,

  /// Breaking mask change: field deleted. Placeholders: {field}, {category},
  /// {count}.
  maskBreakFieldDeleted,

  /// Breaking mask change: field shortened below stored data. Placeholders:
  /// {field}, {category}, {length}, {count}.
  maskBreakFieldTooShort,

  /// Seed name for a mask created in this app (user data, locale-seeded once).
  defaultMaskName,

  /// Seed label for direction 1 of a new mask.
  defaultDirection1Label,

  /// Seed label for direction 2 of a new mask.
  defaultDirection2Label,

  /// Seed name for a new category. Placeholder: {n} (1-based position).
  defaultCategoryName,

  /// Seed name for the question field of a new mask.
  defaultFieldQuestion,

  /// Seed name for the answer field of a new mask.
  defaultFieldAnswer,

  /// Seed name for the remark field of a new mask.
  defaultFieldRemark,
}

/// Localized message catalog for framework-independent strings.
final class LearnAnywhereCatalog {
  const LearnAnywhereCatalog._();

  static const Map<LearnAnywhereLanguage, Map<LearnAnywhereMessage, String>>
  _messages = <LearnAnywhereLanguage, Map<LearnAnywhereMessage, String>>{
    LearnAnywhereLanguage.english: <LearnAnywhereMessage, String>{
      LearnAnywhereMessage.appTitle: 'Learn Anywhere',
      LearnAnywhereMessage.mobileOpenDeck: 'Open deck',
      LearnAnywhereMessage.mobileNoDeckTitle: 'No deck loaded',
      LearnAnywhereMessage.mobileNoDeckBody:
          'Open a .vok deck to start a read-only learning session.',
      LearnAnywhereMessage.mobileDeckLoaded: 'Deck loaded.',
      LearnAnywhereMessage.mobileDeckLoadFailed: 'Deck could not be opened.',
      LearnAnywhereMessage.mobileUnits: 'Units',
      LearnAnywhereMessage.mobileNext: 'Next',
      LearnAnywhereMessage.mobileRatePrompt: 'How did it go?',
      LearnAnywhereMessage.superQueryCompleted:
          'You have now mastered all learning units in the selected range. Congratulations!',
      LearnAnywhereMessage.desktopHomeTitle: 'Workspace',
      LearnAnywhereMessage.homeNoFileLoaded: 'No file loaded',
      LearnAnywhereMessage.homeMaskName: 'Mask',
      LearnAnywhereMessage.homeLastDeck: 'Last deck',
      LearnAnywhereMessage.homeLastMask: 'Last mask',
      LearnAnywhereMessage.menuFile: '&File', // top-bar F
      LearnAnywhereMessage.fileNewDeck: '&Clear units from memory...', // C
      LearnAnywhereMessage.fileOpenDeck: 'Load &deck...', // D
      LearnAnywhereMessage.fileAddMergeDeck: '&Add/merge deck...', // A
      LearnAnywhereMessage.fileSave: '&Save deck', // S
      LearnAnywhereMessage.fileSaveAs: 'Sa&ve deck as...', // V
      LearnAnywhereMessage.fileLoadMask: '&Load mask...', // L
      LearnAnywhereMessage.fileSaveMask: 'Save &mask', // M
      LearnAnywhereMessage.fileSaveMaskAs: 'Save mas&k as...', // K
      LearnAnywhereMessage.fileExit: '&Exit...', // E
      LearnAnywhereMessage.menuEdit: '&Edit', // top-bar E
      LearnAnywhereMessage.menuEditUnitEditor: '&Unit editor', // U
      LearnAnywhereMessage.menuEditSearchUnit: '&Search unit...', // S
      LearnAnywhereMessage.menuEditJumpToNumber: '&Jump to number...', // J
      LearnAnywhereMessage.menuMaskEditor: '&Mask Editor', // top-bar M
      LearnAnywhereMessage.menuLearn: '&Learn', // top-bar L
      LearnAnywhereMessage.menuStatistics: '&Statistics', // top-bar S
      LearnAnywhereMessage.menuLexicon: 'Le&xicon', // top-bar X
      LearnAnywhereMessage.menuHelp: '&Help', // top-bar H
      LearnAnywhereMessage.helpAbout: '&About', // A
      LearnAnywhereMessage.menuOptions: '&Options', // top-bar O
      LearnAnywhereMessage.menuOptionsAdvancedLearning: '&Advanced Learning Options', // A
      LearnAnywhereMessage.menuOptionsAutoLoadStats:
          'Auto-l&oad statistics', // O
      LearnAnywhereMessage.menuOptionsAutoSaveStats:
          'Auto-sa&ve statistics', // V
      LearnAnywhereMessage.themeLabel: '&Theme', // T
      LearnAnywhereMessage.themeSystem: '&System', // S
      LearnAnywhereMessage.themeLight: 'Lig&ht', // H
      LearnAnywhereMessage.themeDark: '&Dark', // D
      LearnAnywhereMessage.themeDarkBlue: 'Dark &Blue', // B
      LearnAnywhereMessage.themeLightBlue: 'Light Bl&ue', // U
      LearnAnywhereMessage.languageLabel: '&Language', // L
      LearnAnywhereMessage.languageEnglish: '&English', // E
      LearnAnywhereMessage.languageGerman: '&German', // G
      LearnAnywhereMessage.routeFileOperationsTitle: 'File operations',
      LearnAnywhereMessage.routeMaskEditorTitle: 'Mask Editor',
      LearnAnywhereMessage.routeAboutTitle: 'About',
      LearnAnywhereMessage.aboutIntro:
          'Learn Anywhere is a modern conversion of Lern PC plus.',
      LearnAnywhereMessage.aboutOriginalCredit:
          'Lern PC plus — Universal-Lernprogramm, © 1990/92 by Ulrich Veigel Softwareservice (UVS)',
      LearnAnywhereMessage.aboutConversionCredit:
          'Modern conversion: SbitFire Software',
      LearnAnywhereMessage.aboutVersionHistory: 'Version history',
      LearnAnywhereMessage.aboutVersion010:
          '0.1.0 – Phase 2 desktop foundation: file operations, editor, '
          'learning, statistics, lexicon, and program info.',
      LearnAnywhereMessage.aboutVersion020:
          '0.2.0 – Compact grid-based editor and practice screen.',
      LearnAnywhereMessage.aboutVersion030:
          '0.3.0 – Statistics, mask editor, and menu accessibility improvements.',
      LearnAnywhereMessage.aboutVersion031:
          '0.3.1 – Code audit fixes and clean-ups.',
      LearnAnywhereMessage.desktopHintBar:
          'F1 Help   F2 Back   F3 Next   F5 Search   F6 Jump   F7 Delete   F8 Insert   F10 Done   Esc Cancel',
      LearnAnywhereMessage.editorEmptyTitle: 'No learning units',
      LearnAnywhereMessage.editorEmptyBody:
          'Insert a unit to begin editing this deck.',
      LearnAnywhereMessage.editorUnitHeader:
          'Unit {index} of {total} - {category}',
      LearnAnywhereMessage.editorPrevious: 'Previous',
      LearnAnywhereMessage.editorNext: 'Next',
      LearnAnywhereMessage.editorJump: 'Jump',
      LearnAnywhereMessage.editorInsertBefore: 'Insert before',
      LearnAnywhereMessage.editorInsertUnit: 'Insert unit',
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
      LearnAnywhereMessage.colorDefault: 'Default',
      LearnAnywhereMessage.colorNone: 'None',
      LearnAnywhereMessage.colorRed: 'Red',
      LearnAnywhereMessage.colorBlue: 'Blue',
      LearnAnywhereMessage.colorGreen: 'Green',
      LearnAnywhereMessage.colorOrange: 'Orange',
      LearnAnywhereMessage.colorPurple: 'Purple',
      LearnAnywhereMessage.colorBlack: 'Black',
      LearnAnywhereMessage.colorWhite: 'White',
      LearnAnywhereMessage.colorYellow: 'Yellow',
      LearnAnywhereMessage.colorCyan: 'Cyan',
      LearnAnywhereMessage.colorLime: 'Lime',
      LearnAnywhereMessage.colorPink: 'Pink',
      LearnAnywhereMessage.colorAmber: 'Amber',
      LearnAnywhereMessage.colorTeal: 'Teal',
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
      LearnAnywhereMessage.learnEmptyTitle: 'No learning units',
      LearnAnywhereMessage.learnEmptyBody:
          'Create or open a deck with learning units before starting a session.',
      LearnAnywhereMessage.learnSetupTitle: 'Practice setup',
      LearnAnywhereMessage.learnDirection: 'Direction',
      LearnAnywhereMessage.learnBothDirections: 'Both',
      LearnAnywhereMessage.learnRangeStart: 'Start unit',
      LearnAnywhereMessage.learnRangeEnd: 'End unit',
      LearnAnywhereMessage.learnMode: 'Mode',
      LearnAnywhereMessage.learnModePractice: 'Endless mode',
      LearnAnywhereMessage.learnModeSuperQuery: 'Drill mode',
      LearnAnywhereMessage.learnModeOnceThrough: 'Once through',
      LearnAnywhereMessage.learnShuffleUnits: 'Shuffle units',
      LearnAnywhereMessage.learnSuperThreshold: 'Super status threshold (%)',
      LearnAnywhereMessage.learnStartSession: 'Start session',
      LearnAnywhereMessage.learnPrompt: 'Prompt',
      LearnAnywhereMessage.learnYourAnswer: 'Your answer',
      LearnAnywhereMessage.learnSolution: 'Solution',
      LearnAnywhereMessage.learnRemarks: 'Remarks',
      LearnAnywhereMessage.learnReveal: 'Reveal',
      LearnAnywhereMessage.learnCheckAnswer: 'Check',
      LearnAnywhereMessage.learnContinue: 'Continue',
      LearnAnywhereMessage.learnCorrectMessage:
          'Your answer is correct. Congratulations!',
      LearnAnywhereMessage.learnWrongMessage:
          'The answer is unfortunately wrong.',
      LearnAnywhereMessage.learnRatingCorrect: 'Correct',
      LearnAnywhereMessage.learnRatingWrong: 'Wrong',
      LearnAnywhereMessage.learnRatingActuallyCorrect: 'Actually correct',
      LearnAnywhereMessage.learnRatingActuallyWrong: 'Actually wrong',
      LearnAnywhereMessage.learnRatingNoCount: 'No count',
      LearnAnywhereMessage.learnRatingKnewIt: 'Knew it',
      LearnAnywhereMessage.learnRatingDidNotKnow: "Didn't know",
      LearnAnywhereMessage.learnLiveMastered: 'Mastered',
      LearnAnywhereMessage.learnLiveRemaining: 'Remaining',
      LearnAnywhereMessage.learnLiveAccuracy: 'Accuracy',
      LearnAnywhereMessage.learnLiveTime: 'Time',
      LearnAnywhereMessage.learnUnitHeader:
          'Unit {index} of {total} - {category} - {direction}',
      LearnAnywhereMessage.learnExtendSession: 'Extend session',
      LearnAnywhereMessage.learnCancelConfirm: 'Cancel the current session?',
      LearnAnywhereMessage.learnEvaluateAs: 'Evaluate as:',
      LearnAnywhereMessage.queryOptionsTitle: 'Advanced Learning Options',
      LearnAnywhereMessage.queryOptionWrongInputCorrectable:
          'Wrong input correctable',
      LearnAnywhereMessage.queryOptionCompleteInputRequired:
          'Complete input required',
      LearnAnywhereMessage.queryOptionCaseSensitive: 'Case sensitive',
      LearnAnywhereMessage.queryOptionAccentSensitive: 'Accent sensitive',
      LearnAnywhereMessage.queryOptionShowClock: 'Show clock',
      LearnAnywhereMessage.queryOptionTimeLimit: 'Time limit (seconds)',
      LearnAnywhereMessage.queryOptionWithAnswerInput: 'Require typed answers',
      LearnAnywhereMessage.queryOptionMinimumAttemptsGuard:
          'Minimum-attempts guard',
      LearnAnywhereMessage.queryOptionMinimumAttempts: 'Minimum attempts',
      LearnAnywhereMessage.queryOptionWrongAnswerCeiling:
          'Wrong-answer ceiling',
      LearnAnywhereMessage.queryOptionWrongAnswerCeilingValue:
          'Wrong-answer ceiling value',
      LearnAnywhereMessage.statisticsTitle: 'Statistics',
      LearnAnywhereMessage.statisticsKeepPracticing: 'Keep practicing',
      LearnAnywhereMessage.statisticsDetailed: 'Detailed',
      LearnAnywhereMessage.statisticsChart: 'Chart',
      LearnAnywhereMessage.statisticsDirectionView: 'View',
      LearnAnywhereMessage.statisticsCombined: 'Combined',
      LearnAnywhereMessage.statisticsDirection1: 'Direction 1',
      LearnAnywhereMessage.statisticsDirection2: 'Direction 2',
      LearnAnywhereMessage.statisticsTotalUnits: 'Total units',
      LearnAnywhereMessage.statisticsQueriedUnits: 'Practiced units',
      LearnAnywhereMessage.statisticsBucket: 'Bucket',
      LearnAnywhereMessage.statisticsCount: 'Count',
      LearnAnywhereMessage.statisticsPercentAll: '% of all',
      LearnAnywhereMessage.statisticsPercentQueried: '% of practiced',
      LearnAnywhereMessage.statisticsUnit: 'Unit',
      LearnAnywhereMessage.statisticsCategory: 'Category',
      LearnAnywhereMessage.statisticsHitRate: 'Hit rate',
      LearnAnywhereMessage.statisticsRange: 'Range',
      LearnAnywhereMessage.statisticsQuestion: 'Question',
      LearnAnywhereMessage.statisticsAnswer: 'Answer',
      LearnAnywhereMessage.statisticsPracticedSummary:
          'Practiced: {practiced} of {total} units ({percent}%)',
      LearnAnywhereMessage.statisticsFilterBuckets: 'Show buckets',
      LearnAnywhereMessage.statisticsFilterMin: 'Min %',
      LearnAnywhereMessage.statisticsFilterMax: 'Max %',
      LearnAnywhereMessage.statisticsSelectAll: 'Select visible',
      LearnAnywhereMessage.statisticsClearSelection: 'Clear selection',
      LearnAnywhereMessage.statisticsSaveSelected: 'Save selected units',
      LearnAnywhereMessage.statisticsLoad: 'Load stats...',
      LearnAnywhereMessage.statisticsSave: 'Save stats',
      LearnAnywhereMessage.fileSaveStatsAs: 'Save stats as...',
      LearnAnywhereMessage.statisticsClear: 'Clear stats...',
      LearnAnywhereMessage.statisticsLoaded: 'Statistics loaded.',
      LearnAnywhereMessage.statisticsSaved: 'Statistics saved.',
      LearnAnywhereMessage.statisticsCleared: 'Statistics cleared.',
      LearnAnywhereMessage.statisticsSelectedSaved: 'Selected units saved.',
      LearnAnywhereMessage.statisticsNoSelection: 'No units selected.',
      LearnAnywhereMessage.statisticsBucketPerfect: 'Perfect',
      LearnAnywhereMessage.statisticsBucketGood: 'Good',
      LearnAnywhereMessage.statisticsBucketFair: 'Fair',
      LearnAnywhereMessage.statisticsBucketUnsure: 'Unsure',
      LearnAnywhereMessage.statisticsBucketVeryUnsure: 'Very unsure',
      LearnAnywhereMessage.statisticsBucketNeverKnown: 'Never known',
      LearnAnywhereMessage.statisticsBucketNotYetQueried: 'Not yet practiced',
      LearnAnywhereMessage.lexiconTitle: 'Lexicon',
      LearnAnywhereMessage.lexiconSearchText: 'Search text',
      LearnAnywhereMessage.lexiconCategoryScope: 'Category',
      LearnAnywhereMessage.lexiconAnyCategory: 'Any category',
      LearnAnywhereMessage.lexiconMemorySearch: 'Search memory',
      LearnAnywhereMessage.lexiconFileSearch: 'Search files',
      LearnAnywhereMessage.lexiconFilePattern: 'File mask',
      LearnAnywhereMessage.lexiconDisplayOnly: 'Display only',
      LearnAnywhereMessage.lexiconLoadFoundUnits: 'Load found units',
      LearnAnywhereMessage.lexiconLoadWarning:
          'Load found units? Current in-memory units will be discarded.',
      LearnAnywhereMessage.lexiconResults: 'Results',
      LearnAnywhereMessage.lexiconNoResults: 'No matches found.',
      LearnAnywhereMessage.lexiconSourceFile: 'Source file',
      LearnAnywhereMessage.lexiconMatchedFields: 'Matched fields',
      LearnAnywhereMessage.lexiconLoadResults: 'Load results',
      LearnAnywhereMessage.lexiconLoadedResults:
          'Found units loaded into memory.',
      LearnAnywhereMessage.maskEditorMaskName: 'Mask name',
      LearnAnywhereMessage.maskEditorDirection1: 'Direction 1 label',
      LearnAnywhereMessage.maskEditorDirection2: 'Direction 2 label',
      LearnAnywhereMessage.maskEditorCategories: 'Categories',
      LearnAnywhereMessage.maskEditorAddCategory: 'Add category',
      LearnAnywhereMessage.maskEditorDeleteCategory: 'Delete category',
      LearnAnywhereMessage.maskEditorMoveUp: 'Move up',
      LearnAnywhereMessage.maskEditorMoveDown: 'Move down',
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
          'Clear units from memory? No file will be deleted.',
      LearnAnywhereMessage.confirmLoadMask:
          'Load a new mask? Current in-memory units will be cleared.',
      LearnAnywhereMessage.confirmCreateLinkedMask:
          'No mask file found for this deck. Create one from the '
          "deck's embedded mask?",
      LearnAnywhereMessage.fileStatusMaskSaved: 'Mask saved',
      LearnAnywhereMessage.fileStatusDecksUpdated: 'Updated {count} deck(s)',
      LearnAnywhereMessage.propagationBreakingTitle: 'Some decks would lose data',
      LearnAnywhereMessage.propagationBreakingBody:
          'Applying this mask change would break the following deck(s). Save the '
          'mask as a new mask (leaving these decks on the old one), cancel, or '
          'force the update and lose the listed data.',
      LearnAnywhereMessage.actionForkMask: 'Save as new mask',
      LearnAnywhereMessage.actionForceUpdate: 'Force update (lose data)',
      LearnAnywhereMessage.menuEditUpdateMaskCopies:
          'U&pdate other copies of this mask...', // p

      LearnAnywhereMessage.maskSyncTitle: 'Update other copies of this mask',
      LearnAnywhereMessage.maskSyncStatusUpToDate: 'Up to date',
      LearnAnywhereMessage.maskSyncStatusWillUpdate: 'Will update',
      LearnAnywhereMessage.maskSyncStatusWouldBreak: 'Would break',
      LearnAnywhereMessage.maskSyncStatusDiffers: 'Differs (same revision)',
      LearnAnywhereMessage.maskSyncApply: 'Update selected',
      LearnAnywhereMessage.maskSyncNoneFound:
          'No other copies of this mask were found',
      LearnAnywhereMessage.maskSyncDone: 'Synced {count} copy(ies)',
      LearnAnywhereMessage.actionCancel: 'Cancel',
      LearnAnywhereMessage.actionContinue: 'Continue',
      LearnAnywhereMessage.actionClear: 'Clear',
      LearnAnywhereMessage.actionClose: 'Close',
      LearnAnywhereMessage.actionYes: 'Yes',
      LearnAnywhereMessage.actionNo: 'No',
      LearnAnywhereMessage.confirmAutoSaveOverwrite: 'Overwrite {name}?',
      LearnAnywhereMessage.fileNotFound: 'File not found: {path}',
      LearnAnywhereMessage.confirmClearStatistics:
          'Clear all statistics for the current deck?',
      LearnAnywhereMessage.confirmExit: 'Exit Learn Anywhere?',
      LearnAnywhereMessage.fileOperationFailed: 'File operation failed',
      LearnAnywhereMessage.fileNewDeckDone: 'New deck created.',
      LearnAnywhereMessage.fileOpenDeckDone: 'Deck loaded.',
      LearnAnywhereMessage.fileMergeDeckDone: 'Deck merged.',
      LearnAnywhereMessage.fileSaveDeckDone: 'Deck saved.',
      LearnAnywhereMessage.fileLoadMaskDone: 'Mask loaded.',
      LearnAnywhereMessage.fileSaveMaskDone: 'Mask saved.',
      LearnAnywhereMessage.filePickerDeckType: 'Vocabulary decks (*.vok)',
      LearnAnywhereMessage.filePickerMaskType: 'Mask files (*.inf)',
      LearnAnywhereMessage.filePickerStatsType: 'Statistics files (*.sta)',
      LearnAnywhereMessage.confirmDiscardEdits:
          'Discard the changes made in the editor?',
      LearnAnywhereMessage.errorNoFilePath: 'No file path was provided.',
      LearnAnywhereMessage.errorMergeMaskMismatch:
          'Cannot merge: the selected deck belongs to a different mask.',
      LearnAnywhereMessage.errorMergeWouldLoseData:
          'Cannot merge: updating the added units to the current mask would '
          'lose data.',
      LearnAnywhereMessage.errorSearchDirectoryMissing:
          'Search directory does not exist: {detail}',
      LearnAnywhereMessage.errorNoSearchPattern:
          'No search pattern was provided.',
      LearnAnywhereMessage.errorPatternNeedsFileMask:
          'The search pattern must include a file mask (e.g. *.vok).',
      LearnAnywhereMessage.lexiconLoadMaskMismatch:
          'The found units belong to different masks and cannot be loaded '
          'together.',
      LearnAnywhereMessage.lexiconLoadWouldLoseData:
          'Loading the found units would lose data when updating them to the '
          'newest mask revision.',
      LearnAnywhereMessage.maskBreakCategoryDeleted:
          'Deleting category "{category}" would orphan {count} unit(s).',
      LearnAnywhereMessage.maskBreakFieldDeleted:
          'Deleting field "{field}" in category "{category}" would drop data '
          'in {count} unit(s).',
      LearnAnywhereMessage.maskBreakFieldTooShort:
          'Shortening field "{field}" in category "{category}" to {length} '
          'would truncate {count} unit(s).',
      LearnAnywhereMessage.defaultMaskName: 'Untitled mask',
      LearnAnywhereMessage.defaultDirection1Label: 'Direction 1',
      LearnAnywhereMessage.defaultDirection2Label: 'Direction 2',
      LearnAnywhereMessage.defaultCategoryName: 'Category {n}',
      LearnAnywhereMessage.defaultFieldQuestion: 'Question',
      LearnAnywhereMessage.defaultFieldAnswer: 'Answer',
      LearnAnywhereMessage.defaultFieldRemark: 'Remark',
    },
    LearnAnywhereLanguage.german: <LearnAnywhereMessage, String>{
      LearnAnywhereMessage.appTitle: 'Learn Anywhere',
      LearnAnywhereMessage.mobileOpenDeck: 'Lern-Datei laden',
      LearnAnywhereMessage.mobileNoDeckTitle: 'Keine Lern-Datei geladen',
      LearnAnywhereMessage.mobileNoDeckBody:
          'Laden Sie eine .vok-Lern-Datei, um eine reine Lern-Sitzung zu starten.',
      LearnAnywhereMessage.mobileDeckLoaded: 'Lern-Datei geladen.',
      LearnAnywhereMessage.mobileDeckLoadFailed:
          'Lern-Datei konnte nicht geöffnet werden.',
      LearnAnywhereMessage.mobileUnits: 'Einheiten',
      LearnAnywhereMessage.mobileNext: 'Weiter',
      LearnAnywhereMessage.mobileRatePrompt: 'Wie lief es?',
      LearnAnywhereMessage.superQueryCompleted:
          'Sie beherrschen nun alle Lerneinheiten im gewählten Bereich! Herzlichen Glückwunsch!',
      LearnAnywhereMessage.desktopHomeTitle: 'Arbeitsbereich',
      LearnAnywhereMessage.homeNoFileLoaded: 'Keine Datei geladen',
      LearnAnywhereMessage.homeMaskName: 'Maske',
      LearnAnywhereMessage.homeLastDeck: 'Letzte Lerneinheiten',
      LearnAnywhereMessage.homeLastMask: 'Letzte Masken-Datei',
      LearnAnywhereMessage.menuFile: '&Datei', // top-bar D
      LearnAnywhereMessage.fileNewDeck:
          'Lerneinheiten &im Speicher löschen...', // I
      LearnAnywhereMessage.fileOpenDeck: '&Lerneinheiten laden...', // L
      LearnAnywhereMessage.fileAddMergeDeck:
          'Lerneinheiten &hinzuladen...', // H
      LearnAnywhereMessage.fileSave: 'Lerneinheiten &speichern', // S
      LearnAnywhereMessage.fileSaveAs:
          'Lerneinheiten speichern &unter...', // U
      LearnAnywhereMessage.fileLoadMask: 'Neue &Masken-Datei laden...', // M
      LearnAnywhereMessage.fileSaveMask: 'Masken-&Datei speichern', // D
      LearnAnywhereMessage.fileSaveMaskAs:
          'Mas&ken-Datei speichern unter...', // K
      LearnAnywhereMessage.fileExit: '&Beenden...', // B
      LearnAnywhereMessage.menuEdit: '&Edit', // top-bar E
      LearnAnywhereMessage.menuEditUnitEditor: '&Eingabe-Maske', // E
      LearnAnywhereMessage.menuEditSearchUnit:
          '&Suchen einer Lerneinheit...', // S
      LearnAnywhereMessage.menuEditJumpToNumber:
          'Springe zu bestimmter &Nummer...', // N (avoids S conflict with Suchen)
      LearnAnywhereMessage.menuMaskEditor: '&Mask Editor', // top-bar M
      LearnAnywhereMessage.menuLearn: '&Lern', // top-bar L
      LearnAnywhereMessage.menuStatistics: '&Statistik', // top-bar S
      LearnAnywhereMessage.menuLexicon: 'Le&xikon', // top-bar X
      LearnAnywhereMessage.menuHelp: '&Hilfe', // top-bar H
      LearnAnywhereMessage.helpAbout: '&Programminfo', // P
      LearnAnywhereMessage.menuOptions: '&Optionen', // top-bar O
      LearnAnywhereMessage.menuOptionsAdvancedLearning: '&Erweiterte Lernoptionen', // E
      LearnAnywhereMessage.menuOptionsAutoLoadStats:
          'Statistiken automatisch &laden', // L
      LearnAnywhereMessage.menuOptionsAutoSaveStats:
          'Statistiken au&tomatisch speichern', // T
      LearnAnywhereMessage.themeLabel: '&Darstellung', // D
      LearnAnywhereMessage.themeSystem: 'S&ystem', // Y (avoids S = Sprache label)
      LearnAnywhereMessage.themeLight: '&Hell', // H
      LearnAnywhereMessage.themeDark: '&Dunkel', // D
      LearnAnywhereMessage.themeDarkBlue: 'Dunkel&blau', // B
      LearnAnywhereMessage.themeLightBlue: 'Hellbla&u', // U
      LearnAnywhereMessage.languageLabel: '&Sprache', // S
      LearnAnywhereMessage.languageEnglish: 'En&glisch', // G (avoids E = Erweiterte)
      LearnAnywhereMessage.languageGerman: 'De&utsch', // U
      LearnAnywhereMessage.routeFileOperationsTitle: 'Dateioperationen',
      LearnAnywhereMessage.routeMaskEditorTitle: 'Mask Editor',
      LearnAnywhereMessage.routeAboutTitle: 'Programminfo',
      LearnAnywhereMessage.aboutIntro:
          'Learn Anywhere ist eine moderne Umsetzung von Lern PC plus.',
      LearnAnywhereMessage.aboutOriginalCredit:
          'Lern PC plus — Universal-Lernprogramm, © 1990/92 by Ulrich Veigel Softwareservice (UVS)',
      LearnAnywhereMessage.aboutConversionCredit:
          'Moderne Umsetzung: SbitFire Software',
      LearnAnywhereMessage.aboutVersionHistory: 'Versionsgeschichte',
      LearnAnywhereMessage.aboutVersion010:
          '0.1.0 – Phase-2-Desktop-Grundlage: Dateioperationen, Editor, Lernen, '
          'Statistik, Lexikon und Programminfo.',
      LearnAnywhereMessage.aboutVersion020:
          '0.2.0 – Kompakter rasterbasierter Editor und Übungsbildschirm.',
      LearnAnywhereMessage.aboutVersion030:
          '0.3.0 – Verbesserungen bei Statistik, Maskeneditor und Menü-Zugänglichkeit.',
      LearnAnywhereMessage.aboutVersion031:
          '0.3.1 – Korrekturen und Bereinigungen im Rahmen des Code-Audits.',
      LearnAnywhereMessage.desktopHintBar:
          'F1 Hilfe   F2 Zurück   F3 Weiter   F5 Suche   F6 Springen   F7 Löschen   F8 Einfügen   F10 Fertig   Esc Abbruch',
      LearnAnywhereMessage.editorEmptyTitle: 'Keine Lerneinheiten',
      LearnAnywhereMessage.editorEmptyBody:
          'Fügen Sie eine Lerneinheit ein, um diese Lern-Datei zu bearbeiten.',
      LearnAnywhereMessage.editorUnitHeader:
          'Einheit {index} von {total} - {category}',
      LearnAnywhereMessage.editorPrevious: 'Zurück',
      LearnAnywhereMessage.editorNext: 'Weiter',
      LearnAnywhereMessage.editorJump: 'Springen',
      LearnAnywhereMessage.editorInsertBefore: 'Einfügen',
      LearnAnywhereMessage.editorInsertUnit: 'Einfügen',
      LearnAnywhereMessage.editorDelete: 'Löschen',
      LearnAnywhereMessage.editorSearch: 'Suche',
      LearnAnywhereMessage.editorDone: 'Fertig',
      LearnAnywhereMessage.editorCancel: 'Abbruch',
      LearnAnywhereMessage.editorBold: 'Fett',
      LearnAnywhereMessage.editorItalic: 'Kursiv',
      LearnAnywhereMessage.editorUnderline: 'Unterstrichen',
      LearnAnywhereMessage.editorColor: 'Textfarbe',
      LearnAnywhereMessage.editorHighlight: 'Markierung',
      LearnAnywhereMessage.editorClearFormatting: 'Formatierung löschen',
      LearnAnywhereMessage.colorDefault: 'Standard',
      LearnAnywhereMessage.colorNone: 'Keine',
      LearnAnywhereMessage.colorRed: 'Rot',
      LearnAnywhereMessage.colorBlue: 'Blau',
      LearnAnywhereMessage.colorGreen: 'Grün',
      LearnAnywhereMessage.colorOrange: 'Orange',
      LearnAnywhereMessage.colorPurple: 'Violett',
      LearnAnywhereMessage.colorBlack: 'Schwarz',
      LearnAnywhereMessage.colorWhite: 'Weiß',
      LearnAnywhereMessage.colorYellow: 'Gelb',
      LearnAnywhereMessage.colorCyan: 'Cyan',
      LearnAnywhereMessage.colorLime: 'Hellgrün',
      LearnAnywhereMessage.colorPink: 'Rosa',
      LearnAnywhereMessage.colorAmber: 'Bernstein',
      LearnAnywhereMessage.colorTeal: 'Blaugrün',
      LearnAnywhereMessage.editorChooseCategoryTitle: 'Kategorie wählen',
      LearnAnywhereMessage.editorJumpTitle: 'Zu Einheit springen',
      LearnAnywhereMessage.editorJumpLabel: 'Einheitsnummer',
      LearnAnywhereMessage.editorSearchTitle: 'Lerneinheiten suchen',
      LearnAnywhereMessage.editorSearchQuery: 'Suchtext',
      LearnAnywhereMessage.editorSearchResults: 'Suchergebnisse',
      LearnAnywhereMessage.editorNoMatches:
          'Keine passenden Lerneinheiten gefunden.',
      LearnAnywhereMessage.editorDeleteConfirm:
          'Aktuelle Lerneinheit löschen?',
      LearnAnywhereMessage.editorHelpTitle: 'Editor-Tasten',
      LearnAnywhereMessage.editorNoCategories:
          'Die aktuelle Maske hat keine Kategorien.',
      LearnAnywhereMessage.learnEmptyTitle: 'Keine Lerneinheiten',
      LearnAnywhereMessage.learnEmptyBody:
          'Erstellen oder laden Sie eine Lern-Datei mit Lerneinheiten, bevor Sie eine Sitzung starten.',
      LearnAnywhereMessage.learnSetupTitle: 'Übung einrichten',
      LearnAnywhereMessage.learnDirection: 'Richtung',
      LearnAnywhereMessage.learnBothDirections: 'Beide',
      LearnAnywhereMessage.learnRangeStart: 'Erste Einheit',
      LearnAnywhereMessage.learnRangeEnd: 'Letzte Einheit',
      LearnAnywhereMessage.learnMode: 'Modus',
      LearnAnywhereMessage.learnModePractice: 'Endlos-Modus',
      LearnAnywhereMessage.learnModeSuperQuery: 'Drill-Modus',
      LearnAnywhereMessage.learnModeOnceThrough: 'Einmal durchgehen',
      LearnAnywhereMessage.learnShuffleUnits: 'Einheiten mischen',
      LearnAnywhereMessage.learnSuperThreshold: 'Super-Status (%)',
      LearnAnywhereMessage.learnStartSession: 'Sitzung starten',
      LearnAnywhereMessage.learnPrompt: 'Frage',
      LearnAnywhereMessage.learnYourAnswer: 'Ihre Antwort',
      LearnAnywhereMessage.learnSolution: 'Lösung',
      LearnAnywhereMessage.learnRemarks: 'Bemerkungen',
      LearnAnywhereMessage.learnReveal: 'Anzeigen',
      LearnAnywhereMessage.learnCheckAnswer: 'Prüfen',
      LearnAnywhereMessage.learnContinue: 'Weiter',
      LearnAnywhereMessage.learnCorrectMessage:
          'Die Eingabe ist richtig! Glückwunsch!',
      LearnAnywhereMessage.learnWrongMessage:
          'Die Eingabe ist leider falsch! Schade!',
      LearnAnywhereMessage.learnRatingCorrect: 'Richtig',
      LearnAnywhereMessage.learnRatingWrong: 'Falsch',
      LearnAnywhereMessage.learnRatingActuallyCorrect: 'Eigentlich richtig',
      LearnAnywhereMessage.learnRatingActuallyWrong: 'Eigentlich falsch',
      LearnAnywhereMessage.learnRatingNoCount: 'Nicht zählen',
      LearnAnywhereMessage.learnRatingKnewIt: 'Gewusst',
      LearnAnywhereMessage.learnRatingDidNotKnow: 'Nicht gewusst',
      LearnAnywhereMessage.learnLiveMastered: 'Beherrscht',
      LearnAnywhereMessage.learnLiveRemaining: 'Übrig',
      LearnAnywhereMessage.learnLiveAccuracy: 'Treffer',
      LearnAnywhereMessage.learnLiveTime: 'Zeit',
      LearnAnywhereMessage.learnUnitHeader:
          'Einheit {index} von {total} - {category} - {direction}',
      LearnAnywhereMessage.learnExtendSession: 'Sitzung erweitern',
      LearnAnywhereMessage.learnCancelConfirm: 'Aktuelle Sitzung abbrechen?',
      LearnAnywhereMessage.learnEvaluateAs: 'Bewerten als:',
      LearnAnywhereMessage.queryOptionsTitle: 'Erweiterte Lernoptionen',
      LearnAnywhereMessage.queryOptionWrongInputCorrectable:
          'Falsche Eingabe korrigierbar',
      LearnAnywhereMessage.queryOptionCompleteInputRequired:
          'Vollständige Eingabe erforderlich',
      LearnAnywhereMessage.queryOptionCaseSensitive:
          'Groß-/Kleinschreibung beachten',
      LearnAnywhereMessage.queryOptionAccentSensitive: 'Akzente beachten',
      LearnAnywhereMessage.queryOptionShowClock: 'Uhr anzeigen',
      LearnAnywhereMessage.queryOptionTimeLimit: 'Zeitlimit (Sekunden)',
      LearnAnywhereMessage.queryOptionWithAnswerInput:
          'Mit Eingabe der Antwort',
      LearnAnywhereMessage.queryOptionMinimumAttemptsGuard:
          'Mindestabfragen beachten',
      LearnAnywhereMessage.queryOptionMinimumAttempts: 'Mindestabfragen',
      LearnAnywhereMessage.queryOptionWrongAnswerCeiling:
          'Falsch-Antworten begrenzen',
      LearnAnywhereMessage.queryOptionWrongAnswerCeilingValue:
          'Grenze für falsche Antworten',
      LearnAnywhereMessage.statisticsTitle: 'Statistik',
      LearnAnywhereMessage.statisticsKeepPracticing: 'Weiter üben',
      LearnAnywhereMessage.statisticsDetailed: 'Detailliert',
      LearnAnywhereMessage.statisticsChart: 'Diagramm',
      LearnAnywhereMessage.statisticsDirectionView: 'Ansicht',
      LearnAnywhereMessage.statisticsCombined: 'Kombiniert',
      LearnAnywhereMessage.statisticsDirection1: 'Richtung 1',
      LearnAnywhereMessage.statisticsDirection2: 'Richtung 2',
      LearnAnywhereMessage.statisticsTotalUnits: 'Lerneinheiten gesamt',
      LearnAnywhereMessage.statisticsQueriedUnits: 'Abgefragte Einheiten',
      LearnAnywhereMessage.statisticsBucket: 'Bereich',
      LearnAnywhereMessage.statisticsCount: 'Anzahl',
      LearnAnywhereMessage.statisticsPercentAll: '% von allen',
      LearnAnywhereMessage.statisticsPercentQueried: '% der abgefragten',
      LearnAnywhereMessage.statisticsUnit: 'Einheit',
      LearnAnywhereMessage.statisticsCategory: 'Kategorie',
      LearnAnywhereMessage.statisticsHitRate: 'Trefferquote',
      LearnAnywhereMessage.statisticsRange: 'Bereich',
      LearnAnywhereMessage.statisticsQuestion: 'Frage',
      LearnAnywhereMessage.statisticsAnswer: 'Antwort',
      LearnAnywhereMessage.statisticsPracticedSummary:
          'Geübt: {practiced} von {total} Einheiten ({percent}%)',
      LearnAnywhereMessage.statisticsFilterBuckets: 'Kategorien anzeigen',
      LearnAnywhereMessage.statisticsFilterMin: 'Min %',
      LearnAnywhereMessage.statisticsFilterMax: 'Max %',
      LearnAnywhereMessage.statisticsSelectAll: 'Sichtbare auswählen',
      LearnAnywhereMessage.statisticsClearSelection: 'Auswahl leeren',
      LearnAnywhereMessage.statisticsSaveSelected:
          'Ausgewählte Einheiten speichern',
      LearnAnywhereMessage.statisticsLoad: 'Statistik laden...',
      LearnAnywhereMessage.statisticsSave: 'Statistik speichern',
      LearnAnywhereMessage.fileSaveStatsAs: 'Statistik speichern unter...',
      LearnAnywhereMessage.statisticsClear: 'Statistik löschen...',
      LearnAnywhereMessage.statisticsLoaded: 'Statistik geladen.',
      LearnAnywhereMessage.statisticsSaved: 'Statistik gespeichert.',
      LearnAnywhereMessage.statisticsCleared: 'Statistik gelöscht.',
      LearnAnywhereMessage.statisticsSelectedSaved:
          'Ausgewählte Einheiten gespeichert.',
      LearnAnywhereMessage.statisticsNoSelection:
          'Keine Einheiten ausgewählt.',
      LearnAnywhereMessage.statisticsBucketPerfect: 'Perfekt',
      LearnAnywhereMessage.statisticsBucketGood: 'Gut',
      LearnAnywhereMessage.statisticsBucketFair: 'Mittel',
      LearnAnywhereMessage.statisticsBucketUnsure: 'Unsicher',
      LearnAnywhereMessage.statisticsBucketVeryUnsure: 'Sehr unsicher',
      LearnAnywhereMessage.statisticsBucketNeverKnown: 'Nie gewusst',
      LearnAnywhereMessage.statisticsBucketNotYetQueried:
          'Noch nicht abgefragt',
      LearnAnywhereMessage.lexiconTitle: 'Lexikon',
      LearnAnywhereMessage.lexiconSearchText: 'Suchtext',
      LearnAnywhereMessage.lexiconCategoryScope: 'Kategorie',
      LearnAnywhereMessage.lexiconAnyCategory: 'Alle Kategorien',
      LearnAnywhereMessage.lexiconMemorySearch: 'Speicher durchsuchen',
      LearnAnywhereMessage.lexiconFileSearch: 'Dateien durchsuchen',
      LearnAnywhereMessage.lexiconFilePattern: 'Dateimaske',
      LearnAnywhereMessage.lexiconDisplayOnly: 'Nur anzeigen',
      LearnAnywhereMessage.lexiconLoadFoundUnits: 'Gefundene Einheiten laden',
      LearnAnywhereMessage.lexiconLoadWarning:
          'Gefundene Einheiten laden? Aktuelle Lerneinheiten im Speicher werden verworfen.',
      LearnAnywhereMessage.lexiconResults: 'Ergebnisse',
      LearnAnywhereMessage.lexiconNoResults: 'Keine Treffer gefunden.',
      LearnAnywhereMessage.lexiconSourceFile: 'Quelldatei',
      LearnAnywhereMessage.lexiconMatchedFields: 'Trefferfelder',
      LearnAnywhereMessage.lexiconLoadResults: 'Treffer laden',
      LearnAnywhereMessage.lexiconLoadedResults:
          'Gefundene Einheiten in den Speicher geladen.',
      LearnAnywhereMessage.maskEditorMaskName: 'Maskenname',
      LearnAnywhereMessage.maskEditorDirection1: 'Abfrage 1',
      LearnAnywhereMessage.maskEditorDirection2: 'Abfrage 2',
      LearnAnywhereMessage.maskEditorCategories: 'Kategorien',
      LearnAnywhereMessage.maskEditorAddCategory: 'Kategorie hinzufügen',
      LearnAnywhereMessage.maskEditorDeleteCategory: 'Kategorie löschen',
      LearnAnywhereMessage.maskEditorMoveUp: 'Nach oben',
      LearnAnywhereMessage.maskEditorMoveDown: 'Nach unten',
      LearnAnywhereMessage.maskEditorCategoryName: 'Kategoriename',
      LearnAnywhereMessage.maskEditorFields: 'Felder',
      LearnAnywhereMessage.maskEditorAddField: 'Feld hinzufügen',
      LearnAnywhereMessage.maskEditorDeleteField: 'Feld löschen',
      LearnAnywhereMessage.maskEditorFieldName: 'Feldname',
      LearnAnywhereMessage.maskEditorFieldLength: 'Länge',
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
      LearnAnywhereMessage.confirmTitle: 'Bitte bestätigen',
      LearnAnywhereMessage.confirmNewDeck:
          'Lerneinheiten im Speicher löschen? Es wird keine Datei gelöscht.',
      LearnAnywhereMessage.confirmLoadMask:
          'Neue Maske laden? Aktuelle Lerneinheiten im Speicher werden gelöscht.',
      LearnAnywhereMessage.confirmCreateLinkedMask:
          'Keine Maskendatei für dieses Deck gefunden. Aus der eingebetteten '
          'Maske des Decks eine erstellen?',
      LearnAnywhereMessage.fileStatusMaskSaved: 'Maske gespeichert',
      LearnAnywhereMessage.fileStatusDecksUpdated:
          '{count} Deck(s) aktualisiert',
      LearnAnywhereMessage.propagationBreakingTitle:
          'Einige Decks würden Daten verlieren',
      LearnAnywhereMessage.propagationBreakingBody:
          'Diese Maskenänderung würde die folgenden Decks beschädigen. Maske als '
          'neue Maske speichern (die Decks bleiben auf der alten), abbrechen '
          'oder Aktualisierung erzwingen und die aufgeführten Daten verlieren.',
      LearnAnywhereMessage.actionForkMask: 'Als neue Maske speichern',
      LearnAnywhereMessage.actionForceUpdate: 'Erzwingen (Datenverlust)',
      LearnAnywhereMessage.menuEditUpdateMaskCopies:
          '&Andere Kopien dieser Maske aktualisieren...', // A

      LearnAnywhereMessage.maskSyncTitle:
          'Andere Kopien dieser Maske aktualisieren',
      LearnAnywhereMessage.maskSyncStatusUpToDate: 'Aktuell',
      LearnAnywhereMessage.maskSyncStatusWillUpdate: 'Wird aktualisiert',
      LearnAnywhereMessage.maskSyncStatusWouldBreak: 'Würde beschädigen',
      LearnAnywhereMessage.maskSyncStatusDiffers: 'Abweichend (gleiche Revision)',
      LearnAnywhereMessage.maskSyncApply: 'Auswahl aktualisieren',
      LearnAnywhereMessage.maskSyncNoneFound:
          'Keine weiteren Kopien dieser Maske gefunden',
      LearnAnywhereMessage.maskSyncDone: '{count} Kopie(n) synchronisiert',
      LearnAnywhereMessage.actionCancel: 'Abbruch',
      LearnAnywhereMessage.actionContinue: 'Weiter',
      LearnAnywhereMessage.actionClear: 'Löschen',
      LearnAnywhereMessage.actionClose: 'Schließen',
      LearnAnywhereMessage.actionYes: 'Ja',
      LearnAnywhereMessage.actionNo: 'Nein',
      LearnAnywhereMessage.confirmAutoSaveOverwrite: '{name} überschreiben?',
      LearnAnywhereMessage.fileNotFound: 'Datei nicht gefunden: {path}',
      LearnAnywhereMessage.confirmClearStatistics:
          'Alle Statistiken für das aktuelle Vokabular löschen?',
      LearnAnywhereMessage.confirmExit: 'Learn Anywhere beenden?',
      LearnAnywhereMessage.fileOperationFailed: 'Dateioperation fehlgeschlagen',
      LearnAnywhereMessage.fileNewDeckDone: 'Neue Lern-Datei erstellt.',
      LearnAnywhereMessage.fileOpenDeckDone: 'Lern-Datei geladen.',
      LearnAnywhereMessage.fileMergeDeckDone: 'Lern-Datei hinzugefügt.',
      LearnAnywhereMessage.fileSaveDeckDone: 'Lern-Datei gespeichert.',
      LearnAnywhereMessage.fileLoadMaskDone: 'Maske geladen.',
      LearnAnywhereMessage.fileSaveMaskDone: 'Maske gespeichert.',
      LearnAnywhereMessage.filePickerDeckType: 'Lern-Dateien (*.vok)',
      LearnAnywhereMessage.filePickerMaskType: 'Masken-Dateien (*.inf)',
      LearnAnywhereMessage.filePickerStatsType: 'Statistik-Dateien (*.sta)',
      LearnAnywhereMessage.confirmDiscardEdits:
          'Die im Editor gemachten Änderungen verwerfen?',
      LearnAnywhereMessage.errorNoFilePath:
          'Es wurde kein Dateipfad angegeben.',
      LearnAnywhereMessage.errorMergeMaskMismatch:
          'Hinzuladen nicht möglich: Die gewählte Lern-Datei gehört zu einer '
          'anderen Maske.',
      LearnAnywhereMessage.errorMergeWouldLoseData:
          'Hinzuladen nicht möglich: Beim Angleichen an die aktuelle Maske '
          'würden Daten verloren gehen.',
      LearnAnywhereMessage.errorSearchDirectoryMissing:
          'Suchordner existiert nicht: {detail}',
      LearnAnywhereMessage.errorNoSearchPattern:
          'Es wurde kein Suchmuster angegeben.',
      LearnAnywhereMessage.errorPatternNeedsFileMask:
          'Das Suchmuster muss eine Dateimaske enthalten (z. B. *.vok).',
      LearnAnywhereMessage.lexiconLoadMaskMismatch:
          'Die gefundenen Lerneinheiten gehören zu unterschiedlichen Masken '
          'und können nicht gemeinsam geladen werden.',
      LearnAnywhereMessage.lexiconLoadWouldLoseData:
          'Beim Angleichen an die neueste Masken-Revision würden Daten '
          'verloren gehen; die gefundenen Lerneinheiten können nicht geladen '
          'werden.',
      LearnAnywhereMessage.maskBreakCategoryDeleted:
          'Das Löschen der Kategorie "{category}" würde {count} '
          'Lerneinheit(en) verwaisen lassen.',
      LearnAnywhereMessage.maskBreakFieldDeleted:
          'Das Löschen des Feldes "{field}" in Kategorie "{category}" würde '
          'Daten in {count} Lerneinheit(en) löschen.',
      LearnAnywhereMessage.maskBreakFieldTooShort:
          'Das Kürzen des Feldes "{field}" in Kategorie "{category}" auf '
          '{length} würde Daten in {count} Lerneinheit(en) abschneiden.',
      LearnAnywhereMessage.defaultMaskName: 'Unbenannte Maske',
      LearnAnywhereMessage.defaultDirection1Label: 'Richtung 1',
      LearnAnywhereMessage.defaultDirection2Label: 'Richtung 2',
      LearnAnywhereMessage.defaultCategoryName: 'Kategorie {n}',
      LearnAnywhereMessage.defaultFieldQuestion: 'Frage',
      LearnAnywhereMessage.defaultFieldAnswer: 'Antwort',
      LearnAnywhereMessage.defaultFieldRemark: 'Bemerkung',
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
