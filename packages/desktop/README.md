# learn_anywhere_desktop

The Windows and Linux application of [Learn Anywhere](../../README.md) — the
full-featured shell: file operations, the unit and mask editors, learning sessions,
statistics, the lexicon, and the menu bar.

Build and run from this directory with `flutter run -d windows` or
`flutter run -d linux`, and `flutter test` for the widget suite.

Read [`CLAUDE.md`](CLAUDE.md) here before touching the menu bar, the version number, or
either the `windows/` or `linux/` runner directory — only build the target you are
sitting on, and never regenerate a platform folder.

Note that the native binary is named `LearnAnywhere` while this pub package is
`learn_anywhere_desktop`; every `package:learn_anywhere_desktop/...` import depends on
the latter. They are not meant to match.
