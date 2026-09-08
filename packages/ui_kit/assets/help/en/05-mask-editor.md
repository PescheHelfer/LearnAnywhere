# The mask editor

The mask editor designs the *shape* of your cards — see [Concepts](02-concepts.md) if
you have not read it yet. Open it from **Edit ▸ Mask Editor** (`Alt+E`, then `M`). It
always edits the **linked `.inf` file**, never a deck's own frozen copy of the mask.

If the current deck has no linked `.inf` yet, opening the editor offers to create one
from the deck's embedded copy, so there is somewhere to save your changes.

## Name and directions

At the top: the mask's **name**, and the two **direction labels** — the names shown for
each direction throughout the rest of the program, for example on the
[learning setup screen](06-learning-sessions.md).

## Categories

The **Categories** panel lists every category, up to `maxCategoriesPerMask = 20` of
them (shown live as **"Categories: {count}/20"**). For each:

- **Add category** appends a new, empty one.
- Select a category to rename it — names are capped at 40 characters.
- **Move up** / **Move down** reorder categories; order only affects how they are
  offered when [inserting a unit](04-unit-editor.md#adding-and-removing-units).
- **Clone category** inserts a copy directly after the category it was cloned from,
  named after it with "(copy)" added, and selects the copy so it can be renamed right
  away. The copy's fields are independent — new field identities, so editing one side
  never touches the other — but start with no units in them; it copies the *schema*,
  not any data. Unavailable once the mask is at the category limit, exactly like **Add
  category**.
- **Delete category** removes it. If any unit still uses it, this is one of the changes
  that can [break existing decks](#keeping-decks-in-sync) when you save.

## Fields

Select a category to edit its **Fields** panel, up to `maxFieldsPerCategory = 20` of
them (**"Fields: {count}/20"**). Each field has:

| Column | Meaning |
|---|---|
| Field name | Empty makes the field hidden — see [Concepts](02-concepts.md#category-and-field) |
| Length | 1 to 80 characters |
| Group | The field's equal group — 0 means none |
| Role dir. 1 / Role dir. 2 | `Q`, `A` or `R` in each direction — see [Concepts](02-concepts.md#role-what-a-field-is-asked-as) |
| Spoken language | The language this field is written in — see [Speech](15-speech.md#choosing-a-spoken-language) |
| Speak | Whether this field may be read aloud; ticked for you when you make the field an answer — see [Speech](15-speech.md#the-speak-flag) |

**Add field**, **Delete field**, and **Move up** / **Move down** work the same way as
for categories. Shortening a field's length so that it would truncate existing data, or
deleting a field that holds data, are also changes that can break existing decks.

## Saving: fork or update in place

When you save a mask that is already used by one or more decks, you choose how:

- **Save as new mask** ("fork") mints a brand-new identity for the mask you have been
  editing, leaving every existing deck exactly as it was, still pointing at the
  original. If the deck you have open right now was built from this mask, you are
  asked whether to re-link *it* to the fork — every other deck is left alone either
  way.
- Saving **in place** keeps the same identity. If every change is safe — nothing
  deleted, nothing shortened past existing data — decks update automatically the next
  time each is opened, or immediately via
  [Update other copies of this mask](#keeping-decks-in-sync) below. If a change **would
  break** one or more decks, you are shown exactly which ones and why (a deleted
  category orphans some units, a deleted field drops their data, a shortened field
  would truncate it), and asked to choose: fork instead, cancel, or **force the update
  and accept the listed data loss**.

The mask editor's title shows **"Not yet saved to a mask file"** for a mask that has
never been written to disk at all.

## Keeping decks in sync

Editing the linked `.inf` does not, by itself, touch any deck — each deck keeps its own
frozen copy until told otherwise. **Edit ▸ Update other copies of this mask...**
searches a folder you choose for every other file built from the same mask and reports
each one's status. The mask it propagates is whichever one you are looking at: the mask
editor's own mask when the editor is open, and the current deck's mask otherwise. Above
the list, a **Reference mask:** line names it and its revision, and a **From:** line
names the file it came from — falling back to the last mask file you opened when no deck
is open, so a standalone loaded mask still names its source.

| Status | Meaning |
|---|---|
| Up to date | Already matches this mask |
| Will update | Differs, and can be brought up to date safely |
| Would break | Differs in a way that would lose data if applied |
| Differs (same revision) | Same revision number but different content — unexpected; investigate before applying |
| Newer (not overwritten) | The deck's own copy is ahead of this one and is left alone |

Only **Will update** rows can be ticked; the other four statuses are shown for
information and are dimmed to show they are not on offer. Nothing is ever ticked for
you, so a stray click on **Update selected** cannot overwrite anything by itself. Tick
the ones you want, then **Update selected**. Nothing not ticked is touched.

The dialog then stays open. The ticked copies are written, the folder is searched
again, and every row is re-read from disk: a copy that was updated now reads **Up to
date** under its own folder path, and one whose write failed still reads **Will
update** — so which files changed, and which did not, is on screen next to their paths
for as long as you want to look. Rows that are now up to date can no longer be ticked,
so nothing is written twice. You can tick a further set and press **Update selected**
again as often as you like; **Cancel** closes the dialog and undoes nothing that was
already written. If no other copies are found in the chosen folder, you are told so
rather than left to wonder.

Closing the dialog — with **Cancel**, the Escape key, or by clicking outside it — without
ever having written anything reports **"No copies were updated"** in the same place a
successful sync is reported, so cancelling reads differently from a silent failure and
from never having run the command at all. Reporting it this way leaves you exactly where
you ran the command from — the mask editor included, unsaved edits and all — rather than
sending you anywhere else.

If the folder cannot be searched again after a round of writes — it was removed or became
unreachable, for instance — you are still told how many copies were written before that
happened, alongside the failure. You are taken to the file operations screen only when at
least one copy was actually written; a round that failed to search again without having
written anything leaves you exactly where you ran the command from, the same as cancelling.
