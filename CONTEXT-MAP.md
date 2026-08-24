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
| [`packages/core/CONTEXT.md`](packages/core/CONTEXT.md) | Statistics vocabulary — the two records, session files, learning sessions. |
| [`docs/adr/0001-all-time-statistics-accumulate-live-deltas.md`](docs/adr/0001-all-time-statistics-accumulate-live-deltas.md) | Why the lifetime record is accumulated live and never derived. |

The other contexts have no `CONTEXT.md` or `docs/adr/` yet. That is not a gap to fill
upfront — they get written when a term or a decision actually needs pinning down.
