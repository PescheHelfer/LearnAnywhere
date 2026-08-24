# ADR-0001 — The all-time record accumulates live deltas and is never merged from session files

**Status:** accepted (2026-08-24)
**Scope:** system-wide — `packages/core` owns the model, `packages/desktop` owns the
writes, `packages/mobile` will adopt the same core API.

## Context

A deck's statistics answer two different questions, and one record cannot answer both.
The working record has to be *resettable*: it decides the super-query pool, mastery and
the Level-Learning ladder, so a learner starting a topic over must be able to zero it.
The lifetime record has to be *durable*: it is the deck's whole history, and its only
job is to still be there in a year.

So a second record exists, written beside the deck as `<deck>_alltime.sta`, carrying
`"scope": "allTime"` (see [`../file-formats.md`](../file-formats.md)). The question this
ADR settles is how it is **filled**.

The obvious cheap answer was to derive it: session files already sit beside the deck,
one per sitting, so the lifetime totals look like their sum. That is what this decision
rejects.

## Decision

**The all-time record is accumulated live, one delta per answer, at the moment the
answer is rated. It is never derived, summed, merged or reconciled from session files
or from the working record.**

Three rules follow from that and are not negotiable:

1. **Only an answer moves the numbers.** Loading statistics, saving, merging a deck,
   realigning after an outside edit and clearing the current record all leave the
   lifetime totals exactly as they were. An attempt suppressed by the wrong-answer
   ceiling is skipped in both records; a "no count" rating is a no-op in both.
2. **The record is kept regardless of the auto-save option.** That option governs
   session files. The lifetime record is written on every answer either way, and
   flushed on new, open, merge, close and exit.
3. **The record decides nothing.** No pool, no mastery, no ladder position, and it never
   appears in a session's live readouts. Loading it *as* the working record is a
   deliberate, warned-about act by the learner (and mints a fresh session file for what
   follows), not something the engine ever does on its own.

### Why not sum the session files

- **They are not a partition of the history.** Session-file retention deletes the oldest
  beyond **Keep last N session files**, so summing them silently under-counts by however
  many the learner let go. The deletion is a feature; making the lifetime record depend
  on it would turn it into data loss.
- **They overlap.** A session file is a snapshot of the *working record*, not a log of
  what happened during that sitting. Load an older file, keep answering, save: two files
  now share the same attempts. Nothing in a `.sta` distinguishes carried-over counters
  from new ones, so there is no arithmetic that de-duplicates them after the fact.
- **A clear erases the evidence, not the history.** Clearing the current record is
  supposed to leave the lifetime one intact. If the lifetime one were derived from what
  the working record has ever been, the everyday clear would take the history with it —
  precisely the thing the second record exists to prevent.
- **The units may have moved.** Realignment can keep a unit's counters across a text
  edit in the lifetime record while the working record resets them (a changed unit is a
  different unit *to practise*, but the same unit *in the history*). The two records
  therefore legitimately disagree about a unit, and a derivation would have to pick one
  reading and be wrong about the other.

A delta has none of these problems: it is counted once, at the only moment its
provenance is unambiguous, into a file whose whole contract is that it only ever grows.

## Consequences

### Authority is a property of the record, not of the call site

Because the record is never re-derivable, a lost or clobbered lifetime file cannot be
rebuilt. The write policy that protects it:

**A lifetime record may _create_ a lifetime file anywhere, but may _replace_ one only at
the deck path it was successfully read from.**

`AllTimeRecord` (`packages/core/lib/statistics/all_time.dart`) carries the proof: the
path it was read for, and an `AllTimeOrigin` saying what that read found — `loaded`,
`absent`, `unreadable`, or `unread` for a record that never read anything.
`speaksFor(path)` is true only for `loaded` and `absent` at that same path. `record`,
`resized`, `afterInsert` and `afterDelete` all preserve the origin and path, which is
what stops a
deck-shape change from manufacturing authority: a merge or an editor insert can still
turn an empty record dense, but dense was never the question.

Two consequences the shell surfaces to the learner:

- **An unreadable file is a refusal to write, not a licence to zero.** A file locked for
  a second by a sync client or a scanner used to decode as "no history"; one answer later
  the intact file was overwritten with zeros. Now the read is distinguished from an
  absent file and the write is refused. An **absent** file still means an empty record,
  silently — that is the ordinary first-run case.
- **Save-as onto an occupied path refuses and says so.** The deck saves; the lifetime
  file already there belongs to another deck and is left untouched. Merging two decks'
  lifetimes has no defensible arithmetic (the record counts by delta, never by sum), and
  an overwrite prompt would ask the learner to weigh a file they cannot see. Save-as onto
  a path with **no** lifetime file writes normally and the record adopts that path, so a
  copied deck carries its history with it.

### A refusal is a remembered state, not a return value

A refused write is not a failure to retry: nothing re-reads or re-points the record
afterwards, so every later write is refused too. That was originally silent, and the rest
of the sitting went nowhere. `AllTimeRecord` therefore also carries `refusedPath` /
`isRefused` — a fact about the disk, set by the writer, riding through every operation
and dropped by `adoptedAt`, because a write that lands is the cure.

The learner is told twice: at the moment of the refusal (`fileSaveDeckAllTimeKept` /
`fileAllTimeUnreadable`) and, for as long as it lasts, by a standing notice in the
all-time scope of the statistics screen (`statisticsAllTimeNotRecorded`). Reopening the
deck from where it now sits is what restores recording, and the wording says so.

The alternatives were weighed and rejected on the same reasoning as above: **re-reading
at the new path** would silently swap which history the deck accumulates into halfway
through a sitting, leaving the answers given before the save-as in neither record;
**asking the learner** is the overwrite prompt already turned down, at the one moment
they are busy doing something else.

### The one deliberate exception

Clearing the all-time record (`replaceUnreadFile: true`) is the single write that means
"zero this file whatever it holds". It says so at the call site rather than forging a
read, it is reachable only from the all-time scope of the statistics screen and from
nowhere in the menu bar, and its dialog focuses Cancel so `Enter` cannot confirm it.
Confirming zeroes the file rather than deleting it, and accumulation restarts from zero.

### What this costs

- **A missed write is a permanently missed write.** There is no reconciliation pass to
  fall back on, by design. The write chain is therefore serialised with the session
  auto-save and flushed at every lifecycle edge.
- **The two records can disagree about a unit**, and that is correct rather than a bug to
  fix — see the realignment point above.
- **The lifetime record cannot be back-filled from a learner's existing session files by
  the program.** No import tool ships. A one-off migration of pre-existing files is a
  manual job, and only defensible once the files involved have been proven not to
  overlap.

## References

- `packages/core/lib/statistics/all_time.dart` — `AllTimeRecord`, `AllTimeOrigin`.
- `packages/core/lib/paths/deck_paths.dart` — `allTimeStatistics`, and why `_alltime`
  can never match the session-file pattern.
- `packages/desktop/lib/src/file_operations/desktop_file_service.dart` —
  `writeAllTimeStatistics` and `AllTimeWriteOutcome`.
- [`../file-formats.md`](../file-formats.md) — the `scope` marker and the two file names.
- [`../../packages/core/CONTEXT.md`](../../packages/core/CONTEXT.md) — the glossary that
  pins *current statistics*, *all-time statistics*, *session file* and *learning
  session*.
