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
| Highlight | Highlights the selection in the theme's highlight; press it again to remove it |
| Clear formatting | Removes bold/italic/underline/colour/highlight from the selection |

**Text color** and **Highlight** work like **Bold**: neither has a palette, and each shows
as pressed when the selection already carries it. Each theme offers one text colour and
one highlight. The text colour is chosen to stay readable on that theme's fields and to
stand out clearly from the normal text; the highlight to stand out from those
fields while the theme's normal text stays readable on it. Each button's icon is drawn in
its colour. The deck stores only *that* the text is coloured or highlighted, not the
colour itself, so switching the theme re-colours it everywhere — in the editor, in a
learning session and on Android.

With nothing selected, turning on Bold, Italic, Underline, Text color or Highlight arms it
for the *next* text you type — useful for typing a whole word in italics without selecting
it afterwards. Formatting is stored with the unit and travels with it wherever the deck
goes.

## Marking a unit difficult

A unit is difficult in a direction (see
[Marking a unit difficult](06-learning-sessions.md#marking-a-unit-difficult)). Here in
the editor you see and set both directions. The header line shows one badge per
direction the current unit is difficult in, **Difficult 1** and **Difficult 2**, each
with the icon of every flag it carries, and updates them as you move between units.
Hover over a badge to read which flag it is:

- **Manual flag** — you marked it.
- **Automatic flag** — the program found it hard from the unit's all-time statistics.
- **Manual and automatic flag** — both.

`F12` toggles Direction 1 and `Shift+F12` toggles Direction 2, with the same rule as in
a [learning session](06-learning-sessions.md#marking-a-unit-difficult): where the unit
is difficult in that direction, both of that direction's flags are cleared; where it is
not, your manual flag is set. The other direction is never touched.

The action row has a pill for each: **Difficult 1** (`F12`) and **Difficult 2**
(`Shift+F12`). Clicking one does what its key does. A pill is filled while the unit is
difficult in its direction and outlined while it is not, and it shows the change you
have not saved yet — what **Done** will keep. Hover over a pill to see which direction
it stands for, under the name your mask gives that direction.

Unlike in a session, the change is not written at once. It is part of the pending edit,
like a field value, so it is kept only in memory until you save, and is dropped along
with any other unsaved change if you cancel. A save whose only change is a flag leaves
the deck's **Last edited** date as it is; a save that also changes a field's content
dates the deck as usual.

## Finishing

- `F10` — **Done**. Keeps every change you made and returns to the workspace.
- `Esc` — **Cancel**. If nothing changed since you opened the editor, this returns you
  immediately; if something did change, you are asked to confirm discarding it, and the
  deck reverts to exactly how it was when you opened the editor.

Nothing you do in the unit editor touches disk on its own — use **File ▸ Save deck**
(or `F10` followed by saving) once you are happy with the result. See
[Working with files](03-managing-files.md).
