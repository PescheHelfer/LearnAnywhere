# Statistics

The **Statistics** screen (**Statistics**, `Alt+S` — a direct action on the menu bar,
not a submenu) reads the same counters your sessions write to. It has three tabs:
**Overview**, **Unit list**, and **Level Learning**.

Every tab shares a **View** switch — **Combined**, **Direction 1** or **Direction 2** —
and the same **Load stats... / Save stats / Save stats as... / Clear stats...** commands
also found on the [File menu](03-managing-files.md#statistics). What happens to these
counters when the deck itself changes is covered under
[When the deck was edited elsewhere](03-managing-files.md#when-the-deck-was-edited-elsewhere).

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
