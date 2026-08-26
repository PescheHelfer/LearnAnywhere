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
