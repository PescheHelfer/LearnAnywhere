# Core — glossary

The vocabulary `packages/core` owns. This is a glossary and nothing else: it says what a
term means and what it is not, never how it is implemented or what the product should
do. For the mechanism, see the ADRs; for the on-disk shape, see
[`../../docs/file-formats.md`](../../docs/file-formats.md).

Use these words as written. If a concept you need is not here, either you are inventing
language the project does not use, or there is a real gap worth adding.

## The two records

**Current statistics** — the working record of a deck. It is the record the program
learns from: it decides which units are asked, which count as mastered, and where the
learner stands on the Level-Learning ladder. It can be loaded, saved and cleared by the
learner. Also called *the working record* when contrasting it with the one below; never
"the session statistics", which collides with *session file*.

**All-time statistics** — the lifetime record of a deck. It holds everything ever
answered for that deck and only ever grows. It decides nothing — no pool, no mastery, no
ladder position — and is never shown during a learning session. Also called *the
lifetime record*. In German it is **Allzeit-Statistik**; never "Gesamt-Statistik".

The two are separate records of the same deck, not two views of one. They can disagree
about a unit, and that is a fact about the domain rather than an inconsistency.

## The word "session"

Four things nearby carry the word, and only two of them are domain terms:

**Learning session** — one run of practice: the learner starts it, answers questions,
and ends it. A thing that happens, bounded in time. Where a message needs the learner's
own word for it, the English catalogue says *sitting*.

**Session file** — a `.sta` file holding a snapshot of the **current statistics**,
written beside the deck and named after it and the moment the run began. A thing on
disk. It is a snapshot, not a log: it records the state of the working record, not what
happened during one learning session. Several session files may therefore describe
overlapping history, and they are not a partition of the deck's past.

Two further uses are *not* domain terms and should never be introduced into prose:

- The working record's scope is spelled `session` in code and in the `.sta` format, for
  historical reasons — it predates the lifetime record. Read it as *current
  statistics*.
- "Session" in the ordinary computing sense (a process run, a connection) does not
  appear in this domain at all.

## Neighbouring terms these lean on

**Deck** — a `.vok` file and the units in it. The learner-facing word in English; in
German the catalogue says **Lern-Datei**. Never "vocabulary file" in English prose.

**Unit** — one entry in a deck: the fields that make a question and an answer, in either
direction. Statistics are recorded per unit and per direction.

**Attempt** — one rated answer to one unit in one direction. Attempts are what move a
record's counters; nothing else does.

**Mastery** — a unit having met the criteria that take it out of the practice pool.
Decided from the current statistics only.
