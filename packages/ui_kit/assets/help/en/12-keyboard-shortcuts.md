# Keyboard shortcuts

Learn Anywhere is fully operable from the keyboard. This chapter is the complete
reference; each shortcut is also explained in context in its own chapter.

## Everywhere

| Key | Action |
|---|---|
| `F1` | Open this user guide, as a dialog over whatever you are doing. Works from any screen, including mid-session or mid-edit — the only exceptions are while a menu is open or another dialog is already showing |
| `Esc` | On any screen without its own `Esc` handling (Statistics, Lexicon, About, Options, Mask Editor), return to the workspace |
| `Ctrl` and `.` | Next zoom level up — the form that works on every keyboard |
| `Ctrl` and `+` | Next zoom level up, where your keyboard has a `+` key of its own. On a Swiss keyboard, where `+` is the shifted `1`, that is `Ctrl+Shift+1`; on a numeric keypad it is the keypad's own `+` |
| `Ctrl` and `-` | Next zoom level down |
| `Ctrl+0` | Back to 100% |

The zoom keys are the only `Ctrl` shortcuts in the program — everything else is a
function key or an `Alt` mnemonic. They step between the six offered levels rather than
scaling freely; see [Settings](11-settings.md#zoom-level).

`Ctrl` and `.` exists because `+` is not in the same place on every keyboard, and on some
it needs a second finger on `Shift`. The full stop is a plain, unshifted key almost
everywhere, and it sits right next to the `-` that zooms back out. If you are unsure which
key your keyboard wants, use that one — or the **Options ▸ Zoom level** menu, which never
depends on the keyboard at all.

## Menu bar

`Alt+<letter>` opens a top-level menu; the underlined letter in each name is the one
that works. **Lexicon** is a direct action rather than a submenu — its accelerator
opens the screen immediately. **Statistics** is a submenu: `Alt+S` then `S` opens the
screen.

| Menu | Accelerator |
|---|---|
| File | `Alt+F` |
| Edit | `Alt+E` |
| Learn | `Alt+L` |
| Statistics | `Alt+S` |
| Lexicon | `Alt+X` |
| Options | `Alt+O` |
| Help | `Alt+H` |

Once a menu is open, every item in it has its own underlined letter, unique within that
menu (but not necessarily across menus — the same letter can mean different things in
different menus). Switching **Options ▸ Language** changes every one of these letters
to their German equivalents; see [Settings](11-settings.md#appearance-and-language).

## Unit editor

| Key | Action |
|---|---|
| `F2` | Previous unit |
| `F3` | Next unit |
| `F5` | Search |
| `F6` | Jump to unit number |
| `F7` | Delete unit (confirm) |
| `F8` | Insert unit before the current one |
| `F12` | Mark the unit difficult in Direction 1, or remove its difficulty there |
| `Shift+F12` | Mark the unit difficult in Direction 2, or remove its difficulty there |
| `F10` | Done — keep changes |
| `Esc` | Cancel — confirm discard if anything changed |
| `Enter` / `Tab` | Next field |
| `Backspace` (on an empty field) | Previous field |

See [The unit editor](04-unit-editor.md) for what each of these does in detail.

Unlike in a learning session, `F12` and `Shift+F12` here do not write to disk at once:
the change is part of the pending edit and reaches the file only when you save. See
[Marking a unit difficult](04-unit-editor.md#marking-a-unit-difficult).

## Learning session

| Key | Action |
|---|---|
| `F3` or `Enter` | Check answer / Continue; at the end, Extend session |
| `F4` | Read the answer aloud again (the **Read aloud** button) |
| `F5` | Rating button 1 |
| `F6` | Rating button 2 |
| `F7` | Rating button 3 |
| `F9` | Cycle answer view: Correction → Solution → Your answer |
| `F10` | Reveal (in Level Learning at level 3: Hide & type, before Reveal) |
| `F12` | Mark the unit difficult in the direction being asked, or remove its difficulty there — before and after the answer is shown. After an automatic flag: none, manual, automatic back |
| `Esc` | Cancel session, back to setup |
| `Enter` / `Tab` | Next blank, in a multi-blank field |
| `Backspace` (on an empty blank) | Previous blank |
| `Arrow Down` | Next answer field |
| `Arrow Up` | Previous answer field |

See [Learning sessions](06-learning-sessions.md),
[Level learning](07-level-learning.md), and
[How answers are judged](08-answer-evaluation.md#rating-the-attempt) for what each
rating button means in a given situation.

`F4` plays exactly what automatic speech plays — the answer fields that may be read
aloud — whether automatic speech is switched on or not, and says nothing before the
answer is revealed. See
[Reading the answer automatically](15-speech.md#reading-the-answer-automatically).

`F12` writes the change to the deck file straight away. See
[Marking a unit difficult](06-learning-sessions.md#marking-a-unit-difficult).

## Options and Mask Editor

`Enter` activates the screen's Close/OK button, the same as clicking it. `Esc` (global,
above) cancels.
