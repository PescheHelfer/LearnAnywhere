# Learn Anywhere Architecture

This document describes the Phase 1 foundation for Learn Anywhere. The project is a Melos-managed Flutter/Dart monorepo with one pure Dart core package shared by the desktop and Android apps.

## Workspace

The repository uses Dart pub workspaces plus Melos:

- `pubspec.yaml` declares the workspace members.
- `melos.yaml` keeps the visible Melos workspace marker and script names.
- `analysis_options.yaml` applies strict analysis rules to every package.

Workspace packages:

- `packages/core`: pure Dart domain model, serialization, validation, i18n catalogs, and business logic.
- `packages/ui_kit`: shared Flutter themes, design tokens, localization adapter, rich-text rendering, and future shared widgets.
- `packages/desktop`: Flutter shell for Windows and Linux.
- `packages/mobile`: Flutter shell for Android.

`core` must not import Flutter. `ui_kit`, `desktop`, and `mobile` may import Flutter. Both apps depend on `core` and `ui_kit`.

## Core Model

The domain model lives in `packages/core/lib/models/models.dart`.

Key types:

- `LearningMask`: user-authored schema with name, two direction labels, and up to 20 categories.
- `CategoryDefinition`: named field group with an id, name, and up to 20 fields.
- `FieldDefinition`: field name, length limit, equal-group id, and direction-specific roles.
- `FieldRole`: `Q`, `A`, or `R` for question, answer, or remark.
- `LearningUnit`: one ordered card, keyed by category id, with field values by field name.
- `FieldValue`: either `PlainFieldValue` or `RichFieldValue`.
- `RichTextRun`: portable formatting run with bold, italic, underline, color, and highlight only.
- `DirectionStats`, `UnitStats`, and `StatisticsFile`: counted attempts and correct answers per unit and direction.
- `SessionParameters`: retained query settings used to recompute practice or super-query state.

Missing field values are treated as empty by `LearningUnit.valueForField`. Hidden fields are represented by an empty field name and are excluded from app-facing role/search helpers unless explicitly included.

## File Formats

Serialization and validation live in `packages/core/lib/serialization/serialization.dart`.

Supported formats:

- `.inf`: mask files with `format: "learn-anywhere/mask"` and `version: 1`.
- `.vok`: learning decks with `format: "learn-anywhere/lessons"`, `version: 1`, an embedded full mask, and ordered units.
- `.sta`: statistics sidecars with `format: "learn-anywhere/statistics"`, `version: 2` (1 still loads), a deck reference, and per-unit counters. The desktop keeps them only in the deck's `statistics/` folder (session files and the `_alltime` lifetime record, named by `DeckPaths`); see [`docs/file-formats.md`](docs/file-formats.md).

All loaders are strict about required schema rules:

- Wrong `format` or unsupported `version` fails.
- Field lengths must be 1 through 80.
- Roles must be `Q`, `A`, or `R`.
- A mask may have at most 20 categories.
- A category may have at most 20 fields.
- Category names may be at most 40 characters.
- Statistics counters must be non-negative, with `correct <= attempts`.
- A rich-text run's `color` must be the token `text1` and its `highlight` the token
  `highlight1` when present.

Unknown future fields are ignored so newer files can remain forward-tolerant. Validation errors are reported as `ValidationException` with a JSON path and human-readable message.

## Core Engines

Business logic lives in `packages/core/lib/engine/engine.dart`.

Implemented helpers include:

- Role-driven prompt, answer, and remark field selection.
- Answer evaluation with trimming, optional case folding, optional accent stripping, plain-text comparison, equal-group multiset matching, complete-input handling, and all-or-nothing unit scoring.
- Rating recording for correct, wrong, and no-count outcomes.
- Optional wrong-answer ceiling that stops recording additional wrong attempts once the configured ceiling is reached.
- Super-query mastery checks using hit-rate threshold plus optional minimum-attempts guard.
- Derived active super-query pools computed from current deck, statistics, range, direction selection, and threshold.
- Practice item picking, including the optional each-once mode.
- Statistics aggregation into the legacy bucket order.
- Statistics clearing by returning zeroed in-memory counters.
- Memory search, loaded-deck file search, and disk `.vok` search returning source-file results.

The super-query pool is intentionally derived rather than stored. To resume, interrupt, widen, or raise a threshold, the app keeps `SessionParameters` and recomputes from current deck data plus current statistics.

## UI Kit

Shared Flutter UI code lives in `packages/ui_kit`.

Current Phase 1 contents:

- `LearnAnywhereTheme`: light and dark Material 3 themes.
- `LearnAnywhereTokens`: shared spacing, radius, and monospace fallback constants.
- `LearnAnywhereRichTextRenderer`: converts `FieldValue` and `RichTextRun` into Flutter `TextSpan`s.
- `LearnAnywhereRichText`: widget wrapper around the renderer.
- `LearnAnywhereLocalizations`: Flutter localization adapter backed by core message catalogs.

The rich-text editor is not implemented in Phase 1. Phase 2 should build it on top of the same core run model so storage remains portable across desktop and Android.

## Apps

`packages/desktop` and `packages/mobile` are blank themed shells.

Both apps:

- Use `LearnAnywhereTheme.light()` and `LearnAnywhereTheme.dark()`.
- Register `LearnAnywhereLocalizations.supportedLocales`.
- Register `LearnAnywhereLocalizations.localizationsDelegates`.
- Read visible app-shell strings from localization instead of hardcoding them in widgets.

The desktop shell targets Windows and Linux. The mobile shell targets Android. No web app is part of the product architecture.

## Internationalization

Framework-independent message catalogs live in `packages/core/lib/i18n/i18n.dart`.

Supported languages:

- English: `en`
- German: `de`

Core exposes message ids through `LearnAnywhereMessage` and resolves strings through `LearnAnywhereCatalog`. Flutter apps consume those strings through `LearnAnywhereLocalizations` in `ui_kit`.

Mask labels and field names are user data, not UI messages. They must remain in deck/mask data and must not be translated by the app catalogs.

## Reference Screenshots

The legacy reference screenshots are source material rather than documentation, so they are not shipped with the repository; they are kept in the maintainer's local project archive. Appendix A of `docs/build-specification.md` is the normative record of what each screenshot contributes, and it is written out in full prose — nothing in the build depends on seeing the images.

They are used only to preserve layout, terminology, and shortcut placement in Phase 2. They must not drive DOS-era visual styling. Phase 2 should modernize typography, controls, spacing, colors, dark mode, and charts while keeping the familiar structure.

## Verification

Phase 1 verification commands:

```powershell
$env:PATH='E:\Programs\IT\flutter\bin;'+$env:PATH
melos bootstrap
dart format . --set-exit-if-changed
melos run analyze
melos run test:core
melos exec --depends-on=flutter -- flutter test
```

Native target build checks depend on installed host toolchains:

- Windows desktop builds require Visual Studio 2019 or later with the C++ desktop workload.
- Android builds require an Android SDK configured for Flutter.
- Linux desktop builds require a Linux host.

In this workspace, analyzer and Flutter/Dart tests pass. Native package builds were attempted during Phase 1 and are blocked by local platform toolchain availability, not by app code.
