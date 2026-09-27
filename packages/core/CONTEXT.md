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

## Difficult units

**Difficult** — a unit the learner should drill again, whatever their statistics say
now. A unit is difficult when it carries a manual flag, an automatic flag, or both;
nothing else makes it difficult. It is a property of the unit and travels with the deck,
so it outlives clearing either record. In German **schwierig**; a flag is a
**Kennzeichnung** (*als schwierig gekennzeichnet*), never *Markierung*, which the German
interface already uses for text highlight.

**Manual flag** — the learner's own verdict that a unit is difficult. Set and removed
only by the learner; never by the program. It is the only record of that verdict.

**Automatic flag** — the program's verdict that a unit is difficult, judged from the
unit's lifetime record alone against thresholds the learner can set, never from how the
rest of the deck is going. It is added when a learning session ends, if the learner has
not switched detection off, and removed only by the learner: by recomputing the
automatic flags, or by unmarking a unit, which says "not difficult" and so removes both
flags. It can always be derived again from the lifetime record, so losing one is not
losing data.

**Last edited** — when a deck's units last changed: a field value or a unit's category,
or a unit added or removed. Changing a flag is not an edit, and neither is a change to
the deck's mask.

**Last learned** — when a deck was last practised, taken from its statistics files. It is
never stored as a date of its own.

Avoid "label" for either flag: in this project a label is a piece of interface text.
Avoid "mark" as a noun for the manual flag; the learner *marks* a unit, and what that
leaves behind is a manual flag.

## Speech

**Spoken language** — the language a *field* holds, as a BCP-47 tag (`fr-FR`), stored in
the mask and carried with the deck to any machine. It says what the text *is*, not who
reads it: it is the same tag whether the field is the question, the answer or a remark,
and in either direction. In German it is **Vorlesesprache** — deliberately not *Sprache*,
which the Options menu already uses for the **interface language**, an unrelated setting
about the program's own labels. It is never a property of a direction or of a deck (see
[ADR-0003](../../docs/adr/0003-spoken-language-belongs-to-the-field.md)), never guessed
from a field's content, and never a voice.

**Voice** — one installed way of speaking a language, as the *machine* reports it. A
voice is a property of the machine and is never portable: it lives in that machine's
settings, is resolved afresh from a spoken language every time, and is never written into
a mask or a deck. A stored choice names an engine as well as a voice, because two engines
identify voices incompatibly. It is not the spoken language — several voices may speak
one language, and a language may resolve to no voice at all, which is silence with an
explanation rather than an error.

**Speech engine** — what actually makes sound: the seam (`TtsEngine`) core describes and
a shell injects an implementation of. Which engine is present is a fact about the host,
so a host with none is handed one that reports itself unavailable rather than none at all
(see [ADR-0004](../../docs/adr/0004-flutter-tts-first-linux-mute.md)). It is not the
voice it speaks with, and it decides nothing about *what* is said — that is the policy's
business, and the engine keeps no state between two utterances.

Speech is **presentation only**. Hearing a field is not an *attempt*: it moves no counter
in either record, and touches neither mastery nor the Level-Learning ladder.
