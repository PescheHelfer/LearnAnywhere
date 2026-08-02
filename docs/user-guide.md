# User guide

The in-depth user documentation is **not** in this folder. It lives at:

- **English** — [`../packages/ui_kit/assets/help/en/00-index.md`](../packages/ui_kit/assets/help/en/00-index.md)
- **Deutsch** — [`../packages/ui_kit/assets/help/de/00-index.md`](../packages/ui_kit/assets/help/de/00-index.md)

Those are ordinary Markdown files; GitHub renders them, and so does the program itself
under **Help ▸ User guide** (`F1`).

## Why it lives there and not here

The guide is shipped *inside* the application, and a Flutter asset can only be declared
by the package that owns the file. Both shells — desktop and mobile — render the same
guide, so the one package both of them depend on is `ui_kit`, which is already the home
of the other shared asset, the bundled Lab Mono typeface.

Keeping a second copy under `docs/` would mean two files to update per change, with
nothing but discipline keeping them equal. One copy, linked from here, cannot drift.

## Editing it

- `en/` and `de/` must always hold the **same file names**. A chapter is added by
  dropping the file into both folders; the viewer discovers chapters from the asset
  manifest, so there is no list in Dart to update.
- Each file has exactly one `#` heading — that is its title in the contents list.
- `##` headings are the anchors, the search granularity, and the only scroll targets.
- UI labels quoted in the guide are copied verbatim from the matching catalog in
  `packages/core/lib/i18n/i18n.dart`, never translated freshly.

`packages/ui_kit/test/help_content_test.dart` enforces the first three, including that
every cross-chapter link and `#anchor` resolves.
