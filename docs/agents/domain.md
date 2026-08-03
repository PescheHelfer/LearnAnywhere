# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

This is a multi-context (melos monorepo) layout: `packages/core`, `packages/ui_kit`,
`packages/desktop`, and `packages/mobile` are separate contexts, each already carrying
its own `CLAUDE.md`-level conventions where relevant.

## Before exploring, read these

- **`CONTEXT-MAP.md`** at the repo root — it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`** at the repo root — system-wide decisions. Also check `packages/<context>/docs/adr/` for context-scoped decisions in the package you're about to work in.

If any of these files don't exist yet, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## File structure

```
/
├── CONTEXT-MAP.md
├── docs/adr/                          ← system-wide decisions
└── packages/
    ├── core/
    │   ├── CONTEXT.md
    │   └── docs/adr/                  ← context-specific decisions
    ├── ui_kit/
    │   ├── CONTEXT.md
    │   └── docs/adr/
    ├── desktop/
    │   ├── CONTEXT.md
    │   └── docs/adr/
    └── mobile/
        ├── CONTEXT.md
        └── docs/adr/
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in the relevant `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
