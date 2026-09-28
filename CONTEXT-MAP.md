# Context map

Learn Anywhere is a melos monorepo with four contexts. Each keeps its own `CONTEXT.md`
(the glossary of terms that context owns) and its own `docs/adr/` (decisions scoped to
it). Repo-wide decisions live in [`docs/adr/`](docs/adr/).

| Context | Path | What it owns |
|---|---|---|
| Core | [`packages/core`](packages/core) | The domain: decks, masks, units, the learning engine, statistics, path derivation, the message catalogues. Pure Dart, no Flutter, no `dart:io` beyond what the shells hand it. |
| UI kit | [`packages/ui_kit`](packages/ui_kit) | Shared widgets, design tokens, bundled fonts, and the in-app user guide under `assets/help/`. Consumed by both shells. |
| Desktop | [`packages/desktop`](packages/desktop) | The Windows and Linux shell: menus, screens, file dialogs, the file service that owns every read and write. |
| Mobile | [`packages/mobile`](packages/mobile) | The Android companion. Depends on core and ui_kit, never on desktop. |

A term belongs to the context that decides its meaning. Statistics vocabulary is core's,
even though the desktop shell is what shows it, because core is what defines when a
counter moves.

## Where to look first

- **A word you are unsure of** — the owning context's `CONTEXT.md`. Don't reach for a
  synonym the glossary explicitly avoids.
- **Why something is built the way it is** — [`docs/adr/`](docs/adr/) for repo-wide
  decisions, then `packages/<context>/docs/adr/`.
- **How the pieces fit together** — [`ARCHITECTURE.md`](ARCHITECTURE.md).
- **What the on-disk files contain** — [`docs/file-formats.md`](docs/file-formats.md).
- **Cross-platform working rules** — [`CLAUDE.md`](CLAUDE.md).

## Existing files

| File | |
|---|---|
| [`packages/core/CONTEXT.md`](packages/core/CONTEXT.md) | Statistics vocabulary — the two records, session files, learning sessions — difficult units (manual and automatic flags, new version, last edited, last learned), and speech vocabulary: spoken language, voice, speech engine. |
| [`docs/adr/0001-all-time-statistics-accumulate-live-deltas.md`](docs/adr/0001-all-time-statistics-accumulate-live-deltas.md) | Why the lifetime record is accumulated live and never derived. |
| [`docs/adr/0002-zoom-scales-the-theme-not-the-text-scaler.md`](docs/adr/0002-zoom-scales-the-theme-not-the-text-scaler.md) | Why zoom scales the theme's font sizes and never the text scaler. |
| [`docs/adr/0003-spoken-language-belongs-to-the-field.md`](docs/adr/0003-spoken-language-belongs-to-the-field.md) | Why a spoken language is a property of a field and never of a direction or a deck. |
| [`docs/adr/0004-flutter-tts-first-linux-mute.md`](docs/adr/0004-flutter-tts-first-linux-mute.md) | Why the simpler speech engine ships first, and why Linux ships mute. |
| [`docs/adr/0005-difficult-flags-live-in-the-deck.md`](docs/adr/0005-difficult-flags-live-in-the-deck.md) | Why the manual and automatic difficult flags are additive keys in the `.vok`, not statistics or a sidecar — and, since its amendments, why they are kept per direction and how a learner keeps theirs when taking a new version of a shared deck. |
| [`packages/desktop/CONTEXT.md`](packages/desktop/CONTEXT.md) | Desktop shell vocabulary — start folder, content frame, zoom level, recent decks. |
| [`packages/mobile/CONTEXT.md`](packages/mobile/CONTEXT.md) | Android companion vocabulary — the Library, and the deck title (a file's base name, never its mask's). |
| [`packages/mobile/docs/adr/0001-library-recency-from-the-session-file.md`](packages/mobile/docs/adr/0001-library-recency-from-the-session-file.md) | Why the Library's order is derived from the session file's modification time and no timestamp is stored. |

Anything not listed above does not exist yet — `packages/ui_kit` has no `CONTEXT.md`, and
only `packages/mobile` has a context-scoped `docs/adr/`. That is not a gap to fill
upfront — they get written when a term or a decision actually needs pinning down.
