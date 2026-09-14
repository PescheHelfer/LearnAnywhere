# The unit editor

The unit editor is where you write your material. Open it from **Edit ▸ Unit editor**
(`Alt+E`, then `U`); it opens on the last unit you were looking at.

Everything in the editor is keyboard-first — the same shortcuts work whether you are
looking at a card's fields or navigating between cards.

## Layout

The header reads **"Unit {index} of {total} - {category}"**, so you always know where
you are and which category the current card belongs to. Below it, one row per field in
that category, each showing the field's name and its value.

A field with no name is a **hidden field**: it holds a value but is never shown as a row
here — see [Concepts](02-concepts.md#category-and-field).

## Moving between units

| Key | Action |
|---|---|
| `F2` | Previous unit |
| `F3` | Next unit |
| `F6` | Jump to a specific unit number |
| `F5` | Search across every unit for matching text |

**Jump** and **Search** each open a small dialog; search shows every matching unit as a
list you can pick from directly, or reports **"No matching units found."** if nothing
matches.

## Adding and removing units

- `F8` — **Insert before** the current unit. If the mask has more than one category,
  you are asked to **choose a category** for the new unit first.
- `F7` — **Delete** the current unit, after confirming — this cannot be undone.
- If the deck is completely empty, the editor shows an **Insert unit** button instead of
  a card; there is nothing to navigate until you add the first one.

If the mask itself has no categories yet, the editor tells you so and sends you to the
[mask editor](05-mask-editor.md) first — a category has to exist before a unit can be
assigned to one.

## Editing a field

Click into a field and type. Fields are single-line and fixed-width, sized by their
**length** limit ([Concepts](02-concepts.md#category-and-field)) — what you type never
grows or shrinks the row. `Enter` or `Tab` moves to the next field; `Backspace` on an
empty field moves back to the previous one.

### Rich text

Select some text inside a field to format it:

| Action | Effect |
|---|---|
| Bold | **Bold** |
| Italic | *Italic* |
| Underline | Underlined |
| Text color | Colours the selection in the theme's text colour; press it again to remove it |
| Highlight | One of a short list of background colours for light or dark themes, or None |
| Clear formatting | Removes bold/italic/underline/colour/highlight from the selection |

**Text color** works like **Bold**: it has no palette, and it shows as pressed when the
selection is already coloured. Each theme offers one text colour, chosen to stay readable
on that theme's fields and to look nothing like the colour of a correction mark; the
button's icon is drawn in it. The deck stores only *that* the text is coloured, not the
colour itself, so switching the theme re-colours it everywhere — in the editor, in a
learning session and on Android.

With nothing selected, turning on Bold, Italic, Underline or Text color arms it for the
*next* text you type — useful for typing a whole word in italics without selecting it
afterwards. Formatting is stored with the unit and travels with it wherever the deck goes.

## Finishing

- `F10` — **Done**. Keeps every change you made and returns to the workspace.
- `Esc` — **Cancel**. If nothing changed since you opened the editor, this returns you
  immediately; if something did change, you are asked to confirm discarding it, and the
  deck reverts to exactly how it was when you opened the editor.

Nothing you do in the unit editor touches disk on its own — use **File ▸ Save deck**
(or `F10` followed by saving) once you are happy with the result. See
[Working with files](03-managing-files.md).
