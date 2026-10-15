# ADR-0006 — Learning time is a capped, deck-wide total in both records

**Status:** accepted (2026-10-13)
**Scope:** system-wide — `packages/core` owns the two records and the `.sta` format that
gains the totals; `packages/desktop` is the only shell that shows them. Android keeps no
learning time: the phone and the computer never exchange statistics, so there is no
record of the desktop's for it to wipe.

## Context

The learning screen had one clock, the **unit time**, which restarts with every unit and
is what the time limit is measured against. The learner asked to see time at three
further scales: the **sitting**, the **current statistics**, and the deck's whole
history across all of them. The vocabulary is pinned in
[`../../packages/core/CONTEXT.md`](../../packages/core/CONTEXT.md) under *Time*.

The two larger scales outlive the program run, so they must be stored, which makes this
a change to the `.sta` format and not just to a screen. Format changes are the hard part
to undo: every session file written from then on carries the value, and a later change
of meaning would leave old and new files disagreeing silently.

Three questions had genuine alternatives:

- **What is learning time?** A clock that runs from start to end counts a sitting left
  open over lunch as an hour of learning. The program cannot tell thinking from absence.
- **Per deck or per direction?** Every other statistic is recorded per unit and per
  direction, and the live readouts follow the session's direction.
- **May the lifetime record be shown during a sitting?** Until now the glossary said
  none of it was — it is the record that decides nothing, kept out of view so it could
  not be mistaken for the one that does.

## Decision

**Learning time is the sum of the unit times of the units the learner rated, each
counted up to a fixed cap of 5 minutes. It is one total per deck, kept in both records:
the current statistics hold the statistics time (reset when that record is cleared), the
all-time statistics hold the total time (never reset). The total time is the one figure
of the lifetime record shown live.**

- **Only rated units count**, *No count* and think-only included. A unit's time is added
  when it is rated, in the same write as the answer, so learning time needs no save of
  its own. A unit left unrated when the sitting ends adds nothing.
- **The cap is a constant, not a setting.** Beyond 5 minutes on one unit the learner is
  taken to have been away; the unit counts 5 minutes. The cap governs the totals only —
  the unit-time pill shows the real elapsed time, and the time limit is unaffected.
- **Deck-wide, not per direction.** Drill and Level-Learning sittings add to the same
  total, and the Statistics screen's View does not filter it.
- **Absent means zero.** A `.sta` written before this has no total, which reads as no
  time recorded rather than as an error.

## Consequences

- **The totals understate on purpose.** A long think on one hard unit is clipped at the
  cap, and the last unit of an abandoned sitting is dropped. Both err toward too little,
  never too much, which is the direction a learner can trust.
- **The live pills can briefly show more than is saved.** The Sitting, Statistics and
  Total pills tick with the current unit's running time; if the learner ends the sitting
  without rating it, those seconds were shown and never stored.
- **Total time starts at the release.** Existing lifetime records carry no time, so the
  total covers only sittings since the format learned to keep it. The glossary says so,
  and so must the guide.
- **The lifetime record's write authority is unchanged.** Adding time is a delta like
  any other and follows [ADR-0001](0001-all-time-statistics-accumulate-live-deltas.md):
  it may create a lifetime file anywhere, but replace one only where it was read.
- **A per-direction split is gone for good from the stored history.** Introducing one
  later cannot divide the totals already written; it would have to start from zero.
- **The glossary rule that the lifetime record is never shown during a sitting now has
  one exception, total time.** It still decides nothing — no pool, no mastery, no
  ladder — so showing its time cannot be mistaken for it steering the session.

## Alternatives rejected

- **Wall-clock time, uncapped.** Simple and exact, and wrong as soon as the learner walks
  away — the figure would measure how long the window was open.
- **Pausing while the window is not focused.** Catches the learner who switched to
  another program but not the one who left the desk; it needs the cap anyway, and the
  cap alone covers both.
- **A learner-settable cap.** One more setting whose right value nobody knows; a constant
  the guide names is easier to reason about.
- **Per-direction time.** Consistent with every other statistic, but the question a
  learner asks is "how long have I spent on this deck", and a sitting that asks both
  directions would have its time split by an attribution nobody chose.
- **Counting the abandoned last unit.** Needs a save as the sitting closes — the one
  moment a failed write has nobody left to report to — to rescue at most 5 minutes.
- **Total time on the Statistics screen only.** Keeps the old glossary rule intact, but
  the learner asked to watch the lifetime figure grow during a sitting, and nothing about
  showing a time total can make the lifetime record decide anything.
