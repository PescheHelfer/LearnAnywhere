# Learning sessions

A session is you being asked cards, one at a time, from the deck you have loaded.
Everything about how a session picks and presents cards starts on the **Practice
setup** screen (**Learn ▸ Practice setup**, `Alt+L` then `P`).

## Setting up a session

| Setting | What it does |
|---|---|
| **Direction** | Which of the mask's two directions to be asked in, or **Both** to mix them |
| **Mode** | **Level learning**, **Drill mode**, **Endless mode** or **Once through** — see below |
| **Entry level** | Level Learning only — caps how much support a newly seeded unit may start with; see [Level learning](07-level-learning.md) |
| **Shuffle units** | Ask in random order instead of deck order |
| **Mastery threshold (%)** | Drill mode only — a unit counts as mastered once its correct rate reaches this |
| **Require typed answers** | Off, cards wait for you to judge yourself instead of typing; hidden for Level learning, which always requires typing |
| **Start unit** / **End unit** | Restrict the session to a range of the deck; clearing either field expands it to the first/last unit. **Use all units ({count})** resets both at once |

Press **Start session** to begin. If you already have a session running, this button
reads **Continue** instead, and takes you straight back into it.

## The four modes

- **Level learning** walks each unit down a ladder of decreasing support until you can
  produce it from nothing. This mode has a chapter of its own:
  [Level learning](07-level-learning.md).
- **Drill mode** keeps a pool of every unit that is not yet **mastered** — correct rate
  at or above your mastery threshold — and asks from that pool until it is empty. The
  pool is recomputed from your statistics every time, so raising the threshold, or
  widening the unit range, brings items back in without losing anything you already
  recorded. You can stop mid-session and resume later, even after restarting the
  program.
- **Endless mode** picks randomly from the whole range for as long as you keep going;
  nothing is ever removed from the pool.
- **Once through** asks every in-range unit exactly once, then finishes.

If the statistics you already have were recorded under a different mode — specifically,
on the other side of the Level-Learning/non-Level-Learning divide — starting a session
asks first: **keep statistics** and carry on as-is, **use for levels** (seed each unit's
starting level from its existing accuracy), or **start fresh** (clears everything,
including Level-Learning progress — this cannot be undone).

## During a session

The header reads **"Unit {index}/{total}"**. Below it:

- **Prompt** — the question fields for this direction.
- An input box for **Your answer**, if **Require typed answers** is on; otherwise the
  card waits for you to judge yourself.
- **Remarks**, if the mask has any fields with that role.

Press `F3` or `Enter` to **Check**. What happens next depends on whether your answer
matched — covered in full in [How answers are judged](08-answer-evaluation.md) — but in
every case you then either continue automatically or choose how to rate the attempt
from a row of buttons (`F5`/`F6`/`F7`) shown right after **Continue** and **Cancel**, so
both groups stay within reach of each other. On a narrow window the rating buttons drop
to a line of their own rather than being cut off.

`F10` **Reveals** the card without you answering, if you would rather see it than guess.
`F9` cycles what the answer area shows: **Correction** (your answer with differences
highlighted against the solution) → **Solution** → **Your answer**.

A small speaker icon beside a field reads that field aloud. It appears wherever the mask
allows the field to be spoken and its value is on screen — so the prompt can be heard
straight away, and the answer once you have checked. See
[Speech](15-speech.md#hearing-a-field).

With **automatic speech** switched on, the answer reads itself out at every reveal,
right or wrong, and `F4` reads it again whenever you want it — see
[Reading the answer automatically](15-speech.md#reading-the-answer-automatically).

A live panel tracks **Attempts**, **Mastered**, **Remaining**, **Accuracy**, **Unit
accuracy** — the current unit's own figure — and, if enabled in
[Settings](11-settings.md#learning-options), elapsed **Time**.

**Attempts**, **Mastered**, **Remaining** and **Accuracy** each describe **the whole deck,
in the direction this session asks** — not the sitting, and not the unit range. (The two
readouts after them are deliberately narrower: **Unit accuracy** is about that one unit,
and **Time** is this sitting's clock.) Restricting the range narrows what you
are asked, never what is counted, so the four figures standing side by side always describe
the same population: a session on units 5–10 of a 200-unit deck still reports **Mastered**
and **Remaining** out of all 200. With one of the mask's two directions chosen under
**Direction** they cover that direction alone; with **Both**, every unit in both
directions.

**Attempts** and **Accuracy** are read from the deck's statistics — they are not counters
for this sitting. They open on whatever the deck has already recorded, keep their value
when you leave a session and start another, and are still there after you close and reopen
the program. That makes them the same figures the [Statistics](09-statistics.md) screen
reports as **Total Attempts** and **Correct Attempts** when its **View** switch matches the
session: **Combined** for a **Both** session, **Direction 1** or **Direction 2** for a
single-direction one. (The screen opens on **Direction 1**, so switch it to compare.) There
is only one set of numbers to trust. Loading another deck shows that deck's own totals and
nothing from the previous one. An attempt rated **No count** records nothing, so it does
not move them either.

`Esc` ends the session and returns to setup. In Drill mode nothing is lost by doing
this: the pool is rebuilt from statistics the next time you start.

## Finishing

Once through and Drill mode both end when there is nothing left to ask —
Drill mode with everything mastered, Once through after the last unit. Either way you
can press **Extend session** to keep going past the end rather than stopping there.
