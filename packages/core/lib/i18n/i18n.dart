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

  /// Mobile library screen title (app home).
  mobileLibraryTitle,

  /// Mobile library empty-state title.
  mobileLibraryEmptyTitle,

  /// Mobile library empty-state body.
  mobileLibraryEmptyBody,

  /// Mobile import-decks action.
  mobileImportDecks,

  /// Mobile import success status, with a `{count}` placeholder.
  mobileImportSuccess,

  /// Mobile import failure status.
  mobileImportFailed,

  /// Mobile delete-deck action.
  mobileDeleteDeck,

  /// Mobile delete-deck confirmation dialog title.
  mobileDeleteDeckConfirmTitle,

  /// Mobile delete-deck confirmation dialog body.
  mobileDeleteDeckConfirmBody,

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

  /// Learn submenu: open the full practice setup screen.
  menuLearnPracticeSetup,

  /// Learn submenu: start straight away with the last-used settings.
  menuLearnWithLastSettings,

  /// Learn submenu: return to the session already running.
  menuLearnContinue,

  /// Statistics menu label.
  menuStatistics,

  /// Lexicon menu label.
  menuLexicon,

  /// Help menu label.
  menuHelp,

  /// Help submenu: opens the bundled user guide.
  helpUserGuide,

  /// About command.
  helpAbout,

  /// User guide route title.
  routeHelpTitle,

  /// User guide: heading above the chapter list.
  helpContents,

  /// User guide: placeholder text of the search field.
  helpSearchHint,

  /// User guide: shown when a search matched nothing.
  helpNoResults,

  /// User guide: number of search matches. Placeholder: {count}.
  helpMatchCount,

  /// User guide: shown on a chapter that has no translation for the active
  /// language and is therefore displayed in English.
  helpEnglishFallback,

  /// User guide: title of the dialog offering a non-chapter link for copying.
  helpLinkTitle,

  /// User guide: copies the link shown in the link dialog.
  helpCopyLink,

  /// User guide: shown when the bundled guide could not be read at all.
  helpUnavailable,

  /// Options menu label.
  menuOptions,

  /// Options menu: advanced learning options item.
  menuOptionsAdvancedLearning,

  /// Options menu: Statistics submenu label.
  menuOptionsStatistics,

  /// Options ▸ Statistics: auto-load statistics toggle.
  menuOptionsAutoLoadStats,

  /// Options ▸ Statistics: auto-save statistics toggle.
  menuOptionsAutoSaveStats,

  /// Options ▸ Statistics: opens the retention-count prompt. Placeholder:
  /// {count}.
  menuOptionsKeepStatistics,

  /// Title of the retention-count prompt dialog.
  keepStatisticsTitle,

  /// Label of the number field in the retention-count prompt dialog.
  keepStatisticsLabel,

  /// Explanation shown under the retention-count field: 0 keeps every file.
  keepStatisticsHint,

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

  /// About page version history entry for 0.4.0.
  aboutVersion040,

  /// About page version history entry for 0.4.1.
  aboutVersion041,

  /// About page version history entry for 0.5.0.
  aboutVersion050,

  /// About page version history entry for 0.6.0.
  aboutVersion060,

  /// About page version history entry for 0.6.1.
  aboutVersion061,

  /// About page bundled-font credit.
  aboutFontCredit,

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

  /// Start-range explanation shown as a tooltip.
  learnRangeStartTooltip,

  /// Learn end range label.
  learnRangeEnd,

  /// End-range explanation shown as a tooltip.
  learnRangeEndTooltip,

  /// Option that fixes the unit range to the whole deck. Placeholder: {count}.
  learnUseAllUnits,

  /// Title of the prompt shown when a session starts in a different mode than
  /// the one the current statistics were recorded in.
  sessionModeSwitchTitle,

  /// Body shown when switching from Level Learning to a drill-style mode.
  sessionModeSwitchToDrillBody,

  /// Body shown when switching from a drill-style mode to Level Learning.
  sessionModeSwitchToLevelBody,

  /// Warning appended to both mode-switch bodies: starting fresh deletes the
  /// existing statistics.
  sessionModeSwitchFreshWarning,

  /// Mode-switch action: keep the existing statistics and continue.
  sessionModeSwitchKeep,

  /// Mode-switch action: seed Level-Learning levels from the existing
  /// statistics and continue.
  sessionModeSwitchSeed,

  /// Mode-switch action: clear all statistics and start over.
  sessionModeSwitchFresh,

  /// Learn mode label.
  learnMode,

  /// Endless mode label.
  learnModePractice,

  /// Drill mode label.
  learnModeSuperQuery,

  /// Once-through mode label.
  learnModeOnceThrough,

  /// Level-Learning mode label.
  learnModeLevelLearning,

  /// Entry-level cap label (Level Learning setup).
  learnEntryLevel,

  /// Entry-level cap helper tooltip.
  learnEntryLevelHint,

  /// Suffix appended to the no-cap entry-level option.
  learnEntryLevelNoCapSuffix,

  /// Shuffle units option.
  learnShuffleUnits,

  /// Mastery threshold label.
  learnMasteryThreshold,

  /// Mastery threshold explanation shown as a tooltip.
  learnMasteryThresholdTooltip,

  /// Start or resume session action.
  learnStartSession,

  /// Prompt section label.
  learnPrompt,

  /// Your answer section label.
  learnYourAnswer,

  /// Solution section label.
  learnSolution,

  /// Corrected-answer (diff highlighted) section label.
  learnCorrection,

  /// "Switch" hint prefix on the answer-view toggle button (before "F9").
  learnSwitchHint,

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

  /// Near-miss ("Almost") answer message.
  learnAlmostMessage,

  /// Rating correct option.
  learnRatingCorrect,

  /// Rating wrong option.
  learnRatingWrong,

  /// Rating actually correct option.
  learnRatingActuallyCorrect,

  /// Rating "close enough" option for a near-miss (records as correct).
  learnRatingCloseEnough,

  /// Rating actually wrong option.
  learnRatingActuallyWrong,

  /// Rating no-count option.
  learnRatingNoCount,

  /// Think-only knew-it option.
  learnRatingKnewIt,

  /// Think-only did-not-know option.
  learnRatingDidNotKnow,

  /// Live attempts count label.
  learnLiveAttempts,

  /// Live mastered count label.
  learnLiveMastered,

  /// Live remaining count label.
  learnLiveRemaining,

  /// Live accuracy label.
  learnLiveAccuracy,

  /// Label for the current unit's own accuracy, appended to the session
  /// header (non-Level modes).
  learnUnitAccuracy,

  /// Live elapsed-time label.
  learnLiveTime,

  /// Current unit header.
  learnUnitHeader,

  /// Completion extend action.
  learnExtendSession,

  /// "Evaluate as:" label before the rating buttons.
  learnEvaluateAs,

  /// Level-Learning "more help" (raise support) action.
  learnMoreHelp,

  /// Level-Learning "less help" (lower support) action.
  learnLessHelp,

  /// Level-Learning level-3 "hide the solution and type it" action.
  learnHideAndType,

  /// Level-name customization panel title.
  learnLevelNamesTitle,

  /// Level-name English column label.
  learnLevelNamesEnglish,

  /// Level-name German column label.
  learnLevelNamesGerman,

  /// Apply the space-launch level-name preset action.
  learnLevelNamesApplyPreset,

  /// Reset level names to defaults action.
  learnLevelNamesReset,

  /// Level-name panel ordering + length helper text.
  learnLevelNamesOrderHint,

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

  /// "Accept near-misses as Almost" option.
  queryOptionAlmostEnabled,

  /// "Almost" similarity threshold (percent) option.
  queryOptionAlmostThreshold,

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

  /// Statistics unit-list tab (per-unit attempts/accuracy table).
  statisticsUnitList,

  /// Statistics overview tab (bucket summary).
  statisticsOverview,

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

  /// Total attempts label (Detailed view), summed over in-scope units.
  statisticsTotalAttempts,

  /// Correct attempts label (Detailed view).
  statisticsCorrectAttempts,

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

  /// Statistics attempts column label (Keep practicing).
  statisticsAttempts,

  /// Statistics accuracy column label (Keep practicing).
  statisticsAccuracy,

  /// Statistics hit-rate range column label (Detailed view).
  statisticsRange,

  /// Statistics question preview column label (Keep practicing).
  statisticsQuestion,

  /// Statistics answer preview column label (Keep practicing).
  statisticsAnswer,

  /// Bucket filter section label (Keep practicing).
  statisticsFilterBuckets,

  /// Helper text explaining the modifier-click "isolate this bucket" gesture
  /// on the bucket filter chips (Keep practicing).
  statisticsFilterIsolateHint,

  /// Caption noting that these statistics include Level-Learning results
  /// recorded at the last level (Detailed and Keep practicing).
  statisticsIncludesLevelZero,

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

  /// Status shown when loaded statistics could not be carried over in full,
  /// because the deck was edited outside the app. Takes `{count}`.
  statisticsUnitsReset,

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

  /// Level-Learning statistics tab.
  statisticsLevelLearning,

  /// Total row/column header (Level-Learning matrix).
  statisticsTotal,

  /// Level row-header column label (Level-Learning matrix).
  statisticsLevel,

  /// Numeric level secondary label / breadcrumb. Placeholder: {level}.
  statisticsLevelNumber,

  /// Back-to-matrix action (Level-Learning drill-down).
  statisticsBack,

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

  /// Equal-group column label (shown as "Group" — kept short for the
  /// compact Fields table).
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

  /// Shown under the Mask Editor title when the mask has no linked file yet.
  maskEditorUnsavedMask,

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

  /// Confirm re-linking the open deck to a freshly forked mask.
  confirmForkRelinkDeck,

  /// File→New: title of the dialog choosing how to seed a new deck's mask.
  fileNewMaskChoiceTitle,

  /// File→New: body text of the mask-choice dialog.
  fileNewMaskChoiceBody,

  /// File→New: action to load an existing mask file for the new deck.
  actionLoadExistingMask,

  /// File→New: action to mint a brand-new mask for the new deck.
  actionCreateNewMask,

  /// Status shown after the linked `.inf` mask is saved.
  fileStatusMaskSaved,

  /// Status shown when compatible sibling decks were updated on mask save.
  fileStatusDecksUpdated,

  /// Status shown when an opened deck adopted schema changes from its
  /// linked `.inf` mask.
  fileStatusLinkedMaskAdopted,

  /// Status shown when an opened deck's linked `.inf` differs but cannot be
  /// applied automatically without losing data.
  fileStatusLinkedMaskConflict,

  /// Title of the breaking-propagation dialog.
  propagationBreakingTitle,

  /// Intro line of the breaking-propagation dialog.
  propagationBreakingBody,

  /// Title of the tier-1 propagation confirm-selection dialog (compatible
  /// sibling decks only; no breaking changes).
  propagationConfirmTitle,

  /// Body text of the tier-1 propagation confirm-selection dialog.
  propagationConfirmBody,

  /// Fork action: save the `.inf` as a brand-new mask.
  actionForkMask,

  /// Force action: apply the mask despite data loss.
  actionForceUpdate,

  /// Edit-menu command: sync this mask to copies in other folders.
  menuEditUpdateMaskCopies,

  /// Title of the cross-directory mask-sync review dialog.
  maskSyncTitle,

  /// Subtitle showing the reference mask's own name and revision in the
  /// tier-2 sync dialog. Placeholders: {name}, {revision}.
  maskSyncReferenceLabel,

  /// Line showing the reference mask's own source file, when it has one.
  /// Placeholder: {path}.
  maskSyncReferenceSource,

  /// Sync status: already identical to the current mask.
  maskSyncStatusUpToDate,

  /// Sync status: an older/compatible copy that will be updated.
  maskSyncStatusWillUpdate,

  /// Sync status: a deck that would lose data (excluded).
  maskSyncStatusWouldBreak,

  /// Sync status: differs from the current mask at the same revision.
  maskSyncStatusDiffers,

  /// Sync status: ahead of the reference mask (excluded, never downgraded).
  maskSyncStatusNewer,

  /// Button that applies the selected updates.
  maskSyncApply,

  /// Status shown when a sync scan finds no copies. Placeholder: {folder}.
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

  /// Affirmative action that applies and closes a form (OK).
  actionOk,

  /// Affirmative action (Yes).
  actionYes,

  /// Negative action (No).
  actionNo,

  /// Ask whether a manually-loaded `.sta` should become the auto-save target.
  confirmAdoptAutoSaveTarget,

  /// Auto-load prompt for a discovered session `.sta`. Placeholders:
  /// {datetime}, {queried}, {total}.
  confirmLoadAvailableStats,

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
      LearnAnywhereMessage.mobileLibraryTitle: 'Library',
      LearnAnywhereMessage.mobileLibraryEmptyTitle: 'No decks yet',
      LearnAnywhereMessage.mobileLibraryEmptyBody:
          'Import a .vok deck to start a read-only learning session.',
      LearnAnywhereMessage.mobileImportDecks: 'Import decks',
      LearnAnywhereMessage.mobileImportSuccess: '{count} deck(s) imported.',
      LearnAnywhereMessage.mobileImportFailed: 'Import failed.',
      LearnAnywhereMessage.mobileDeleteDeck: 'Delete',
      LearnAnywhereMessage.mobileDeleteDeckConfirmTitle: 'Delete deck?',
      LearnAnywhereMessage.mobileDeleteDeckConfirmBody:
          'This removes the deck and its statistics from this device.',
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
      LearnAnywhereMessage.menuLearnPracticeSetup: '&Practice setup', // P
      LearnAnywhereMessage.menuLearnWithLastSettings:
          '&Learn with last settings', // L
      LearnAnywhereMessage.menuLearnContinue: '&Continue', // C
      LearnAnywhereMessage.menuStatistics: '&Statistics', // top-bar S
      LearnAnywhereMessage.menuLexicon: 'Le&xicon', // top-bar X
      LearnAnywhereMessage.menuHelp: '&Help', // top-bar H
      LearnAnywhereMessage.helpUserGuide: '&User guide', // U
      LearnAnywhereMessage.helpAbout: '&About', // A
      LearnAnywhereMessage.menuOptions: '&Options', // top-bar O
      LearnAnywhereMessage.menuOptionsAdvancedLearning: '&Advanced Learning Options', // A
      LearnAnywhereMessage.menuOptionsStatistics: 'Stat&istics', // I
      LearnAnywhereMessage.menuOptionsAutoLoadStats:
          'Auto-l&oad statistics', // O
      LearnAnywhereMessage.menuOptionsAutoSaveStats:
          'Auto-sa&ve statistics', // V
      LearnAnywhereMessage.menuOptionsKeepStatistics:
          '&Keep last N session files... ({count})', // K
      LearnAnywhereMessage.keepStatisticsTitle: 'Keep last N session files',
      LearnAnywhereMessage.keepStatisticsLabel: 'Files to keep per deck',
      LearnAnywhereMessage.keepStatisticsHint:
          'The oldest timestamped session files beyond this count are '
          'deleted after each new one is written. 0 keeps every file.',
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
      LearnAnywhereMessage.routeHelpTitle: 'User guide',
      LearnAnywhereMessage.helpContents: 'Contents',
      LearnAnywhereMessage.helpSearchHint: 'Search the guide...',
      LearnAnywhereMessage.helpNoResults: 'Nothing in the guide matches that.',
      LearnAnywhereMessage.helpMatchCount: '{count} matches',
      LearnAnywhereMessage.helpEnglishFallback:
          'This chapter has not been translated yet and is shown in English.',
      LearnAnywhereMessage.helpLinkTitle: 'External link',
      LearnAnywhereMessage.helpCopyLink: 'Copy link',
      LearnAnywhereMessage.helpUnavailable:
          'The user guide could not be loaded.',
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
      LearnAnywhereMessage.aboutVersion040: '0.4.0 – Add Level learning mode.',
      LearnAnywhereMessage.aboutVersion041:
          '0.4.1 – Many small improvements and fixes across the app.',
      LearnAnywhereMessage.aboutVersion050:
          '0.5.0 – Added Linux packaging as an AppImage.',
      LearnAnywhereMessage.aboutVersion060:
          '0.6.0 – Added the built-in user guide under Help, in English and '
          'German.',
      LearnAnywhereMessage.aboutVersion061:
          '0.6.1 – Statistics now follow their units when a deck is edited '
          'outside the app, and the app reports any that were reset.',
      LearnAnywhereMessage.aboutFontCredit:
          'Lab Mono font by Martin Wecke, licensed under OFL-1.1',
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
      LearnAnywhereMessage.editorNoCategories:
          'The current mask has no categories.',
      LearnAnywhereMessage.learnEmptyTitle: 'No learning units',
      LearnAnywhereMessage.learnEmptyBody:
          'Create or open a deck with learning units before starting a session.',
      LearnAnywhereMessage.learnSetupTitle: 'Practice setup',
      LearnAnywhereMessage.learnDirection: 'Direction',
      LearnAnywhereMessage.learnBothDirections: 'Both',
      LearnAnywhereMessage.learnRangeStart: 'Start unit',
      LearnAnywhereMessage.learnRangeStartTooltip:
          'Clearing this field expands the range to the first unit.',
      LearnAnywhereMessage.learnRangeEnd: 'End unit',
      LearnAnywhereMessage.learnRangeEndTooltip:
          'Clearing this field expands the range to the last unit.',
      LearnAnywhereMessage.learnUseAllUnits: 'Use all units ({count})',
      LearnAnywhereMessage.sessionModeSwitchTitle:
          'Statistics from a different mode',
      LearnAnywhereMessage.sessionModeSwitchToDrillBody:
          'The current statistics were recorded in Level learning. Units that '
          'reached the last level already count towards the overall '
          'statistics, so a drill session will treat them as practised.',
      LearnAnywhereMessage.sessionModeSwitchToLevelBody:
          'The current statistics were recorded in another mode. They can be '
          'used to distribute the units across the levels, so units you '
          'already know start with less support.',
      LearnAnywhereMessage.sessionModeSwitchFreshWarning:
          'Starting fresh deletes all existing statistics — both the overall '
          'counters and the Level-learning levels. This cannot be undone.',
      LearnAnywhereMessage.sessionModeSwitchKeep: 'Keep statistics',
      LearnAnywhereMessage.sessionModeSwitchSeed: 'Use for levels',
      LearnAnywhereMessage.sessionModeSwitchFresh: 'Start fresh',
      LearnAnywhereMessage.learnMode: 'Mode',
      LearnAnywhereMessage.learnModePractice: 'Endless mode',
      LearnAnywhereMessage.learnModeSuperQuery: 'Drill mode',
      LearnAnywhereMessage.learnModeOnceThrough: 'Once through',
      LearnAnywhereMessage.learnModeLevelLearning: 'Level learning',
      LearnAnywhereMessage.learnEntryLevel: 'Entry level',
      LearnAnywhereMessage.learnEntryLevelHint:
          'Caps the highest support a newly seeded unit may start at. '
          'No cap lets each unit start with as much support as its prior '
          'results suggest.',
      LearnAnywhereMessage.learnEntryLevelNoCapSuffix: ' (no cap)',
      LearnAnywhereMessage.learnShuffleUnits: 'Shuffle units',
      LearnAnywhereMessage.learnMasteryThreshold: 'Mastery threshold (%)',
      LearnAnywhereMessage.learnMasteryThresholdTooltip:
          'A unit is considered mastered once its correct-answer rate reaches '
          'this percentage. Mastered units are removed from the active '
          'practice pool.',
      LearnAnywhereMessage.learnStartSession: 'Start session',
      LearnAnywhereMessage.learnPrompt: 'Prompt',
      LearnAnywhereMessage.learnYourAnswer: 'Your answer',
      LearnAnywhereMessage.learnSolution: 'Solution',
      LearnAnywhereMessage.learnCorrection: 'Correction',
      LearnAnywhereMessage.learnSwitchHint: 'Switch',
      LearnAnywhereMessage.learnRemarks: 'Remarks',
      LearnAnywhereMessage.learnReveal: 'Reveal',
      LearnAnywhereMessage.learnCheckAnswer: 'Check',
      LearnAnywhereMessage.learnContinue: 'Continue',
      LearnAnywhereMessage.learnCorrectMessage:
          'Your answer is correct. Congratulations!',
      LearnAnywhereMessage.learnWrongMessage:
          'The answer is unfortunately wrong.',
      LearnAnywhereMessage.learnAlmostMessage: 'Almost! So close.',
      LearnAnywhereMessage.learnRatingCorrect: 'Correct',
      LearnAnywhereMessage.learnRatingWrong: 'Wrong',
      LearnAnywhereMessage.learnRatingActuallyCorrect: 'Actually correct',
      LearnAnywhereMessage.learnRatingCloseEnough: 'Close enough',
      LearnAnywhereMessage.learnRatingActuallyWrong: 'Actually wrong',
      LearnAnywhereMessage.learnRatingNoCount: 'No count',
      LearnAnywhereMessage.learnRatingKnewIt: 'Knew it',
      LearnAnywhereMessage.learnRatingDidNotKnow: "Didn't know",
      LearnAnywhereMessage.learnLiveAttempts: 'Attempts',
      LearnAnywhereMessage.learnLiveMastered: 'Mastered',
      LearnAnywhereMessage.learnLiveRemaining: 'Remaining',
      LearnAnywhereMessage.learnLiveAccuracy: 'Accuracy',
      LearnAnywhereMessage.learnUnitAccuracy: 'This unit',
      LearnAnywhereMessage.learnLiveTime: 'Time',
      LearnAnywhereMessage.learnUnitHeader: 'Unit {index}/{total}',
      LearnAnywhereMessage.learnExtendSession: 'Extend session',
      LearnAnywhereMessage.learnEvaluateAs: 'Evaluate as:',
      LearnAnywhereMessage.learnMoreHelp: 'More help',
      LearnAnywhereMessage.learnLessHelp: 'Less help',
      LearnAnywhereMessage.learnHideAndType: 'Hide & type',
      LearnAnywhereMessage.learnLevelNamesTitle: 'Level names',
      LearnAnywhereMessage.learnLevelNamesEnglish: 'English',
      LearnAnywhereMessage.learnLevelNamesGerman: 'German',
      LearnAnywhereMessage.learnLevelNamesApplyPreset: 'Apply space preset',
      LearnAnywhereMessage.learnLevelNamesReset: 'Reset to defaults',
      LearnAnywhereMessage.learnLevelNamesOrderHint:
          'Ordered from most support (top) to free recall (bottom). '
          'Up to 20 characters each.',
      LearnAnywhereMessage.queryOptionsTitle: 'Advanced Learning Options',
      LearnAnywhereMessage.queryOptionWrongInputCorrectable:
          'Wrong input correctable',
      LearnAnywhereMessage.queryOptionCompleteInputRequired:
          'Complete input required',
      LearnAnywhereMessage.queryOptionCaseSensitive: 'Case sensitive',
      LearnAnywhereMessage.queryOptionAccentSensitive: 'Accent sensitive',
      LearnAnywhereMessage.queryOptionAlmostEnabled:
          "Accept near-misses as 'Almost'",
      LearnAnywhereMessage.queryOptionAlmostThreshold:
          "'Almost' similarity threshold (%)",
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
      LearnAnywhereMessage.statisticsUnitList: 'Unit list',
      LearnAnywhereMessage.statisticsOverview: 'Overview',
      LearnAnywhereMessage.statisticsDirectionView: 'View',
      LearnAnywhereMessage.statisticsCombined: 'Combined',
      LearnAnywhereMessage.statisticsDirection1: 'Direction 1',
      LearnAnywhereMessage.statisticsDirection2: 'Direction 2',
      LearnAnywhereMessage.statisticsTotalUnits: 'Total units',
      LearnAnywhereMessage.statisticsQueriedUnits: 'Practiced units',
      LearnAnywhereMessage.statisticsTotalAttempts: 'Total Attempts',
      LearnAnywhereMessage.statisticsCorrectAttempts: 'Correct Attempts',
      LearnAnywhereMessage.statisticsBucket: 'Bucket',
      LearnAnywhereMessage.statisticsCount: 'Count',
      LearnAnywhereMessage.statisticsPercentAll: '% of all',
      LearnAnywhereMessage.statisticsPercentQueried: '% of practiced',
      LearnAnywhereMessage.statisticsUnit: 'Unit',
      LearnAnywhereMessage.statisticsAttempts: 'Attempts',
      LearnAnywhereMessage.statisticsAccuracy: 'Accuracy',
      LearnAnywhereMessage.statisticsRange: 'Range',
      LearnAnywhereMessage.statisticsQuestion: 'Question',
      LearnAnywhereMessage.statisticsAnswer: 'Answer',
      LearnAnywhereMessage.statisticsFilterBuckets: 'Show buckets',
      LearnAnywhereMessage.statisticsFilterIsolateHint:
          'Ctrl+click a bucket to show only that one.',
      LearnAnywhereMessage.statisticsIncludesLevelZero:
          'Including the last level from Level learning',
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
      LearnAnywhereMessage.statisticsUnitsReset:
          'Statistics for {count} units were reset '
          '— those units changed.',
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
      LearnAnywhereMessage.statisticsLevelLearning: 'Level Learning',
      LearnAnywhereMessage.statisticsTotal: 'Total',
      LearnAnywhereMessage.statisticsLevel: 'Level',
      LearnAnywhereMessage.statisticsLevelNumber: 'Level {level}',
      LearnAnywhereMessage.statisticsBack: 'Back',
      LearnAnywhereMessage.lexiconTitle: 'Lexicon',
      LearnAnywhereMessage.lexiconSearchText: 'Search text',
      LearnAnywhereMessage.lexiconCategoryScope: 'Category',
      LearnAnywhereMessage.lexiconAnyCategory: 'Any category',
      LearnAnywhereMessage.lexiconMemorySearch: 'Search memory',
      LearnAnywhereMessage.lexiconFileSearch: 'Search files',
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
      LearnAnywhereMessage.maskEditorEqualGroup: 'Group',
      LearnAnywhereMessage.maskEditorRole1: 'Role dir. 1',
      LearnAnywhereMessage.maskEditorRole2: 'Role dir. 2',
      LearnAnywhereMessage.maskEditorCategoryCount: 'Categories: {count}/20',
      LearnAnywhereMessage.maskEditorFieldCount: 'Fields: {count}/20',
      LearnAnywhereMessage.maskEditorLimitReached: 'Limit reached',
      LearnAnywhereMessage.maskEditorUnsavedMask: 'Not yet saved to a mask file',
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
      LearnAnywhereMessage.confirmForkRelinkDeck:
          'Re-link the currently open deck to this forked mask? The deck '
          'file will be saved now to persist the new identity.',
      LearnAnywhereMessage.fileNewMaskChoiceTitle: 'New deck: choose a mask',
      LearnAnywhereMessage.fileNewMaskChoiceBody:
          'Start this new deck from an existing mask file, or create a '
          'brand-new mask?',
      LearnAnywhereMessage.actionLoadExistingMask: 'Load existing mask...',
      LearnAnywhereMessage.actionCreateNewMask: 'Create new mask',
      LearnAnywhereMessage.fileStatusMaskSaved: 'Mask saved',
      LearnAnywhereMessage.fileStatusDecksUpdated: 'Updated {count} deck(s)',
      LearnAnywhereMessage.fileStatusLinkedMaskAdopted:
          'Deck updated to match its linked mask file.',
      LearnAnywhereMessage.fileStatusLinkedMaskConflict:
          'This deck\'s linked mask file has changed in a way that would '
          'lose data, so the deck keeps its own copy of the mask. Use '
          'Edit ▸ Mask Editor to resolve the conflict.',
      LearnAnywhereMessage.propagationBreakingTitle: 'Some decks would lose data',
      LearnAnywhereMessage.propagationBreakingBody:
          'Applying this mask change would break the following deck(s). Save the '
          'mask as a new mask (leaving these decks on the old one), cancel, or '
          'force the update and lose the listed data.',
      LearnAnywhereMessage.propagationConfirmTitle: 'Update linked decks?',
      LearnAnywhereMessage.propagationConfirmBody:
          'These deck(s) share this mask and can be updated without losing '
          'data. Choose which to update now; unchecked decks are left '
          'untouched.',
      LearnAnywhereMessage.actionForkMask: 'Save as new mask',
      LearnAnywhereMessage.actionForceUpdate: 'Force update (lose data)',
      LearnAnywhereMessage.menuEditUpdateMaskCopies:
          'U&pdate other copies of this mask...', // p

      LearnAnywhereMessage.maskSyncTitle: 'Update other copies of this mask',
      LearnAnywhereMessage.maskSyncReferenceLabel:
          'Reference mask: {name} (rev {revision})',
      LearnAnywhereMessage.maskSyncReferenceSource: 'From: {path}',
      LearnAnywhereMessage.maskSyncStatusUpToDate: 'Up to date',
      LearnAnywhereMessage.maskSyncStatusWillUpdate: 'Will update',
      LearnAnywhereMessage.maskSyncStatusWouldBreak: 'Would break',
      LearnAnywhereMessage.maskSyncStatusDiffers: 'Differs (same revision)',
      LearnAnywhereMessage.maskSyncStatusNewer: 'Newer (not overwritten)',
      LearnAnywhereMessage.maskSyncApply: 'Update selected',
      LearnAnywhereMessage.maskSyncNoneFound:
          'No other copies of this mask were found under {folder}',
      LearnAnywhereMessage.maskSyncDone: 'Synced {count} copy(ies)',
      LearnAnywhereMessage.actionCancel: 'Cancel',
      LearnAnywhereMessage.actionContinue: 'Continue',
      LearnAnywhereMessage.actionClear: 'Clear',
      LearnAnywhereMessage.actionClose: 'Close',
      LearnAnywhereMessage.actionOk: 'OK',
      LearnAnywhereMessage.actionYes: 'Yes',
      LearnAnywhereMessage.actionNo: 'No',
      LearnAnywhereMessage.confirmAdoptAutoSaveTarget:
          'Use this file for auto-saving from now on?',
      LearnAnywhereMessage.confirmLoadAvailableStats:
          'Statistics are available from {datetime}, with {queried} out of '
          '{total} units already queried. Load these?',
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
      LearnAnywhereMessage.mobileLibraryTitle: 'Bibliothek',
      LearnAnywhereMessage.mobileLibraryEmptyTitle: 'Noch keine Lern-Dateien',
      LearnAnywhereMessage.mobileLibraryEmptyBody:
          'Importieren Sie eine .vok-Datei, um eine reine Lesesitzung zu '
          'starten.',
      LearnAnywhereMessage.mobileImportDecks: 'Lern-Dateien importieren',
      LearnAnywhereMessage.mobileImportSuccess:
          '{count} Lern-Datei(en) importiert.',
      LearnAnywhereMessage.mobileImportFailed: 'Import fehlgeschlagen.',
      LearnAnywhereMessage.mobileDeleteDeck: 'Löschen',
      LearnAnywhereMessage.mobileDeleteDeckConfirmTitle:
          'Lern-Datei löschen?',
      LearnAnywhereMessage.mobileDeleteDeckConfirmBody:
          'Dadurch werden die Lern-Datei und ihre Statistik von diesem Gerät '
          'entfernt.',
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
      // Matches the setup screen's own title (learnSetupTitle).
      LearnAnywhereMessage.menuLearnPracticeSetup: 'Übung &einrichten', // E
      LearnAnywhereMessage.menuLearnWithLastSettings:
          'Mit &letzten Einstellungen lernen', // L
      LearnAnywhereMessage.menuLearnContinue: '&Fortsetzen', // F
      LearnAnywhereMessage.menuStatistics: '&Statistik', // top-bar S
      LearnAnywhereMessage.menuLexicon: 'Le&xikon', // top-bar X
      LearnAnywhereMessage.menuHelp: '&Hilfe', // top-bar H
      LearnAnywhereMessage.helpUserGuide: '&Benutzerhandbuch', // B
      LearnAnywhereMessage.helpAbout: '&Programminfo', // P
      LearnAnywhereMessage.menuOptions: '&Optionen', // top-bar O
      LearnAnywhereMessage.menuOptionsAdvancedLearning: '&Erweiterte Lernoptionen', // E
      LearnAnywhereMessage.menuOptionsStatistics: 'Statisti&ken', // K
      LearnAnywhereMessage.menuOptionsAutoLoadStats:
          'Statistiken automatisch &laden', // L
      LearnAnywhereMessage.menuOptionsAutoSaveStats:
          'Statistiken au&tomatisch speichern', // T
      LearnAnywhereMessage.menuOptionsKeepStatistics:
          'Nur die letzten &N Sitzungsdateien behalten... ({count})', // N
      LearnAnywhereMessage.keepStatisticsTitle:
          'Nur die letzten N Sitzungsdateien behalten',
      LearnAnywhereMessage.keepStatisticsLabel: 'Dateien pro Deck behalten',
      LearnAnywhereMessage.keepStatisticsHint:
          'Die ältesten Sitzungsdateien über diese Anzahl hinaus werden nach '
          'jeder neu geschriebenen Datei gelöscht. 0 behält alle Dateien.',
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
      LearnAnywhereMessage.routeHelpTitle: 'Benutzerhandbuch',
      LearnAnywhereMessage.helpContents: 'Inhalt',
      LearnAnywhereMessage.helpSearchHint: 'Handbuch durchsuchen...',
      LearnAnywhereMessage.helpNoResults:
          'Dazu findet sich nichts im Handbuch.',
      LearnAnywhereMessage.helpMatchCount: '{count} Treffer',
      LearnAnywhereMessage.helpEnglishFallback:
          'Dieses Kapitel ist noch nicht übersetzt und wird auf Englisch '
          'angezeigt.',
      LearnAnywhereMessage.helpLinkTitle: 'Externer Link',
      LearnAnywhereMessage.helpCopyLink: 'Link kopieren',
      LearnAnywhereMessage.helpUnavailable:
          'Das Benutzerhandbuch konnte nicht geladen werden.',
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
      LearnAnywhereMessage.aboutVersion040:
          '0.4.0 – Stufenlernen-Modus hinzugefügt.',
      LearnAnywhereMessage.aboutVersion041:
          '0.4.1 – Viele kleine Verbesserungen und Korrekturen in der '
          'gesamten App.',
      LearnAnywhereMessage.aboutVersion050:
          '0.5.0 – Linux-Paketierung als AppImage hinzugefügt.',
      LearnAnywhereMessage.aboutVersion060:
          '0.6.0 – Eingebautes Benutzerhandbuch unter "Hilfe" hinzugefügt, auf '
          'Deutsch und Englisch.',
      LearnAnywhereMessage.aboutVersion061:
          '0.6.1 – Statistiken folgen ihren Einheiten, wenn eine Lern-Datei '
          'außerhalb der App bearbeitet wurde; zurückgesetzte Einheiten werden '
          'gemeldet.',
      LearnAnywhereMessage.aboutFontCredit:
          'Schriftart Lab Mono von Martin Wecke, lizenziert unter OFL-1.1',
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
      LearnAnywhereMessage.editorNoCategories:
          'Die aktuelle Maske hat keine Kategorien.',
      LearnAnywhereMessage.learnEmptyTitle: 'Keine Lerneinheiten',
      LearnAnywhereMessage.learnEmptyBody:
          'Erstellen oder laden Sie eine Lern-Datei mit Lerneinheiten, bevor Sie eine Sitzung starten.',
      LearnAnywhereMessage.learnSetupTitle: 'Übung einrichten',
      LearnAnywhereMessage.learnDirection: 'Abfragerichtung',
      LearnAnywhereMessage.learnBothDirections: 'Beide',
      LearnAnywhereMessage.learnRangeStart: 'Erste Einheit',
      LearnAnywhereMessage.learnRangeStartTooltip:
          'Ein leeres Feld erweitert den Bereich bis zur ersten Einheit.',
      LearnAnywhereMessage.learnRangeEnd: 'Letzte Einheit',
      LearnAnywhereMessage.learnRangeEndTooltip:
          'Ein leeres Feld erweitert den Bereich bis zur letzten Einheit.',
      LearnAnywhereMessage.learnUseAllUnits:
          'Alle Einheiten verwenden ({count})',
      LearnAnywhereMessage.sessionModeSwitchTitle:
          'Statistik aus einem anderen Modus',
      LearnAnywhereMessage.sessionModeSwitchToDrillBody:
          'Die aktuelle Statistik stammt aus dem Stufenlernen. Einheiten, die '
          'die letzte Stufe erreicht haben, zählen bereits zur '
          'Gesamtstatistik und gelten im Drill-Modus als geübt.',
      LearnAnywhereMessage.sessionModeSwitchToLevelBody:
          'Die aktuelle Statistik stammt aus einem anderen Modus. Sie kann '
          'verwendet werden, um die Einheiten auf die Stufen zu verteilen, '
          'damit bereits bekannte Einheiten mit weniger Unterstützung '
          'starten.',
      LearnAnywhereMessage.sessionModeSwitchFreshWarning:
          'Neu beginnen löscht die gesamte bisherige Statistik — sowohl die '
          'Gesamtzähler als auch die Stufen des Stufenlernens. Das kann nicht '
          'rückgängig gemacht werden.',
      LearnAnywhereMessage.sessionModeSwitchKeep: 'Statistik behalten',
      LearnAnywhereMessage.sessionModeSwitchSeed: 'Für Stufen verwenden',
      LearnAnywhereMessage.sessionModeSwitchFresh: 'Neu beginnen',
      LearnAnywhereMessage.learnMode: 'Modus',
      LearnAnywhereMessage.learnModePractice: 'Endlos-Modus',
      LearnAnywhereMessage.learnModeSuperQuery: 'Drill-Modus',
      LearnAnywhereMessage.learnModeOnceThrough: 'Einmal durchgehen',
      LearnAnywhereMessage.learnModeLevelLearning: 'Stufenlernen',
      LearnAnywhereMessage.learnEntryLevel: 'Einstiegsstufe',
      LearnAnywhereMessage.learnEntryLevelHint:
          'Begrenzt die höchste Unterstützung, mit der eine neu eingestufte '
          'Einheit starten darf. Ohne Begrenzung startet jede Einheit mit so '
          'viel Unterstützung, wie ihre bisherigen Ergebnisse nahelegen.',
      LearnAnywhereMessage.learnEntryLevelNoCapSuffix: ' (keine Begrenzung)',
      LearnAnywhereMessage.learnShuffleUnits: 'Einheiten mischen',
      LearnAnywhereMessage.learnMasteryThreshold: 'Beherrschungsschwelle (%)',
      LearnAnywhereMessage.learnMasteryThresholdTooltip:
          'Eine Lerneinheit gilt als gemeistert, sobald ihre Trefferquote '
          'diesen Prozentsatz erreicht. Gemeisterte Einheiten werden aus dem '
          'aktiven Übungspool entfernt.',
      LearnAnywhereMessage.learnStartSession: 'Sitzung starten',
      LearnAnywhereMessage.learnPrompt: 'Frage',
      LearnAnywhereMessage.learnYourAnswer: 'Ihre Antwort',
      LearnAnywhereMessage.learnSolution: 'Lösung',
      LearnAnywhereMessage.learnCorrection: 'Korrektur',
      LearnAnywhereMessage.learnSwitchHint: 'Wechseln',
      LearnAnywhereMessage.learnRemarks: 'Bemerkungen',
      LearnAnywhereMessage.learnReveal: 'Anzeigen',
      LearnAnywhereMessage.learnCheckAnswer: 'Prüfen',
      LearnAnywhereMessage.learnContinue: 'Weiter',
      LearnAnywhereMessage.learnCorrectMessage:
          'Die Eingabe ist richtig! Glückwunsch!',
      LearnAnywhereMessage.learnWrongMessage:
          'Die Eingabe ist leider falsch! Schade!',
      LearnAnywhereMessage.learnAlmostMessage: 'Fast! Ganz knapp daneben.',
      LearnAnywhereMessage.learnRatingCorrect: 'Richtig',
      LearnAnywhereMessage.learnRatingWrong: 'Falsch',
      LearnAnywhereMessage.learnRatingActuallyCorrect: 'Eigentlich richtig',
      LearnAnywhereMessage.learnRatingCloseEnough: 'Nah genug',
      LearnAnywhereMessage.learnRatingActuallyWrong: 'Eigentlich falsch',
      LearnAnywhereMessage.learnRatingNoCount: 'Nicht zählen',
      LearnAnywhereMessage.learnRatingKnewIt: 'Gewusst',
      LearnAnywhereMessage.learnRatingDidNotKnow: 'Nicht gewusst',
      LearnAnywhereMessage.learnLiveAttempts: 'Versuche',
      LearnAnywhereMessage.learnLiveMastered: 'Beherrscht',
      LearnAnywhereMessage.learnLiveRemaining: 'Übrig',
      LearnAnywhereMessage.learnLiveAccuracy: 'Korrekt',
      LearnAnywhereMessage.learnUnitAccuracy: 'Diese Einheit',
      LearnAnywhereMessage.learnLiveTime: 'Zeit',
      LearnAnywhereMessage.learnUnitHeader: 'Einheit {index}/{total}',
      LearnAnywhereMessage.learnExtendSession: 'Sitzung erweitern',
      LearnAnywhereMessage.learnEvaluateAs: 'Bewerten als:',
      LearnAnywhereMessage.learnMoreHelp: 'Mehr Hilfe',
      LearnAnywhereMessage.learnLessHelp: 'Weniger Hilfe',
      LearnAnywhereMessage.learnHideAndType: 'Verdecken & tippen',
      LearnAnywhereMessage.learnLevelNamesTitle: 'Stufennamen',
      LearnAnywhereMessage.learnLevelNamesEnglish: 'Englisch',
      LearnAnywhereMessage.learnLevelNamesGerman: 'Deutsch',
      LearnAnywhereMessage.learnLevelNamesApplyPreset: 'Weltraum-Vorlage',
      LearnAnywhereMessage.learnLevelNamesReset: 'Auf Standard zurücksetzen',
      LearnAnywhereMessage.learnLevelNamesOrderHint:
          'Geordnet von meiste Hilfe (oben) bis freies Erinnern (unten). '
          'Je bis zu 20 Zeichen.',
      LearnAnywhereMessage.queryOptionsTitle: 'Erweiterte Lernoptionen',
      LearnAnywhereMessage.queryOptionWrongInputCorrectable:
          'Falsche Eingabe korrigierbar',
      LearnAnywhereMessage.queryOptionCompleteInputRequired:
          'Vollständige Eingabe erforderlich',
      LearnAnywhereMessage.queryOptionCaseSensitive:
          'Groß-/Kleinschreibung beachten',
      LearnAnywhereMessage.queryOptionAccentSensitive: 'Akzente beachten',
      LearnAnywhereMessage.queryOptionAlmostEnabled:
          'Beinahe-Treffer als „Fast“ akzeptieren',
      LearnAnywhereMessage.queryOptionAlmostThreshold:
          'Ähnlichkeitsschwelle für „Fast“ (%)',
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
      LearnAnywhereMessage.statisticsUnitList: 'Einheitenliste',
      LearnAnywhereMessage.statisticsOverview: 'Übersicht',
      LearnAnywhereMessage.statisticsDirectionView: 'Ansicht',
      LearnAnywhereMessage.statisticsCombined: 'Kombiniert',
      LearnAnywhereMessage.statisticsDirection1: 'Abfragerichtung 1',
      LearnAnywhereMessage.statisticsDirection2: 'Abfragerichtung 2',
      LearnAnywhereMessage.statisticsTotalUnits: 'Lerneinheiten gesamt',
      LearnAnywhereMessage.statisticsQueriedUnits: 'Abgefragte Einheiten',
      LearnAnywhereMessage.statisticsTotalAttempts: 'Abfrage-Versuche',
      LearnAnywhereMessage.statisticsCorrectAttempts: 'Korrekte Versuche',
      LearnAnywhereMessage.statisticsBucket: 'Bereich',
      LearnAnywhereMessage.statisticsCount: 'Anzahl',
      LearnAnywhereMessage.statisticsPercentAll: '% von allen',
      LearnAnywhereMessage.statisticsPercentQueried: '% der abgefragten',
      LearnAnywhereMessage.statisticsUnit: 'Einheit',
      LearnAnywhereMessage.statisticsAttempts: 'Abfrage-Versuche',
      LearnAnywhereMessage.statisticsAccuracy: 'Korrekt',
      LearnAnywhereMessage.statisticsRange: 'Bereich',
      LearnAnywhereMessage.statisticsQuestion: 'Frage',
      LearnAnywhereMessage.statisticsAnswer: 'Antwort',
      LearnAnywhereMessage.statisticsFilterBuckets: 'Kategorien anzeigen',
      LearnAnywhereMessage.statisticsFilterIsolateHint:
          'Strg+Klick auf einen Bereich zeigt nur diesen an.',
      LearnAnywhereMessage.statisticsIncludesLevelZero:
          'Einschließlich der letzten Stufe aus dem Stufenlernen',
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
      LearnAnywhereMessage.statisticsUnitsReset:
          'Die Statistik von {count} Einheiten wurde zurückgesetzt '
          '— diese Einheiten haben sich geändert.',
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
      LearnAnywhereMessage.statisticsLevelLearning: 'Stufenlernen',
      LearnAnywhereMessage.statisticsTotal: 'Gesamt',
      LearnAnywhereMessage.statisticsLevel: 'Stufe',
      LearnAnywhereMessage.statisticsLevelNumber: 'Stufe {level}',
      LearnAnywhereMessage.statisticsBack: 'Zurück',
      LearnAnywhereMessage.lexiconTitle: 'Lexikon',
      LearnAnywhereMessage.lexiconSearchText: 'Suchtext',
      LearnAnywhereMessage.lexiconCategoryScope: 'Kategorie',
      LearnAnywhereMessage.lexiconAnyCategory: 'Alle Kategorien',
      LearnAnywhereMessage.lexiconMemorySearch: 'Speicher durchsuchen',
      LearnAnywhereMessage.lexiconFileSearch: 'Dateien durchsuchen',
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
      LearnAnywhereMessage.maskEditorDirection1: 'Name Abfragerichtung 1',
      LearnAnywhereMessage.maskEditorDirection2: 'Name Abfragerichtung 2',
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
      LearnAnywhereMessage.maskEditorEqualGroup: 'Gruppe',
      LearnAnywhereMessage.maskEditorRole1: 'Rolle Abfr. 1',
      LearnAnywhereMessage.maskEditorRole2: 'Rolle Abfr. 2',
      LearnAnywhereMessage.maskEditorCategoryCount: 'Kategorien: {count}/20',
      LearnAnywhereMessage.maskEditorFieldCount: 'Felder: {count}/20',
      LearnAnywhereMessage.maskEditorLimitReached: 'Grenze erreicht',
      LearnAnywhereMessage.maskEditorUnsavedMask:
          'Noch nicht in einer Maskendatei gespeichert',
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
      LearnAnywhereMessage.confirmForkRelinkDeck:
          'Das aktuell geöffnete Deck mit dieser abgespaltenen Maske neu '
          'verknüpfen? Die Deck-Datei wird jetzt gespeichert, um die neue '
          'Identität dauerhaft festzuhalten.',
      LearnAnywhereMessage.fileNewMaskChoiceTitle: 'Neues Deck: Maske wählen',
      LearnAnywhereMessage.fileNewMaskChoiceBody:
          'Dieses neue Deck aus einer vorhandenen Maskendatei starten oder '
          'eine brandneue Maske erstellen?',
      LearnAnywhereMessage.actionLoadExistingMask: 'Vorhandene Maske laden...',
      LearnAnywhereMessage.actionCreateNewMask: 'Neue Maske erstellen',
      LearnAnywhereMessage.fileStatusMaskSaved: 'Maske gespeichert',
      LearnAnywhereMessage.fileStatusDecksUpdated:
          '{count} Deck(s) aktualisiert',
      LearnAnywhereMessage.fileStatusLinkedMaskAdopted:
          'Lern-Datei an ihre verknüpfte Maskendatei angepasst.',
      LearnAnywhereMessage.fileStatusLinkedMaskConflict:
          'Die mit dieser Lern-Datei verknüpfte Maskendatei hat sich so '
          'geändert, dass Daten verloren gingen; die Lern-Datei behält '
          'daher ihre eigene Kopie der Maske. Öffnen Sie Bearbeiten ▸ '
          'Mask-Editor, um den Konflikt zu lösen.',
      LearnAnywhereMessage.propagationBreakingTitle:
          'Einige Decks würden Daten verlieren',
      LearnAnywhereMessage.propagationBreakingBody:
          'Diese Maskenänderung würde die folgenden Decks beschädigen. Maske als '
          'neue Maske speichern (die Decks bleiben auf der alten), abbrechen '
          'oder Aktualisierung erzwingen und die aufgeführten Daten verlieren.',
      LearnAnywhereMessage.propagationConfirmTitle:
          'Verknüpfte Decks aktualisieren?',
      LearnAnywhereMessage.propagationConfirmBody:
          'Diese Decks teilen sich diese Maske und können ohne '
          'Datenverlust aktualisiert werden. Wählen Sie, welche jetzt '
          'aktualisiert werden sollen; nicht ausgewählte Decks bleiben '
          'unverändert.',
      LearnAnywhereMessage.actionForkMask: 'Als neue Maske speichern',
      LearnAnywhereMessage.actionForceUpdate: 'Erzwingen (Datenverlust)',
      LearnAnywhereMessage.menuEditUpdateMaskCopies:
          '&Andere Kopien dieser Maske aktualisieren...', // A

      LearnAnywhereMessage.maskSyncTitle:
          'Andere Kopien dieser Maske aktualisieren',
      LearnAnywhereMessage.maskSyncReferenceLabel:
          'Referenzmaske: {name} (Rev. {revision})',
      LearnAnywhereMessage.maskSyncReferenceSource: 'Aus: {path}',
      LearnAnywhereMessage.maskSyncStatusUpToDate: 'Aktuell',
      LearnAnywhereMessage.maskSyncStatusWillUpdate: 'Wird aktualisiert',
      LearnAnywhereMessage.maskSyncStatusWouldBreak: 'Würde beschädigen',
      LearnAnywhereMessage.maskSyncStatusDiffers: 'Abweichend (gleiche Revision)',
      LearnAnywhereMessage.maskSyncStatusNewer:
          'Neuer (wird nicht überschrieben)',
      LearnAnywhereMessage.maskSyncApply: 'Auswahl aktualisieren',
      LearnAnywhereMessage.maskSyncNoneFound:
          'Keine weiteren Kopien dieser Maske gefunden unter {folder}',
      LearnAnywhereMessage.maskSyncDone: '{count} Kopie(n) synchronisiert',
      LearnAnywhereMessage.actionCancel: 'Abbruch',
      LearnAnywhereMessage.actionContinue: 'Weiter',
      LearnAnywhereMessage.actionClear: 'Löschen',
      LearnAnywhereMessage.actionClose: 'Schließen',
      LearnAnywhereMessage.actionOk: 'OK',
      LearnAnywhereMessage.actionYes: 'Ja',
      LearnAnywhereMessage.actionNo: 'Nein',
      LearnAnywhereMessage.confirmAdoptAutoSaveTarget:
          'Diese Datei von jetzt an zum automatischen Speichern verwenden?',
      LearnAnywhereMessage.confirmLoadAvailableStats:
          'Statistik von {datetime} verfügbar, mit {queried} von {total} '
          'bereits abgefragten Einheiten. Diese laden?',
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
      LearnAnywhereMessage.defaultDirection1Label: 'Abfragerichtung 1',
      LearnAnywhereMessage.defaultDirection2Label: 'Abfragerichtung 2',
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
