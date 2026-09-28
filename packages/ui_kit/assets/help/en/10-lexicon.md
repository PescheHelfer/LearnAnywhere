# The lexicon

The **Lexicon** (**Lexicon**, `Alt+X` — a direct action, not a submenu) searches for
text across units, in one of two scopes.

## Search memory

Searches the units currently loaded, filtered by **Search text** and, optionally, a
single **Category** (or **Any category**). Matches show which fields the text was
found in.

Leaving **Search text** empty (or typing nothing but spaces) means "everything": every
unit is listed. Combined with a **Category**, that is how you review one category of a
deck — pick the category, leave the box empty, search. Such results name no matched
fields, because no text was searched for.

## Search files

Searches every `.vok` file under a folder you choose, recursively — not just the deck
you have open. This is for finding a card you know you wrote at some point but cannot
remember which deck it ended up in.

Results carry both a **Source file** and the **Matched fields**, so you can tell decks
apart when the same text turns up in more than one. Two modes govern what happens to
what you find:

- **Display only** — the default. Results are shown; nothing in memory changes.
- **Load found units** — replaces your currently loaded units with the results, after
  you confirm (this discards whatever was in memory). It is refused outright rather
  than risking a mess if the results belong to more than one mask, or if bringing them
  in line with the newest mask revision among them would lose data.

Once results are loaded, use **Load results** to bring them into memory the same way
loading a deck would.

Both search modes stop at 2000 hits, so that a broad search over a large folder cannot
leave the program building a table for minutes. When that happens the line above the
table reads **Results: showing the first 2000 — there are more. Narrow the search.**
instead of the usual count — a capped search is never reported as if nothing was found.
Narrow it with a **Category**, or with search text.

Both search modes respect the **Case sensitive** and **Accent sensitive** options from
[Advanced Learning Options](11-settings.md#learning-options) — the same settings that
govern how a typed answer is judged during a session.

## Finding difficult units

Switch on **Difficult only** to find just the units flagged as
[difficult](06-learning-sessions.md#marking-a-unit-difficult), by you or by the program,
in either direction. It works in both search modes and combines with **Search text** and
**Category**: a hit has to match all three. Like **Category**, it applies to the next search, not to the
results already on screen. With **Search text** left empty it lists every difficult
unit.

The flags are stored in the deck files themselves, so **Search files** finds the
difficult units of every deck under a folder with no statistics loaded at all. That is
the way to gather every difficult unit you own.

The results table has a **Difficult** column: a flag for your manual flag, a sparkle
for the automatic one, both side by side for both — in either direction — and nothing
for a unit that is not difficult. Hover over it to read which flag sits in which
direction, for example **Manual flag: Direction 1 · Automatic flag: Direction 1 and 2**.

Loading hits with **Load results** keeps every flag on every unit, in both directions,
and so does saving them afterwards. So switch on **Difficult only** and **Load found
units**, choose **Search files**, then **Load results**, and finally **File ▸ Save
deck**: that gives you one new deck of your difficult units, still flagged.
