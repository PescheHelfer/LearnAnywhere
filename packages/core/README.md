# learn_anywhere_core

Pure Dart core of [Learn Anywhere](../../README.md). Holds the domain model, the
`.inf` / `.vok` / `.sta` serialization and validation, the learning engines, mask
compatibility, path helpers, settings, and the English and German message catalogs.

**This package must never import Flutter.** Both shells depend on it, so anything a
shell needs about paths, formats or learning rules belongs here rather than in the
shell, and is tested against `p.windows` and `p.posix` alike.

Run its suite with `melos run test:core`, or `dart test` from this directory.
