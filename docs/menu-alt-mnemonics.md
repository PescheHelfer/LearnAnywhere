# Desktop menu ALT mnemonics — how it works and how to keep it working

This document explains the ALT-mnemonic (access-key) system in the desktop menu
bar so it survives future menu changes (renames, reordering, new menus/submenus).
**Read this before editing the menu bar in
[`packages/desktop/lib/main.dart`](../packages/desktop/lib/main.dart).**

## Why there is custom code (do not "simplify" it away)

Flutter's `MenuAcceleratorLabel` registers every `Alt+<letter>` into a **single,
app-wide `ShortcutRegistry`**. Its only scoping is that a `SubmenuButton`
suppresses *its own* accelerator while *its* submenu is open. It does **not**
suppress sibling **closed** top-level menus. So with the stock widget, while the
File menu is open every other top-level menu (Edit, Options, …) keeps its
`Alt+<letter>` registered and competes — in the same global registry — with the
open submenu's items. Result: pressing e.g. `Alt+O` while File is open opens the
**Options** menu instead of activating File's item on `O` (and in debug the
registry even throws on exact duplicate activators).

To get correct, Windows-style behavior (type a letter to pick an item in the open
menu; use Left/Right arrows to move between menus) we **scope the top-level
accelerators ourselves** instead of letting the framework register them globally.

## The two patterns

There are exactly two kinds of menu entries. Use the right one:

### Top-level bar entries → `MenuAcceleratorDisplayLabel` + gated shortcut

Top-level entries (File, Edit, Learn, Statistics, Lexicon, Options, Help — the
first three plus Options/Help are dropdowns, Statistics and Lexicon are direct
actions) must
**not** use `MenuAcceleratorLabel` — that would register them globally and
re-introduce the bug. Instead:

- Their `child:` is a
  [`MenuAcceleratorDisplayLabel`](../packages/ui_kit/lib/src/menu/menu_accelerator_display_label.dart)
  — it renders the access-letter highlight while ALT is held but registers **no**
  shortcut.
- Opening/activating them is done by `_handleMenuAccelerator`, a
  `HardwareKeyboard` handler in `main.dart`. It looks up the pressed letter in
  `_topLevelAccelerators` (a `char -> action` map rebuilt every `build()` from each
  top-level label's `&` marker) and invokes the action. It is **gated**: it returns
  early (does nothing) whenever `_menuActive` is true, so once a menu opens only
  that menu's items own `Alt+<letter>`.
- **Why a `HardwareKeyboard` handler and not `CallbackShortcuts`/`Shortcuts`:** on
  Windows a `HardwareKeyboard` handler's return value is what tells the embedder
  the key was *handled*, which suppresses the system "ding". The same handler also
  swallows the bare **left** Alt key so Windows never enters "menu mode" (the other
  source of the ding). It deliberately leaves **right** Alt (AltGr) alone — German
  keyboards need it to type `@ € { }`, etc. — and ignores AltGr combos (reported as
  Control+AltRight).
- "Is a menu open?" is tracked by `_openMenuCount`, incremented/decremented by the
  `onOpen`/`onClose` callbacks wired onto the five top-level **submenus** (File,
  Edit, Learn, Options, Help). The two direct-action entries
  (Statistics/Lexicon) have no submenu and do not affect the count.
- The two direct-action entries are bare `MenuItemButton`s; they are given a
  `FocusNode(skipTraversal: true)` so the `MenuBar`'s Left/Right arrow navigation
  skips over them (they have no submenu to open) and jumps to the next
  submenu-bearing menu instead of stalling. They stay reachable via their Alt
  accelerator and the mouse.

### Submenu items → `MenuAcceleratorLabel`

Everything inside a dropdown (`MenuItemButton`, `RadioMenuButton`,
`CheckboxMenuButton`, and nested `SubmenuButton`s like Theme/Language) keeps using
the stock `MenuAcceleratorLabel(..., builder: menuAcceleratorBuilder)`. While a
menu is open the gated top-level layer is disabled, so these items have exclusive
ownership of `Alt+<letter>` and there are no collisions or duplicate-registration
crashes.

## Checklist: adding a new TOP-LEVEL menu

1. Build it as a `SubmenuButton` (dropdown) or `MenuItemButton` (direct action) in
   `_buildMenuChildren`.
2. For a dropdown: give it a `MenuController` field and wire
   `onOpen: _onMenuOpened, onClose: _onMenuClosed`. For a direct-action
   `MenuItemButton`: give it a `FocusNode(skipTraversal: true)` field (and dispose
   it) so arrow navigation skips it.
3. Set its `child:` to `MenuAcceleratorDisplayLabel(messages.message(...))`
   (**not** `MenuAcceleratorLabel`).
4. Add it to the `entries` list in `_buildTopLevelAccelerators` with its action
   (`() => _xMenuController.open()` for a dropdown, or `() => _selectRoute(...)`
   for a direct action).
5. In the i18n catalog give its label an `&` marker with a `// top-bar X` comment.
   The letter must be **unique among the top-bar letters** (currently
   EN: F E L S X O H — DE: D E L S X O H).

## Checklist: adding a SUBMENU item

1. Use `MenuAcceleratorLabel(messages.message(...), builder: menuAcceleratorBuilder)`
   as the item's `child:`.
2. In the i18n catalog add an `&` marker with a `// X` comment.
3. The letter only needs to be **unique within that one submenu** — it may freely
   reuse a top-bar letter (that is the whole point of the scoping; the top bar is
   suppressed while the submenu is open). Keep existing assignments stable.
4. **Nested-submenu caveat (e.g. the Options → Theme/Language/Statistics
   subtree):** Flutter keeps a parent menu's *leaf* items and its *closed
   sibling submenu labels* registered while a deeper submenu is open. So a
   Theme/Language/Statistics item letter must also avoid the active
   Options-level letters (Advanced Learning Options plus the Theme, Language,
   and Statistics submenu labels themselves) and the closed sibling label
   (e.g. Language's letter while Theme is open, and vice-versa). See the
   `// Y (avoids S = Sprache label)` style notes in the DE catalog for worked
   examples. The same rule nests one level further for items *inside*
   Statistics (auto-load/auto-save/keep-last-N): they must also avoid Theme's
   and Language's own letters, not just their submenu's.

## Shared-string rule

If a menu label string is **also** rendered somewhere else as plain text (e.g. the
statistics action strings appear both in the File menu and as buttons on the
Statistics page), then adding an `&` would show a literal ampersand at the other
site. Either leave that string unmarked, or wrap it in
`MenuAcceleratorLabel.stripAcceleratorMarkers(...)` at every plain-text render
site. (As of this writing the shared `statisticsLoad/Save/Clear` and
`fileSaveStatsAs` strings are intentionally left unmarked.)

## Known Windows beep fix

Even though the ALT-mnemonic scoping above makes the correct menu open or
item activate, Windows itself still plays its system "ding" (`MessageBeep`)
on every `Alt+<letter>` press by default. This cannot be fixed from Dart:
Flutter's Windows embedder's `KeyboardManager` deliberately never marks a "sys"
key message (`WM_SYSKEYDOWN`/`WM_SYSCHAR`) as handled, so the OS always sees it
regardless of what a `HardwareKeyboard` handler returns (see the framework's own
comment: "SYS messages must not be consumed by HandleMessage so that they are
forwarded to the system"). Since this window has no native `HMENU` (the whole
menu bar is Flutter-drawn), `DefWindowProc`'s default `WM_SYSCHAR` handling has
no accelerator to match and calls `MessageBeep` unconditionally.

The fix lives in the native runner:
[`packages/desktop/windows/runner/flutter_window.cpp`](../packages/desktop/windows/runner/flutter_window.cpp)
intercepts `WM_SYSCHAR` and swallows it (returns `0`, skipping
`DefWindowProc`) whenever the character is one of our registered `&`
accelerator letters — collected from every top-level and submenu label, EN and
DE, into the `kMenuAcceleratorChars` constant in that file. It also handles
`WM_MENUCHAR` defensively (returns `MNC_CLOSE`), though that message should
never actually fire here since the window never enters Windows' native
menu-tracking loop (see the `WM_SYSCOMMAND`/`SC_KEYMENU` case in the same
file).

**`kMenuAcceleratorChars` must be kept in sync by hand** with the `&`-prefixed
accelerator letters in
[`packages/core/lib/i18n/i18n.dart`](../packages/core/lib/i18n/i18n.dart) —
update it whenever a menu label's accelerator letter changes there. Alt+letter
combinations that aren't one of these registered accelerators still beep,
which is expected (there is nothing for them to activate). AltGr combinations
(German `@ € { }` etc.) are unaffected either way, because Windows reports
them as Control+AltRight, which routes them through ordinary `WM_CHAR` instead
of the `WM_SYSKEYDOWN`/`WM_SYSCHAR` "sys" path this fix hooks into.

## Verifying after a change

Run the app (`flutter run -d windows` from `packages/desktop`) in **both** DE and
EN and confirm:

- ALT alone underlines the top-level letters; `Alt+<top letter>` opens/activates
  that menu.
- With a submenu open, `Alt+<item letter>` activates that item and does **not**
  fall through to a top-level menu sharing the letter (test a letter that a
  submenu item and a top-bar menu share, e.g. File ▸ Save `S` vs Statistics `S`).
- Left/Right arrows switch between open top-level menus.
- No menu label shows a literal `&`.
- `flutter analyze` is clean.
