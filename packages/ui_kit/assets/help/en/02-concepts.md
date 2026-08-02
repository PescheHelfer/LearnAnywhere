# Concepts

Learn Anywhere has no idea what a language, a formula, or a chemical symbol is. It only
knows about **masks**, **decks**, **units**, **categories**, **fields**, **roles** and
**directions** — a small, subject-agnostic vocabulary that everything else in this guide
builds on.

## Mask: the shape of a card

A **mask** is the form your cards fill in. It defines:

- A **name**, purely for your own reference.
- Two **direction labels** — the two ways round you can be asked, for example
  "German" and "French". You choose which direction to practise in
  [Learning sessions](06-learning-sessions.md).
- Up to 20 **categories**, each a named group of up to 20 **fields**.

A mask has no idea of the *content* of a card, only its *shape*: how many pieces of
information belong to it and what role each one plays.

## Category and field

A **category** groups the fields that belong together on one kind of card — a mask for
vocabulary might have a "Noun" category with fields for the word, its article and a
plural form, and a separate "Verb" category with fields for the infinitive and the
principal parts. Every learning unit belongs to exactly one category.

A **field** is one piece of information: a name, a maximum **length** (1 to 80
characters — fields are single-line and shown in a fixed-width font, so their width
never depends on what is typed into them), an **equal group**, and a **role** in each
direction.

A field with no name is **hidden**: it still holds data and can still be asked, but it
never appears as a labelled row in the editor or in search results — useful for a
field you fill in for your own bookkeeping rather than to be quizzed on.

## Equal group

Fields that share a non-zero **equal group** number are treated as interchangeable
answers. If both "plural form" and "alternative plural form" carry equal group `1`,
typing either one into a session is accepted — the program checks your answer against
every field in the group, not just the one currently shown as the primary answer.
Fields with equal group `0` (the default) are not linked to anything.

## Role: what a field is asked as

Every field carries a **role** in each of the mask's two directions, shown in the
[mask editor](05-mask-editor.md) as a single letter:

| Role | Meaning |
|---|---|
| `Q` | Question — shown as the prompt |
| `A` | Answer — what you are asked to supply |
| `R` | Remark — shown alongside the prompt or the solution, never asked |

The same field can be `Q` in one direction and `A` in the other. That is what makes a
mask bidirectional: a German→French mask typically has the German fields as `Q` and the
French fields as `A` in one direction, and the reverse in the other, so the same deck
drills you both ways without being authored twice.

## Unit: one card

A **learning unit** is one card: a category, plus a value for each of that category's
fields. Units are numbered 1..N in the order they appear in the deck. A value can be
plain text, or **rich text** — bold, italic, underline, colour and highlight, set in the
[unit editor](04-unit-editor.md).

## Deck and mask file: why there are two

Your material lives in two related files, described in full in
[Getting started](01-getting-started.md#the-three-kinds-of-file):

- The **deck** (`.vok`) holds your units, plus a read-only **copy** of the mask — frozen
  at whatever shape it had the last time the deck was saved.
- The **mask file** (`.inf`) is the mask's own, *editable* home.

The deck carries its own copy so that it always opens correctly, even if the `.inf` is
missing, renamed, or lives somewhere else entirely. But it also means editing the
`.inf` in the [mask editor](05-mask-editor.md) does not, by itself, change any deck. To
bring a deck's embedded copy up to date, use **Edit ▸ Update other copies of this
mask...**, described in [The mask editor](05-mask-editor.md#keeping-decks-in-sync).

Two decks that share the same mask — for example this week's lesson and last week's —
are recognised as sharing it internally, even though each keeps its own frozen copy.
That is what makes **Update other copies of this mask** able to find and offer to
update every deck built from a given `.inf`, wherever it lives on disk.
