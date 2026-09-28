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

## Amendment (2026-09-28) — the flags are per direction

Before any release carried them, both flags moved from the unit to the unit **in one
direction**. The decision above still stands: the flags live in the deck, as additive
keys each omitted when false, at `.vok` version `1`. Only their shape changed, to four
booleans: `manualDifficult1`, `manualDifficult2`, `autoDifficult1`, `autoDifficult2`.

**Why.** The brief chose one flag per unit because no learner had yet practised
Direction 2. The learner wants the setup count, the drill and the statistics to answer
"which units are hard *this* way", and a unit hard in one direction only should not be
asked in the other under Difficult units only. Detection already judged each direction
separately and then threw the direction away. Changing the shape after 1.0.0 would have
needed a migration for released decks; changing it before costs nothing.

**Consequences.**
- The pre-amendment keys `manualDifficult` / `autoDifficult` exist only in decks flagged
  by development builds. They are read as **Direction 1** (the only direction ever
  practised when they were written) and never written again.
- A place without a single direction in view (the Lexicon, the statistics unit list's
  Combined view) treats a unit as difficult when either direction is, and counts it once.
- An older build still drops every flag on save, exactly as before.

## Amendment (2026-09-28) — flags belong to one copy of a deck

Because the flags live in the `.vok`, two learners who share a deck each keep their own
flags in their own copy. That is the intent: a flag is one learner's verdict. The cost
shows when the deck's author sends out a **new version** (a typo fixed, units added):
overwriting a copy with it replaces that learner's flags with the author's. Automatic
flags come back with a recompute from the learner's own lifetime record; manual flags do
not.

**Decision.** The flags stay in the deck. Desktop gets a command that takes a new version
of the open deck and carries the open deck's own flags onto the matching units, per
direction, ignoring every flag in the incoming file. Units are matched by identity hash
first, then, among those left over in the same category, by text similarity, so a
typo-fixed unit keeps its flags even when units were inserted before it. Overwriting a
copy in the file manager is still possible, and still loses the manual flags; the user
guide names the command as the way to take a new version.

**Considered and rejected.**
- **Flags in the lifetime `.sta`** — per-learner by construction, but Android never
  imports that file, so the phone would lose every flag. "Clear all-time stats" would wipe
  them. The Lexicon file search, Save selected units, loading found units and merging
  would all need a statistics file they do not read or write today. And the statistics'
  own hash-then-position matching loses or misplaces the record of an edited unit that
  also moved.
- **A safety copy of the manual flags in the lifetime `.sta`**, offered back when a deck
  opens without them — two homes for one verdict, and an exception in "Clear all-time
  stats", to protect only against a copy made outside the program.
