# Learn Anywhere documentation

This folder holds **living developer reference** — documents that describe how the
project works today and that the code or the build depends on staying accurate.

| Document | What it is |
|---|---|
| [`build-specification.md`](build-specification.md) | The product specification the whole build derives from: domain model, file formats, business rules, per-shell app specs, and Appendix A's record of the legacy program's screens. |
| [`file-formats.md`](file-formats.md) | The `.inf` / `.vok` on-disk contract — identity conventions, id spaces, ordering rules. Anything reading or writing Learn Anywhere data conforms to this. |
| [`menu-alt-mnemonics.md`](menu-alt-mnemonics.md) | How the desktop ALT-mnemonic system works and why Flutter's `MenuAcceleratorLabel` cannot be used. Five source comments link here; keep it current. |

## What is deliberately not here

- **Test fixtures.** The canonical `example.inf` / `example.vok` live in
  `packages/core/test/fixtures/`, next to the test that compares them byte-for-byte.
  Anything a test reads belongs under its own package's `test/fixtures/`.
- **Architecture.** [`../ARCHITECTURE.md`](../ARCHITECTURE.md) at the repo root.
- **Cross-platform working rules.** [`../CLAUDE.md`](../CLAUDE.md), and
  [`../packages/desktop/CLAUDE.md`](../packages/desktop/CLAUDE.md) for the desktop shell.
- **Project history** — requirements lineage, playtest feedback rounds, implementation
  prompts, code audits, and the legacy reference screenshots. These are source material
  rather than documentation, and they are kept in the maintainer's local project
  archive outside the repository. Appendix A of `build-specification.md` is the
  normative record of what the screenshots contribute, so nothing here depends on them.
