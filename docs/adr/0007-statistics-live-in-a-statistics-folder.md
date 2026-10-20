# ADR-0007 — Statistics live in a statistics folder

**Status:** accepted (2026-10-19)
**Scope:** system-wide — `packages/core` derives the paths (`DeckPaths`), `packages/desktop`
is the only shell that reads and writes there. Android's private library is exempt.

## Context

Until desktop 1.2.0 every `.sta` the desktop wrote sat beside its deck: one **session
file** per learning session that wrote statistics, plus the deck's **all-time
statistics**. A folder of twenty decks quickly showed a hundred files, most of which the
learner never opens by hand, and the decks they do care about were hard to find among
them. The vocabulary is pinned in
[`../../packages/core/CONTEXT.md`](../../packages/core/CONTEXT.md).

Moving the files raises the questions that make it more than a rename: whether the old
location is still read, whether existing files are moved for the learner, and what the
lifetime record's write authority ([ADR-0001](0001-all-time-statistics-accumulate-live-deltas.md))
compares once the path changes.

## Decision

**A deck's session files and its all-time statistics live in the subfolder named
`statistics` beside the deck — `French/mydeck.vok` keeps its lifetime record at
`French/statistics/mydeck_alltime.sta` — and that folder is the only place they are
looked for.**

- **One location.** Writing a session file, writing the lifetime record on every answer,
  auto-loading the newest session file, *Keep last N* pruning, the lifetime read on open
  and the **last learned** date all use the statistics folder. File names inside it are
  unchanged.
- **The name is fixed:** `statistics`, lower case, never translated. A deck folder shared
  between Windows and Linux, or between an English and a German learner, then means the
  same folder to every one of them.
- **Created by writing, never by reading.** The first statistics write for a deck creates
  the folder; opening or browsing a deck leaves its folder as it was.
- **No fallback and no migration.** Nothing reads, moves or warns about a `.sta` left
  beside a deck. A deck whose lifetime file is only there opens as a deck with no lifetime
  record yet.
- **Android's sidecar is exempt.** The phone's single `<deck>.sta` stays beside the deck
  in the app's private library, which no learner sees and which never holds more than one
  statistics file per deck. Its path helper does not change.
- **Write authority is untouched.** A lifetime record may still create a file anywhere
  and replace one only where it was read. Both sides of that comparison are derived from
  the deck path by the same helpers, so moving the file moves both together; the save-as
  refusal holds exactly as before.

## Consequences

- **Statistics beside a deck are invisible to 1.2.0.** Until they are moved into
  `statistics/`, auto-load offers nothing, the Recent decks list shows the deck as not
  learned, and the first answer starts a fresh lifetime record in the new folder rather
  than adding to the old one. The user guide says plainly that only the statistics folder
  is read.
- **Versions before 1.2.0 will not find the files.** An older build still running against
  a synced folder reads and writes beside the deck again, where 1.2.0 never looks, and the
  two histories drift apart silently. Every machine sharing a deck folder has to be
  updated together.
- **The Lexicon's recursive folder search walks into statistics folders** and finds
  nothing there, because it keeps only decks.
- **A loaded deck's statistics dialogs can start in the folder,** which is a separate
  change on top of this one.

## Alternatives rejected

- **A fallback read beside the deck.** It would keep old files working, but two places to
  look means two places that can disagree, and a stale lifetime file beside the deck
  could quietly be preferred over the live one, or be written over by a record that never
  read it.
- **A one-off migration on open.** Moving a learner's files is the one thing this program
  must never get wrong, and the code would have to be written, tested and carried forever
  for a move the maintainer can make by hand once.
- **Detecting old files and warning.** Cheaper than a migration, but still a permanent
  read of the old location for a transition that ends the day the files are moved.
- **A translated or configurable folder name.** It would split one shared deck folder
  into one statistics folder per interface language or per setting.
- **Moving Android's sidecar too.** It lives where no learner looks and holds one file per
  deck, so there is no clutter to clear, and moving it would need a phone release and a
  migration of its own for no benefit.
