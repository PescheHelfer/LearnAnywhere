# learn_anywhere_ui_kit

Shared Flutter layer of [Learn Anywhere](../../README.md), used by both the desktop and
the mobile shell: themes and design tokens, the localization adapter, rich-text
rendering, field-row widgets, the ALT-mnemonic menu labels, and the user-guide viewer.

It also owns the bundled assets, because a Flutter asset can only be declared by the
package that owns the file and both shells need these:

- `assets/fonts/` — the Lab Mono typeface, pinned so fixed-width layouts measure the
  same on every host.
- `assets/help/en/`, `assets/help/de/` — the user guide. See
  [`docs/user-guide.md`](../../docs/user-guide.md) before editing it.

Run its suite with `flutter test` from this directory.
