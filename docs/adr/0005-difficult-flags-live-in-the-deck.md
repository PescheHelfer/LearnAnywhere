# ADR-0005 — Difficult flags live in the deck, as two additive keys

**Status:** accepted (2026-09-27)
**Scope:** system-wide — `packages/core` owns the `.vok` codec and the detection rule;
desktop writes both flags, Android reads them only.

## Decision

A unit's **manual flag** and **automatic flag** (see `packages/core/CONTEXT.md`) are two
independent booleans on the unit inside the `.vok` — `"manualDifficult": true` and
`"autoDifficult": true` — each omitted when false. The `.vok` `version` stays `1`.

## Why the deck and not the statistics

The flags have to outlive clearing **either** statistics record — that is the whole
use case: clear the statistics, then drill what was difficult. The `.vok` is the only
file that survives both clears. It also carries the flag **on the unit itself**, so
editing a unit keeps its flag without the hash-and-realign machinery the `.sta` needs
(ADR-0001), and a Lexicon file search finds difficult units without loading any
statistics.

The cost is that flag changes are deck writes. That is contained by timing: a manual
flag is written when the learner sets it (it is the only record of their verdict), an
automatic flag only at the end of a learning session. Flag-only writes do not move
**last edited**, which is why that date is stored in the file rather than read from the
file's modification time.

## Considered options

- **A sidecar file of its own** — a sixth file type needing its own unit identity,
  realignment, documentation and backup story, and able to go missing apart from its
  deck. Most machinery, least gain.
- **Automatic flag in the lifetime `.sta`, manual flag in the `.vok`** — free to write,
  but gives one learner-facing idea two homes, and the automatic flag would need
  realignment when a unit is edited.
- **One key with a `manual` / `auto` / `both` value** — every write must read and merge
  the other flag's state, although the two are written at different times for
  different reasons.

## Consequences

- Additive keys follow the `.sta` `hash` and mask `language`/`speak` precedent:
  `example.vok` stays byte-identical and older builds open flagged decks.
- **An older build that re-saves a deck silently drops every flag in it**, because its
  encoder writes only `categoryId` and `fields`. Accepted rather than bumping the
  version, which would lock older builds out of the file entirely. Automatic flags come
  back with a recompute; manual flags are lost only on a machine that was not updated.
- Writing a flag rewrites the whole file, so it also saves any unsaved unit edits made
  in the same sitting. Accepted: they are the learner's own edits, and the
  window-close autosave would save them anyway.
- Detection is on by default, so a learning session's end may write the deck — also a
  deck opened only to look at someone else's progress. Switching detection off in the
  settings is the escape; no other exclusion exists.
- The unit identity hash ignores both flags, so flagging never resets a unit's
  statistics.
