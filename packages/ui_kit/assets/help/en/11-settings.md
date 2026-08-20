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

## Statistics options

**Options ▸ Statistics** holds auto-load, auto-save, and the session-file retention
count, all covered in [Working with files](03-managing-files.md#auto-load-and-auto-save).

## Where settings live

Two separate stores, both entirely local — nothing here is ever sent anywhere:

- Your **learning options**, level names, and last-used deck/mask paths are written to
  `learn_anywhere.settings.json` in a `LearnAnywhere` folder under your operating
  system's standard per-user configuration location (`%APPDATA%` on Windows;
  `$XDG_CONFIG_HOME` or `~/.config` on Linux).
- **Theme, language, recent-folder memory, auto-load/auto-save toggles, and the
  window's size and position** are kept in the operating system's own application
  preferences store, separately from the file above.

Neither file needs to be touched by hand — everything in it is reachable from the menus
described in this chapter — but both are plain, readable text if you ever want to look.
