# packages/desktop — Claude notes

Cross-platform rules (never edit the other OS's runner, path/case/font/line-ending
constraints) live in the repo-root [`CLAUDE.md`](../../CLAUDE.md) — read it before
touching `windows/`, `linux/`, or anything path- or font-related.

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

## Bumping the app version

Whenever the app version changes, update both of these together — never just one:

- `version:` in `pubspec.yaml` (`X.Y.Z+B`; this also drives the Windows exe's
  `FileVersion`/`ProductVersion` automatically at build time, no `Runner.rc` edit
  needed).
- The version history in the About box: add a new `aboutVersionNNN` entry to the
  `LearnAnywhereMessage` enum and both catalogs (EN + DE) in
  `packages/core/lib/i18n/i18n.dart`, then prepend it (newest first) to the
  `labels` list in `packages/desktop/lib/src/about/about_page.dart`.
- The version string asserted by the About test in `test/widget_test.dart`
  ("help about shows legacy and conversion credits"). It pins the **newest**
  entry on purpose, so it fails loudly when a bump forgets the two steps above.
  Don't "fix" it by pointing it at an older version: the history is a
  fixed-height lazy `ListView` that only builds its first ~3 rows, so an older
  entry stops existing in the widget tree as soon as newer ones push it down.

- `app_info.version` in
  [`packaging/linux/AppImageBuilder.yml`](../../packaging/linux/AppImageBuilder.yml).
  Nothing derives it from `pubspec.yaml`, and no test or build on Windows reads
  it, so it drifts silently and only shows up in the shipped AppImage's
  metadata.

Also update the root `README.md` "Status" line, which names the current desktop
version. Tagging and the two-product version split are covered in the root
[`CLAUDE.md`](../../CLAUDE.md) under "Versions and tags".

Grep for the **outgoing** version (the one being replaced), not the incoming one,
when hunting for stragglers — searching for the new number finds nothing by
definition, which is how the AppImage version silently sat a release behind.

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
