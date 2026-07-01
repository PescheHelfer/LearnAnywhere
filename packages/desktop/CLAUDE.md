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
