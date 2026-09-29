# Settings

Everything configurable lives under the **Options** menu (`Alt+O`), plus the Level-name
editor covered in [Level learning](07-level-learning.md#naming-the-levels). This
chapter lists every option and, at the end, where each kind of setting is actually
stored on disk.

## Learning options

**Options ▸ Advanced Learning Options** — every option here applies the next time you
check an answer; changing one mid-session takes effect immediately.

| Option | Default | Effect |
|---|---|---|
| Wrong input correctable | On | Offers "Actually correct" on a wrong answer's rating row |
| Complete input required | On | Every non-empty solution field must be answered for a match |
| Case sensitive | On | Distinguishes upper/lower case when matching |
| Accent sensitive | On | Distinguishes accented characters when matching |
| Accept near-misses as 'Almost' | Off | Enables the Almost outcome |
| 'Almost' similarity threshold (%) | 80 | How close a near-miss must be to count as Almost |
| Show clock | Off | Shows elapsed time during a session |
| Time limit (seconds) | 0 (no limit) | Caps how long a session may run |
| Minimum-attempts guard | Off | See below |
| Minimum attempts | 2 | Value for the guard above |
| Wrong-answer ceiling | Off | See below |
| Wrong-answer ceiling value | 10 | Value for the ceiling above |

The matching, near-miss and guardrail options are explained in full in
[How answers are judged](08-answer-evaluation.md). Direction, mode, shuffle, mastery
threshold, and whether answers must be typed at all are set on the
[practice setup screen](06-learning-sessions.md#setting-up-a-session) instead, since
they describe a session rather than how one answer is judged.

## Appearance and language

**Options ▸ Theme** — **System**, **Light**, **Dark**, **Dark Blue** (the default) or
**Light Blue**.

**Options ▸ Language** — **English** (the default) or **German**. This switches every
label in the program, including menu ALT-mnemonics — a letter that opens a menu in
English may not be the same letter in German — and this guide itself, which follows the
same setting.

## Zoom level

**Options ▸ Zoom level** resizes the whole program: **75%**, **100%** (the default),
**125%**, **150%**, **175%** or **200%**. The larger levels are for reading comfortably
from your usual seating distance on a big monitor; **75%** goes the other way, for fitting
more of a wide deck on screen at once. The current level is ticked in the menu. It applies
to every screen and to the menu bar, and it is remembered, so you set it once.

`Ctrl` and `+` steps up a level, `Ctrl` and `-` steps down one, and `Ctrl+0` returns to
100% — the same keys as in most other programs. Where `+` is awkward to reach, **`Ctrl`
and `.`** steps up as well: the full stop needs no `Shift` and no numeric keypad, and it
sits next to the `-` that steps back down. On a Swiss keyboard, where `+` is the shifted
`1`, `Ctrl+Shift+1` steps up too. They step between the six offered levels
rather than growing the text a little at a time, so you always land on a size that has
been laid out and tested. These are the only `Ctrl` shortcuts in the program; everything
else is a function key or an `Alt` mnemonic. The levels are also the one menu whose items
have no underlined letter: six percentages simply do not contain six different digits
between them, so they are picked with the arrow keys, the mouse, or these shortcuts.

Zoom is never applied for you. It does not follow the deck, and it does not follow your
operating system's own display scaling — if you have already scaled your desktop, the two
add up, which is usually what you want.

A field's box grows with the text inside it, so a longer field stays a longer box and
nothing is cut off at any level. The small `F3`/`Esc` captions under the buttons follow
the level too. What does *not* change size is the fixed chrome around the text: icons and
the spacing inside buttons. At 200% the interface is therefore a little tighter around
its text than at 100%. If a screen that used two side-by-side columns runs out of room —
the Mask Editor is the one that does — it stacks them instead, exactly as it does in a
narrow window.

At 75% it is the text that shrinks; the boxes and controls holding it keep their normal
size, because the arrows and icons inside them do not shrink and would otherwise be
squeezed out. So 75% buys you room by making the words smaller, not by making the whole
interface smaller.

## Centred content frame

**Options ▸ Centred content frame** puts each screen's content into a *content frame* — a
box of its own, sitting in the middle of the window — instead of pinning it to the top-left
corner. On a maximised window on a large monitor that is the difference between reading from
the middle of the screen and holding your gaze on one corner for a whole sitting. It is on
from the start, and unticking it gives you the old full-width layout back.

Centring is sideways only. The content still starts at the top of the window, deliberately:
the line telling you whether an answer was right appears and disappears as you work, and a
frame centred top-to-bottom as well would make the whole mask jump on every answer.

The frame is as wide as the deck you have open needs, and no wider. It is sized from the
widest field your mask can show, so a mask that would have fitted never has to be scrolled
sideways. It is the same width while learning and while editing the same deck, so nothing
moves when you switch between the two.

The **Mask Editor** is sized the same way, but from its own **Fields** table rather than
from the deck: its columns decide how wide the frame is, so a window wide enough to show
them all no longer leaves the table scrolling sideways.

A deck of short fields therefore gets a narrow frame, and the rows of buttons underneath
simply wrap onto a second line inside it — which is what they do in a narrow window too. The
one thing the frame will not do is squeeze a button, or either group of the evaluation pills,
to make it fit: it never goes narrower than the widest single one of those.

Three screens are never framed, whatever this setting says. The **workspace** and the status
screen shown after a file operation are each a heading over a few lines of text: centring
those leaves them adrift in the middle of an empty screen rather than looking laid out, so
they keep the top-left corner. The **About** box is already narrow and centred by itself, so
there is nothing for a frame to do.

The **lexicon** is framed like everything else. Its results table is the widest thing in the
program, but it already scrolls sideways inside its own box, so the frame only means it starts
doing that a little sooner.

Make the window narrower than the frame and the frame simply becomes the window: the margins
disappear and everything behaves exactly as it did before, with the mask scrolling sideways
inside its own box if it genuinely does not fit. The page itself never grows a horizontal
scrollbar at any window size. The frame follows the zoom level too, since a zoomed mask needs
more room.

## Speech

**Options ▸ Speech...** is where you choose which of your computer's voices reads each
language, and how fast. The whole screen is covered in [Speech](15-speech.md#choosing-a-voice);
what belongs here is where the settings live and what they cover.

The screen lists one language per row: the languages the open deck's mask uses, plus any you
have already chosen a voice for. Each row offers that language's installed voices and a
speaker button that reads a sample phrase aloud, so you can hear a voice before you pick it.
A row for a language your machine has no voice for says so instead, and the chapter above
explains how to add one.

**Read the answer aloud automatically** is the one switch that lets the program speak
without being asked: with it ticked, every revealed answer is read out. It is off until you
switch it on, and
[Reading the answer automatically](15-speech.md#reading-the-answer-automatically) covers
what it plays and when.

**Speech rate** applies to every single thing the program says — the sample phrases on this
screen included — and is the setting worth reaching for first in a language you barely know.

Voice choices are stored **per machine and never in the deck**: your deck says a field is
French, and each computer decides which of its French voices says it. Copy a deck to another
computer and it carries no voice names with it.

The entry is absent on a machine that cannot speak at all — **Linux** today — rather than
present and doing nothing.

## Statistics options

**Options ▸ Statistics** holds auto-load, auto-save and the session-file retention
count. They are covered in
[Working with files](03-managing-files.md#auto-load-and-auto-save), and concern session
files only. The deck's lifetime record is kept whatever these are set to — see
[The two records](09-statistics.md#the-two-records).

## Difficult units

**Options ▸ Difficult units...**, directly under the Statistics submenu, decides how the
program finds the units you keep getting wrong when a session ends, as described in
[Difficult units found automatically](06-learning-sessions.md#difficult-units-found-automatically):

| Setting | Range | Default |
|---|---|---|
| **Flag difficult units automatically when a session ends** | on / off | on |
| **Minimum wrong answers** | 1–10 | 2 |
| **Minimum wrong rate in %** | 10–90 | 33 |
| **Attempts that count without a correct answer** | 3–20 | 6 |

- A number outside its range gets a note under it, and **OK** stays unavailable until
  you correct it. **Reset to defaults** puts the three numbers back to 2, 33 and 6; it
  leaves the switch as it is.
- The choice belongs to this computer, like the other settings in the settings file, and
  applies to every deck you open on it.
- Saving changed numbers, with detection switched on and a deck open, leads straight to
  the warning of **Recompute automatic flags...**, because the flags the deck carries
  were set by the old numbers. **Continue** rebuilds them by the new ones
  (see [Recomputing and removing flags](09-statistics.md#recomputing-and-removing-flags));
  **Cancel** keeps them, and the new numbers apply from the next session end on. While
  the **Unit editor** is open you are asked to leave it first instead, and can run the
  command from **Statistics ▸ Manage difficult units** afterwards.
- Switched off, a session end flags nothing, and **Recompute automatic flags...** cannot
  be chosen. The flags already set stay, manual and automatic alike,
  and you can still mark and unmark units yourself. Switching it off is also the way to
  keep a session from writing flags into a deck you are only trying out.

## Start folder

**Options ▸ Start folder...** points every file dialog at one folder of your choosing:
decks, statistics files and masks alike. The prompt shows the folder currently set, if
any; **Choose folder...** opens a folder picker, **Clear start folder** removes the
setting again.

With a start folder set, every Load and Save dialog opens there — whatever folder you
last saved in. That is the point of it: the folder your decks live in stays one click
away no matter where the last file went. Clearing the setting restores the normal
behaviour at once, with no restart: each dialog opens again where you last used that
kind of file, because those folders are remembered underneath the whole time.

If the start folder is gone — deleted, renamed, or on a drive that is not connected —
the dialog still opens, at the remembered folder instead. A folder that has vanished
never blocks a dialog. The setting itself is kept, and the prompt says the folder cannot
be reached, so a drive that comes back puts it in force again with nothing to redo.

One dialog deliberately ignores the setting: **Edit ▸ Update other copies of this
mask...** keeps starting at the open deck's own folder, which is a better place to scan
for copies of that deck's mask than any fixed folder.

## Where settings live

Two separate stores, both entirely local — nothing here is ever sent anywhere:

- Your **learning options**, level names, speech choices, difficult-unit detection, the
  session-file retention count, and last-used deck/mask paths are written to
  `learn_anywhere.settings.json` in a `LearnAnywhere` folder under your operating
  system's standard per-user configuration location (`%APPDATA%` on Windows;
  `$XDG_CONFIG_HOME` or `~/.config` on Linux).
- **Theme, language, the zoom level, the content frame, the start folder, recent-folder
  memory, auto-load/auto-save toggles, and the window's size and position** are kept in the
  operating system's own application preferences store, separately from the file above.

Neither file needs to be touched by hand — everything in it is reachable from the menus
described in this chapter — but both are plain, readable text if you ever want to look.
