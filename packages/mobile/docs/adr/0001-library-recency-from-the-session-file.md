# ADR-0001 (mobile) — The Library's order comes from the session file's modification time

**Status:** accepted (2026-09-20)
**Scope:** `packages/mobile` only. Nothing here changes a file format, and the desktop
shell has no Library to order.

## Context

The companion's **Library** is a live enumeration of an on-device folder, re-read every
time the learner opens the screen. It was ordered by deck name, which answers a question
nobody asks on a phone: a learner opening the app is almost always going back to the deck
they were working through, or to the one they imported a minute ago. Ordering by **when
each deck was last practised** puts both at the top and makes resuming a single tap.

That needs a timestamp per deck, and there was no obvious place for one. Three were
considered.

The first was to **store it**: add a "last practised" field to the statistics format. It
is additive, it is exact, and it is the answer a database would give. It is also a format
change — read by both shells, byte-compared by the core fixtures, and carried in every
`.sta` on every device from then on — bought to decide the order of rows on one screen of
one of the two apps. The file would then carry a fact about *the phone's list* rather
than about the learner's answers, which is not what the record is for.

The second was a **local preference map**: path to timestamp, in the companion's own
preference store, written when a session ends. That avoids the format change, but it
invents a second place where a deck's history lives and immediately has to be kept in
agreement with the first. It goes stale in every way this app can go stale — a deck
deleted outside the app, a deck re-imported under a new name, a preference store cleared
by Android while the library survives — and each of those leaves the list lying about
decks that are on screen.

The third is the one taken here. The companion **already writes a file every time the
learner rates a card**: saving the current statistics rewrites the deck's **session
file**, the `.sta` sidecar beside the `.vok`. Its modification time therefore already *is*
"last practised", maintained by the filesystem, for free, with no field to add and no
second copy to keep in step. A deck with no session file has never been practised, which
is exactly the condition the listing needs to put a freshly imported deck at the top.

## Decision

**The Library derives each deck's recency from the modification time of its session file,
read fresh on every listing. Nothing persists a "last practised" timestamp.**

*(Update, difficult-units ticket 01.)* The derivation itself now lives in core as the
shared `lastLearned` helper — the newest modification time among *all* of a deck's
statistics files (sidecar, timestamped session files, the lifetime file), so desktop's
recent-decks list agrees with the Library on what "last learned" means. Mobile only ever
writes the plain sidecar, so nothing above changes in practice: the helper still resolves
to that one file's timestamp here. The reasoning and the four rules stand unchanged.

Four rules follow:

1. **No session file means never practised**, and those decks sort **above** every
   practised deck. A deck imported thirty seconds ago is the one the learner came to the
   app to open; burying it under twenty decks with a history is the worst outcome on a
   phone.
2. **Practised decks sort newest first**, and equal times break the tie on the deck name,
   so two visits that changed nothing produce the same list and the rows do not reshuffle
   under the learner's finger.
3. **The recency never reaches the entry model and is never rendered.** No date appears
   in the Library, so nothing displayed needs to carry one; the order alone carries the
   meaning. `LibraryDeckSource` holds it on the way in, `LibraryDeckEntry` does not hold
   it on the way out.
4. **The order is fixed.** There is no sort control and no persisted sort preference.

## Consequences

Accepted, and worth knowing:

- **The timestamp is the filesystem's, not the app's.** Anything that rewrites the `.sta`
  without the learner practising — a restore from Android's automatic backup, a file
  copied by a tool — moves the deck up the list. On a private app-storage folder that
  only this app writes to, that is rare and harmless: the row is in the wrong place until
  the next session, and nothing else is affected.
- **Clearing a deck's statistics counts as practising it.** Clear stats writes the
  sidecar, so the deck jumps to the top rather than returning to the never-practised
  group. That is defensible — the learner just acted on that deck — and fixing it would
  mean storing the very timestamp this record exists to avoid.
- **Listing now stats one extra file per deck.** The listing already opens and decodes
  every `.vok` in the folder; one `exists` plus one `lastModified` beside each is not
  measurable against that.
- **Reversing this decision means a format change**, which is the point of writing it
  down. Anyone who wants exactness across backups and copies has to add the field that
  was rejected above, and should re-read the first alternative before doing so.

## Alternatives rejected

- **A "last practised" field in the statistics format.** Rejected above: a shared,
  byte-compared, cross-shell format change to order one screen, storing a fact about a
  list rather than about the learner's answers.
- **A local preference map of path to timestamp.** Rejected above: a second home for a
  deck's history, which goes stale against deletion, re-import under a new name, and a
  cleared preference store.
- **A package that reads richer file metadata.** Not needed — `dart:io` answers
  `lastModified()` on every platform the companion runs on — and the repo requires a new
  dependency to resolve on Linux and Android both before it may be added at all.
- **Leaving the order alphabetical and adding a sort control.** Rejected as a setting
  that exists to avoid making a decision. If the Library ever grows large enough for
  alphabetical lookup to be missed, the answer is search, not a toggle.
