# Getting started

This chapter takes you from a fresh installation to a first finished practice session.
It assumes you have a deck file to work with; if you do not, read
[The mask editor](05-mask-editor.md) and [The unit editor](04-unit-editor.md) to build
one from scratch.

## Installing

**Windows.** Unpack the release folder anywhere you like and run `LearnAnywhere.exe`.
The program needs no installation and writes nothing outside your own user profile.

**Linux.** Learn Anywhere is distributed as an AppImage. Mark it executable and run it:

```
chmod +x LearnAnywhere-x86_64.AppImage
./LearnAnywhere-x86_64.AppImage
```

The Android companion is not released yet.

## The first run

The program opens on the **Workspace** screen with nothing loaded, so it reports
**No file loaded**. Everything is reached from the menu bar along the top:

**File · Edit · Learn · Statistics · Lexicon · Options · Help**

**Statistics** and **Lexicon** are single commands rather than menus — clicking either
one opens that screen directly. Every menu can also be opened from the keyboard with
`Alt` and the underlined letter, for example `Alt+F` for **File**. See
[Keyboard shortcuts](12-keyboard-shortcuts.md) for the full list.

Once you have loaded something, the Workspace screen becomes a summary: the deck's file
path, the name of the mask it uses, how many units it contains, and how much of it you
have already practised. `Esc` returns you here from any other screen.

## The three kinds of file

Learn Anywhere keeps your material in three separate files. All three are plain
UTF-8 JSON text — there is no database, and you can read or back them up with any
editor.

| Extension | What it holds |
|---|---|
| `.vok` | A **deck**: your learning units, plus a read-only copy of the mask that shapes them |
| `.inf` | A **mask**: the editable definition of what a card looks like |
| `.sta` | **Statistics**: how often each unit was asked and how often you got it right |

A deck is self-contained — it carries its own copy of the mask, so it opens correctly
even if the `.inf` file is missing. The `.inf` file is the copy you *edit*; changes made
there can then be pushed into the decks that use it. [Concepts](02-concepts.md)
explains the relationship in full.

Statistics live beside the deck rather than inside it, so you can practise the same
deck under several names, delete a run of bad results, or archive a session without
touching your material.

## Opening a deck

Choose **File ▸ Load deck...** and pick a `.vok` file. The Workspace screen fills in
with the deck's details.

The next time you start the program, the Workspace screen shows the last deck you had
open as a clickable line — one click reopens it without going through the file dialog.

If you keep statistics for the deck, turn on **Options ▸ Statistics ▸ Auto-load
statistics** and the matching `.sta` file is picked up automatically whenever you open
a deck. See [Working with files](03-managing-files.md).

## Your first session

Choose **Learn ▸ Practice setup**. The setup screen asks four things:

- **Direction** — which way round to ask. A mask defines two directions, for example
  German → French and French → German.
- **Mode** — **Level learning**, **Drill mode**, **Endless mode** or **Once through**.
  If you are unsure, start with **Level learning**: it shows you most of the answer at
  first and takes the support away as you improve.
- **Shuffle units** — ask in random order rather than deck order.
- **Start unit** and **End unit** — restrict practice to a stretch of the deck, e.g.
  only this week's lesson. Leave them alone to practise everything.

Press **Start session**. For each card the program shows the question fields and an
empty box for the answer. Type your answer and press `Enter` (or `F3`) to check it.
The program then shows whether it was right, and you press `Enter` again to move on.

If you would rather not type, turn typed answers off and the program will show the
card, wait for you to press **Reveal** (`F10`), and then let you judge yourself.

`Esc` leaves the session at any point. Nothing is lost: [Drill mode](06-learning-sessions.md)
rebuilds its list of unmastered cards from your statistics every time, so you can stop
in the middle and pick up days later — even after restarting the program.

## What to read next

- [Concepts](02-concepts.md) — the vocabulary the rest of the guide uses.
- [Learning sessions](06-learning-sessions.md) — what each mode actually does.
- [Statistics](09-statistics.md) — reading your results, and building a deck out of
  the cards you keep getting wrong.
