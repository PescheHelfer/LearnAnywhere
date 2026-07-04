# packages/desktop — Claude notes

## Menu bar ALT mnemonics (read before editing the menu in `lib/main.dart`)

The top-level menu accelerators are scoped by custom code, **not** by Flutter's
default `MenuAcceleratorLabel` (which registers globally and makes closed top-level
menus steal `Alt+<letter>` from the open submenu's items). Two patterns:

- **Top-level bar entries** (File/Edit/Learn/Statistics/Lexicon/Options/Help): use
  `MenuAcceleratorDisplayLabel` for the label (renders the underline, registers no
  shortcut) and add the entry to `_buildTopLevelAccelerators`. Opening/activation
  goes through `_handleMenuAccelerator` (a `HardwareKeyboard` handler — needed so
  the key is marked handled and Windows doesn't "ding"; it also swallows bare
  left-Alt but leaves AltGr alone), gated by `_menuActive` / `_openMenuCount`. Wire
  `onOpen: _onMenuOpened, onClose: _onMenuClosed` + a `MenuController` on top-level
  **submenus**; give direct-action top-level `MenuItemButton`s a
  `FocusNode(skipTraversal: true)` so arrow nav skips them.
- **Submenu items**: use the stock `MenuAcceleratorLabel(..., builder:
  menuAcceleratorBuilder)`. Their letters only need to be unique within their own
  submenu (top-bar letters may be reused).

When adding/renaming/reordering menus, follow the checklists and letter-assignment
rules in [`../../docs/menu-alt-mnemonics.md`](../../docs/menu-alt-mnemonics.md),
and keep the inline `// top-bar X` / `// X` mnemonic comments in the i18n catalog
(`packages/core/lib/i18n/i18n.dart`) accurate.

## Keep `test/*.dart` in sync with UI drift

Widget tests here find things by exact string/key, so they silently rot when the UI
changes. **After any change that could break a finder, run `flutter test` in this
package and fix every file that fails to compile or fails an assertion — don't just
fix the file you were touching.** `flutter test` shares one compiler process across
all test files in a run: one file with a stale required-constructor-arg can make an
unrelated, still-correct test file report as "failed to load" too — check each
failure's own error text before assuming it's actually broken.

Changes with the most breaking potential:
- Adding/renaming a **required** constructor param on a page widget instantiated
  directly by a test (`LearnAnywhereDesktopApp`, `StatisticsPage`, `LexiconPage`,
  `MaskEditorPage`, `QueryOptionsPage`, ...) — compile error in that widget's test.
- Moving a menu command between top-level and a submenu, or renaming/removing an
  i18n message used in `find.text(...)` — breaks `widget_test.dart` taps/asserts.
  (Note: `MenuAcceleratorLabel`/`MenuAcceleratorDisplayLabel` render as plain
  `Text` with `&` stripped when ALT isn't held, so `find.text('Label')` — no `&`,
  no `findRichText: true` — is the correct finder; don't add rich-text finders.)
- Removing/renaming a `ValueKey` a test uses via `find.byKey(...)`.
- Swapping a screen's root scrollable type (e.g. `ListView` → `SingleChildScrollView`)
  — breaks `find.byType(...)` drags.
- Widening a screen's default layout — can overflow the default 800×600 test
  surface; widen it in the test via `tester.view.physicalSize` instead of shrinking
  the UI.
