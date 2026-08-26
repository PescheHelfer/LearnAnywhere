# Statistics

The **Statistics** screen (**Statistics**, `Alt+S` — a direct action on the menu bar,
not a submenu) reads the same counters your sessions write to. It has three tabs:
**Overview**, **Unit list**, and **Level Learning**.

Two rows sit above the tabs. The first holds the **Direction** switch — **Combined**,
**Direction 1** or **Direction 2** — and the **Current** / **All-time** scope control
described in [The two records](#the-two-records); in the **All-time** scope a
three-dot overflow button, **All-time actions**, joins them. The second holds the file
commands, which follow the scope: in **Current** they are **Load stats... / Save stats /
Save stats as... / Clear current stats...**, the same commands found on the
[File menu](03-managing-files.md#statistics); in **All-time** it holds nothing but
**Cancel**, because none of those commands acts on the record you are looking at. What
happens to these counters when the deck itself
changes is covered under
[When the deck was edited elsewhere](03-managing-files.md#when-the-deck-was-edited-elsewhere).

## The two records

Every deck keeps two separate records of what you have answered, and all three tabs can
show either of them. The **Current** / **All-time** control chooses which one you are
looking at; the screen always opens on **Current**.

- **Current** — the working record. This is the one the program learns from: it decides
  which units go into the practice pool, which count as mastered, and where you stand on
  the [Level learning](07-level-learning.md) ladder. It is what **Load stats...** and
  **Save stats** read and write, and it is the record a session file holds.
- **All-time** — the deck's whole history. It only ever grows: every answer you give is
  added to it as you give it, and nothing else ever changes it. Loading a statistics
  file, merging another deck or clearing the current record leaves it exactly as it was.
  It decides nothing — no practice pool, no mastery, no ladder position — and it never
  appears in the readouts during a session.

The all-time record is kept whether or not **Auto-save statistics** is switched on. That
option governs session files only; the lifetime record is written on every answer
regardless of it, into a file of its own named after the deck — `mydeck_alltime.sta`
beside `mydeck.vok` — which is created the first time you answer a question.

In the **All-time** scope, the **Level Learning** tab's level column reads as the
**last** level reached rather than a current one, because the lifetime record has no
current position on the ladder.

Occasionally the screen shows a standing warning in the all-time scope: **These all-time
statistics are no longer being saved: the file beside the deck belongs to another deck,
or could not be read.** The program never overwrites a lifetime file it did not manage
to read, so from that point on this sitting is counted on screen only. Opening the deck
again from where it now sits is what restores the recording.

## Clearing a record

Each record is cleared on its own, from its own scope, and neither clear touches the
other.

- **Clear current stats...**, in the **Current** scope, erases every recorded attempt in
  the working record after confirming. The all-time statistics are not affected — the
  dialog says so. This is the everyday reset: start the deck over without losing its
  history.
- **Clear all-time stats...**, in the **All-time** scope, erases the deck's complete
  learning history. It is deliberately kept out of sight, because it is the one command
  in the program that destroys something you cannot rebuild by practising. It exists
  nowhere in the menu bar, and it is not on the screen either: open the three-dot
  **All-time actions** button beside the scope control and it is the single entry
  inside, marked with a warning symbol in the warning colour. From the keyboard, `Tab`
  reaches that button, `Enter` or `Space` opens it — the command takes the focus at once
  — and `Esc` closes it again unused.
- Choosing it asks first. The dialog **names the deck** whose history is about to go, so
  you can be certain which record you are destroying, and asks whether you **really**
  want this. Cancel holds the focus, so pressing `Enter` dismisses the dialog rather
  than confirming it; only clicking **Clear** goes through with it.

**Clearing the all-time record cannot be undone.** There is no copy to restore it from:
the numbers live in `<deck name>_alltime.sta` beside the deck, and confirming zeroes
that file. Your current statistics, your session files and the deck itself are
untouched, and answers given afterwards start accumulating a new history from zero. If
you want the old figures kept, copy that file somewhere else before you clear.

## Practising from the all-time record

The all-time record cannot decide what is practised — but you can hand it over to the
working record deliberately, when you want a run driven by the units you have got wrong
most across the deck's whole life.

Choose **Load stats...** and pick the deck's `_alltime.sta` file. Because that file is
not an ordinary session file, the program warns you first, spelling out what happens:
the numbers replace the current statistics and decide which units are asked next,
further answers go to a **new** session file, and the all-time statistics themselves
stay untouched. Decline and nothing at all changes.

Accept and the practice pool is rebuilt from those figures. The program will not offer
to auto-save into that file, and never treats it as the file **Save stats** writes to,
so no ordinary save can reach it. Meanwhile the lifetime record carries on accumulating
in the background exactly as it would have done anyway.

## The seven buckets

Every unit's accuracy sorts it into one of seven buckets, used throughout this screen:

| Bucket | Accuracy |
|---|---|
| Perfect | 100% |
| Good | 75–99% |
| Fair | 50–74% |
| Unsure | 25–49% |
| Very unsure | 1–24% |
| Never known | 0% (attempted, never correct) |
| Not yet practiced | No attempts recorded |

## Overview

Total units, practiced units, total attempts and correct attempts for the current
scope, then a table and bar chart breaking every unit down by bucket — count, percent
of all units, and percent of practiced units.

## Unit list — finding what to practice again

A sortable table of every unit: **Unit**, **Question**, **Answer**, **Attempts**,
**Accuracy**. This is the screen to build a fresh deck out of exactly the units giving
you trouble:

1. Narrow the list — click a bucket chip to toggle it, `Ctrl`+click one to isolate it,
   or set explicit **Min %** / **Max %** bounds.
2. **Select visible** to select everything currently shown, or click individual rows.
   **Clear selection** starts over.
3. **Save selected units** writes them out as a brand-new `.vok` deck — your current
   deck and its statistics are untouched; this only creates a new file.

This works the same way in either scope, so a deck of lifetime problem units is built
exactly like a deck of this week's.

A note under the table flags when the figures **include the last level from Level
Learning** — level-0 results count toward these ordinary statistics too, so a unit
mastered there is not invisible here.

## Level Learning

A matrix with one row per level and one column per accuracy bucket, plus row and column
**Total**s, showing how your practice pool is distributed across both dimensions at
once. Click a cell to drill into the units it represents — the same unit list as above,
scoped to that level and bucket; **Back** returns to the matrix.

This tab only has data once you have practised in
[Level learning](07-level-learning.md) mode.
