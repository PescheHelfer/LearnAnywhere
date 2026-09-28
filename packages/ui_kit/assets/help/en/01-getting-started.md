# Getting started

This chapter takes you from a fresh installation to a first finished practice session.
It assumes you have a deck file to work with; if you do not, read
[The mask editor](05-mask-editor.md) and [The unit editor](04-unit-editor.md) to build
one from scratch.

## Installing

Download it from the
[Releases page](https://github.com/PescheHelfer/LearnAnywhere/releases/latest).

**Windows.** Unzip the downloaded folder anywhere you like, keeping its files
together, and run `LearnAnywhere.exe` from inside it. The program needs no
installation and writes nothing outside your own user profile.

**Linux.** Learn Anywhere is distributed as an AppImage. Mark it executable and run it:

```
chmod +x Learn_Anywhere-*.AppImage
./Learn_Anywhere-*.AppImage
```

The Android companion is not released yet.

## The first run

The program opens on the **Workspace** screen with nothing loaded, so it reports
**No file loaded**. Everything is reached from the menu bar along the top:

**File · Edit · Learn · Statistics · Lexicon · Options · Help**

**Lexicon** is a single command rather than a menu — clicking it opens that screen
directly. Every menu can also be opened from the keyboard with
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

The Workspace screen keeps the three decks you opened most recently under **Recent
decks**, newest first. Each one is a clickable line, and one click opens it without
going through the file dialog. The list is there on the next start of the program, and
also while a deck is loaded — that is when switching to another language is most
useful. The deck you already have open is left out, so the list only ever offers
somewhere else to go.

Each entry names the folder the deck sits in as well as the deck itself, for example
`...\Franz\LCI2_LC1.vok`: a file name on its own rarely says which language it belongs
to, while the folder above it usually does. The `...` stands for the rest of the path,
and the ⧉ at the end marks the line as a link. Hovering over an entry shows the full
path.

Under each entry are two dates, so you can tell a freshly revised deck from one you
have been neglecting:

- **Last edited** — when you last changed the deck's units and saved them: typed in a
  field, added or removed a unit. Practising does not count, and neither does a change
  to the deck's mask. A deck last saved by an older
  version of Learn Anywhere has no such date and shows **not recorded** until you next
  edit and save it.
- **Last learned** — when you last practised the deck, read from the statistics files
  beside it. A deck you have never practised shows **not learned yet**.

If you move or delete a deck it stays
in the list, greyed out, rather than quietly disappearing — that way a whole folder you
have moved is visible instead of silently gone. Such an entry no longer opens anything:
clicking it reports **File not found** with the path it looked in.

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
