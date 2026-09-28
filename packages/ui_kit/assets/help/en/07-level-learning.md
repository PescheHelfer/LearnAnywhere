# Level learning

Level learning is a per-unit scaffold: each unit starts with heavy support and loses it
step by step, in four **levels** numbered 3 down to 0. Level 3 is the most help; level 0
is producing the answer from nothing.

## The four levels

| Level | What you see |
|---|---|
| 3 | The whole solution is shown first. Pressing the primary button (`F10`, labelled **Hide & type**) hides it and turns the field into an empty box you type the same answer into from memory, before it is checked. |
| 2 | An **editable scaffold**: every other character of the solution is already filled in and fixed; you fill in the blanks between them. The **first** character of each word is always one of yours, so even a one-character answer asks you to recall it. |
| 1 | Only the first and last character are shown; everything between is blank. Short words still ask for something: a two-character word shows the first character and leaves the last, and a one-character word is left blank. |
| 0 | Free recall — nothing is shown. This is the same as answering with no Level Learning support at all. |

Punctuation and spaces are never blanked, only letters and digits — a word's own
characters are what carry the difficulty, not its shape.

Below level 3 every word keeps at least one blank, so you are never shown a field with
nothing to answer. One consequence is deliberate: for a three-character word level 1
shows two characters where level 2 shows only one, so level 1 is marginally easier at
that single length. At one, two, four and five characters the two levels show the same
number of characters, only in different places; from six characters on, level 2 always
shows more.

The characters the scaffold puts on screen count as part of your answer. Revealed
letters, and the punctuation and spaces it never blanks, are graded as though you had
typed them, and they appear in the **Your answer** view. A field you leave untouched is
therefore submitted with its revealed characters rather than as an empty answer — so
with **Complete input required** switched off (see
[How answers are judged](08-answer-evaluation.md)), a scaffolded field is never treated
as unanswered.

## Moving down the ladder

A unit **promotes** — moves to the next level down, meaning *less* support — the moment
its current level's own accuracy reaches your mastery threshold. There is **no
automatic demotion**: a wrong answer only adds to that level's own attempt count, it
never sends a unit back up. A unit leaves the practice pool for good only once it has
mastered level 0.

With [Difficult units only](06-learning-sessions.md#asking-difficult-units-only)
switched on, the pool holds just the difficult units in the range. Mastering level 0
still takes a unit out, and it keeps its difficulty flag.

You can override the automatic pace at any time with **More help** (moves the current
unit up one level) and **Less help** (moves it down one), each bounded by 0 and 3.

## Where a unit starts

**Entry level**, on the [setup screen](06-learning-sessions.md#setting-up-a-session),
caps how much support a unit new to Level Learning may start with. A unit's starting
level is otherwise guessed from whatever accuracy it already has recorded from other
modes — a unit you already know well starts further down the ladder — then capped by
this setting. Setting it to **no cap** removes the ceiling entirely.

## Naming the levels

The four levels have names of their own, shown throughout the program instead of the
bare numbers. Edit them under **Options ▸ Advanced Learning Options**, in the **Level
names** panel — see [Settings](11-settings.md#learning-options). Two sets are kept, one
per interface language, each ordered from most support (top, level 3) to free recall
(bottom, level 0), up to 20 characters each:

| | Level 3 | Level 2 | Level 1 | Level 0 |
|---|---|---|---|---|
| English default | Beginner | Learner | Almost There | Champion |
| German default | Anfänger | Lerner | Fast geschafft | Meister |

**Apply space preset** swaps in an alternative English set (Launchpad, Lift-Off, In
Orbit, Moon Landing) and its German counterpart (Startrampe, Abflug, Umlaufbahn,
Mondlandung); **Reset to defaults** restores the table above.

## Statistics

Level Learning keeps its own per-level counters, viewable as a level-by-accuracy matrix
on the [Statistics](09-statistics.md#level-learning) screen. A unit that has reached
level 0 also counts toward your overall (non-Level-Learning) statistics, so switching to
Drill mode later treats it as already practised rather than starting from scratch.

The live **Attempts** figure during a Level-Learning session is read from those per-level
counters: it counts every attempt at every level, across the whole deck, in the direction
the session is set to — both directions only when it is set to **Both** — so a session
spent climbing the ladder shows movement. That makes it deliberately larger than **Total
Attempts** on the [Statistics](09-statistics.md) screen, which only ever sees the level-0
results. The two carry the same label because a longer one would not fit on the pill — in
Level Learning, read **Attempts** as ladder work.

The level pills and **Mastered** follow the same rule as everywhere else: each one is a
deck total in the session's direction. A session restricted to a unit range still shows how
every unit of the deck is spread across the four levels, and what share of the whole deck
has reached mastery — the range decides what you are asked, not what is counted.
