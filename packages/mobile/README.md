# learn_anywhere_mobile

The Android companion to [Learn Anywhere](../../README.md): a read-only learner for
decks authored on the desktop. Early stage and not released yet.

It depends on `core` and `ui_kit` only — **never** on `desktop`. Any file or path
behaviour it needs belongs in `core`, behind the shared API, so all three shells derive
paths identically.

One widget-test failure here is a known baseline; confirm a failure reproduces at `HEAD`
before treating it as new.
