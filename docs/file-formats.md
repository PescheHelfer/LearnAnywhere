# Learn Anywhere file-format contract (`.inf` / `.vok` / `.sta`)

The canonical, authoritative examples of the current on-disk format live in
`packages/core/test/fixtures/` as `example.inf` and `example.vok`. They sit
beside the test that reads them rather than in this folder, because they are a
test fixture first and an illustration second.

They are produced by the real serializers in `packages/core/lib/serialization/`
(regenerate with `dart run tool/generate_format_examples.dart` from
`packages/core`), and the core round-trip test asserts they re-encode
byte-for-byte. **The Converter must conform to what is described here — not the
other way around.**

Both files are human-readable UTF-8 JSON. There is no database.

## Identity conventions

- **`maskId`** — an opaque unique string. Two files describe "the same mask" iff
  their `maskId`s are equal. This app mints new ids as `m_new_` + a v4 UUID and
  only ever *reads* the id of a file it did not create; it never recomputes one.
  The Converter must mint legacy ids as **`m_legacy_` + hash** so app-minted and
  converter-minted ids can never collide. Never emit an `m_legacy_` id from a
  non-converter tool, and never emit an `m_new_` id from the Converter.
- **`revision`** — a monotonic integer, bumped on each `.inf` save. Optional on
  read (defaults to `0`).
- **Category `id`** — a 0-based integer, unique among the mask's categories.
- **Field `id`** — a 0-based integer, unique across the **entire mask** (a single
  id space spanning all categories — note ids `0..5` span two categories in the
  example). Assigned once at creation, **never reused** (deleting does not
  recycle; next id is `max existing + 1`), **never renumbered** by reordering.
- **Order = array position.** Category and field display order is the order of
  the `categories` / `fields` arrays. There is no separate sort key. Reordering
  or renaming never changes ids, so unit→category and unit→field links survive.

## `.inf` (mask) — `example.inf`

Top-level `format` is `learn-anywhere/mask`, `version` `1`, then the mask body:
`maskId`, `revision`, `name`, `direction1Label`, `direction2Label`, and
`categories`. Each category has `id`, `name`, `fields`; each field has `id`,
`name` (empty = hidden), `length` (1..80), `equalGroup` (0 = positional; equal
non-zero groups are interchangeable answers), and `role1`/`role2` (`Q`/`A`/`R`).

A field may additionally carry the two **speech** keys, seen on field `1` of the
example:

- **`language`** — the spoken language of that field's values as a BCP-47 tag,
  shaped `language[-Script][-REGION]` (`fr-FR`, `de-AT`, `zh-Hant-TW`). It says
  what language the field holds, never which voice reads it: a voice is a
  property of the machine and is never written to a file that travels.
- **`speak`** — `true` when the field may be read aloud.

Both are **optional and additive at version `1`** — the version is deliberately
NOT bumped, on the same reasoning as the `.sta` per-unit `hash` below: decoders
ignore keys they do not know, so a mask carrying speech still loads in a build
that predates it. What the Converter must do:

- **Omit both keys whenever they are at their default** (`language` empty,
  `speak` false). Writing `"language": ""` or `"speak": false` is wrong: an
  unconfigured mask must stay byte-identical to what every shipped build
  produces, which the round-trip fixture test depends on.
- **Never invent a language.** Legacy files say nothing about pronunciation, so
  a converted mask omits both keys on every field and the author fills them in.
  The program never guesses a field's language from its content.
- Write tags in conventional casing (lower-case language, title-case script,
  upper-case region). The app normalizes what it reads, and **drops** a value
  that is not a string of that shape — or a `speak` that is not a boolean — to
  the default rather than failing the load.

## `.vok` (deck) — `example.vok`

Top-level `format` is `learn-anywhere/lessons`, `version` `1`, then:

- **`mask`** — an embedded **read-only cache** of the mask (same shape as the
  `.inf` mask body, including the matching `maskId` and ids). The editable copy
  is the sibling `.inf`; this cache is only overwritten by propagation.
- **`units`** — each has a `categoryId` (referencing a category `id`) and a
  `fields` object whose **keys are field ids serialized as JSON strings**
  (`"0"`, `"1"`, …), never field names. A value is either a plain string or a
  list of rich-text runs (`{text, bold?, italic?, underline?, strikethrough?, color?,
  highlight?}`). `color` and `highlight` are not colours but formatting tokens,
  `"text1"` and `"highlight1"`: the program draws them in the current theme's text
  colour and highlight, so they change with the theme. Any other value, an old
  `#RRGGBB` included, fails to load with the run's path. Fields may be omitted;
  absent = empty.

A deck may additionally carry, right after `version`:

- **`lastEdited`** — when the deck's **units** last changed, as local time with
  its UTC offset, ISO 8601, to the second: `"2026-09-25T16:32:11+02:00"`. No
  `Z`, no fractional seconds, no missing offset — exactly this shape.

It is set by every write that changes unit content: a field value, a unit's
category, a unit added or removed (including a merge, and a new deck made with
**Save selected units** or from Lexicon hits). It is **content only**: a write
that changes nothing but the embedded mask — propagation, a mask-copy sync,
adopting the linked `.inf` — keeps the value it had, and so does a write that
changes only a unit's difficulty flags. The file's modification time is no
substitute, because those writes all move it.

Like the speech keys it is **optional and additive at version `1`**: omit it
when unknown (never write `null` or `""`), so an undated deck stays
byte-identical to what every shipped build produces. The app reads a value that
is not a string of that shape as "not recorded" rather than failing the load,
and drops it on the next save. Builds predating the key ignore it and drop it
when they re-save. The Converter omits it: a legacy file says nothing about when
its units were edited.

"Last learned" is deliberately **not** stored: it is the newest modification
time among the deck's statistics files in its statistics folder (the plain
sidecar, the timestamped session files, the all-time file), worked out when
needed.

A unit may additionally carry, right after its `categoryId`, up to four
**difficulty flags** — two kinds, each per query direction (ADR-0005 and its
per-direction amendment):

- **`manualDifficult1`** / **`manualDifficult2`** — `true` when the learner
  marked the unit difficult in direction 1 / 2 (F12 or the **Difficult** pill in
  a learning session asking that direction).
- **`autoDifficult1`** / **`autoDifficult2`** — `true` when the program
  detected the unit as difficult in direction 1 / 2 from that direction's
  lifetime record.

A unit is **difficult in a direction** when it carries either flag of that
direction; where no single direction is in view (the Lexicon, the statistics
unit list's Combined view), it counts as difficult when either direction is. Each key is written **only when `true`**
and omitted otherwise (never `false`), so an unflagged deck stays byte-identical
to what earlier builds produce; all four are **additive at version `1`**, and
are written in the order listed above. A value that is not the boolean `true`
reads as unflagged rather than failing the load.

Decks flagged by development builds carry the direction-less keys
**`manualDifficult`** / **`autoDifficult`** instead. They are read as
**direction 1**'s flags — the only direction ever practised when they were
written — and never written again, so the next save of such a deck turns them
into `manualDifficult1` / `autoDifficult1`. A unit carrying both an old and a
new key for direction 1 is flagged if either says so.
The flags are not unit content: they never enter the per-unit identity `hash`
in the `.sta` (so marking a unit never resets its statistics), and a write that
changes only flags does not move `lastEdited`. Propagating a mask keeps them.

**Builds before 1.0 open a flagged deck but drop every flag when they re-save it**,
because their encoder writes only `categoryId` and `fields`. Accepted rather
than bumping the version, which would lock older builds out of the file; update
every machine that edits a deck. An automatic flag can be recomputed from the
lifetime record; a manual flag lost this way is gone.

Only `attempts` + `correct` per unit+direction are stored (in the separate
`.sta` sidecar), and the super-query active pool is always a derived view.

## `.sta` (statistics sidecar) — per-unit `hash`

Top-level `format` is `learn-anywhere/statistics`, `version` `2`, then an
optional `scope`, `deckRef`, an optional `learningSeconds` (see below) and
`perUnit`. Each `perUnit` entry has `index`
(1-based), `dir1`, `dir2`, and
**optionally `hash`** — the identity of the unit those counters were recorded
for, so a deck edited outside the app can have its statistics realigned instead
of silently landing on the wrong units.

- **Input:** the unit's `categoryId`, then every field of that category whose
  `role1` **or** `role2` is `Q` or `A`, in the category's field order. Fields
  that are `R` in *both* directions are excluded, so editing a remark never
  changes a unit's identity. Each field contributes its id and the field value's
  **plain text** (formatting runs flattened), so re-colouring an answer does not
  change the identity either.
- **Encoding:** `c<categoryId>` followed by `|<fieldId>:<charLength>:<value>`
  per contributing field, UTF-8 encoded; the hash is the **first 16 lowercase
  hex characters of the SHA-256 digest** of that string. The length prefix is
  what makes the encoding unambiguous — a value may contain any character,
  including whatever separator one might otherwise pick.
- **Version stays `2`.** The key is additive: decoders on both sides ignore keys
  they do not know, so a hashed file loads in an older build and an unhashed
  file loads here (positionally, exactly as before). Bumping to `3` would only
  make current builds reject the file.

`packages/core/lib/statistics/unit_identity.dart` is the implementation and the
tie-breaker for anything this section leaves open.

## `.sta` — the `scope` marker and the two file names

A `.sta` is one of two kinds, and the kind is carried by the file, not by where
it was found:

- **`scope` absent, or an unrecognised value → the working record.** This is
  every `.sta` written before all-time statistics existed, and every session
  file written today. **Never emit `"scope": "session"`** — the working record
  is the *unwritten* default, so a working file stays byte-identical to what
  earlier builds produced and read.
- **`"scope": "allTime"` → the deck's lifetime record.** The only value ever
  written. `StatisticsScope` (`packages/core/lib/models/models.dart`) is the
  enum; the JSON value is its Dart name, so the casing is exactly `allTime`.

**The key is additive at version `2`,** on the same terms as the per-unit
`hash`: decoders on both sides ignore keys they do not know, and an unrecognised
`scope` value decodes as the working record rather than failing the load. So a
build predating the marker still loads a lifetime file — as a working record,
which is the safe reading. Do **not** bump the version to `3` for it; that would
only make shipped builds reject the file.

The names, all derived in `DeckPaths`
(`packages/core/lib/paths/deck_paths.dart`), never the shell. The desktop's two
files live
in the deck's **statistics folder**: the subfolder named `statistics` beside
the deck, lower case and never translated (ADR-0007). It is the only place the
desktop looks for them; a `.sta` left beside the deck is not found, and the
folder is created by the first write, never by a read.

| File | Path for `French/mydeck.vok` | Written by |
|---|---|---|
| Session file | `French/statistics/mydeck_YYYYMMDD_HHMMSS.sta` | auto-save, save-as |
| Lifetime record | `French/statistics/mydeck_alltime.sta` | every answer, always |
| Android sidecar | `mydeck.sta` beside the deck, in the app's private library | the Android companion only |

Three constraints hold the naming together, and the Converter must respect all
three:

- **`_alltime` can never match the session pattern.**
  `DeckPaths.timestampedStatisticsPattern` requires digits after the underscore,
  so the lifetime file is never a candidate for the most-recent-session
  auto-load. Any new sidecar name must keep that property.
- **The lifetime record is deliberately not the bare `mydeck.sta`.** That name
  is the Android companion's live sidecar; one name meaning two things would
  break a deck carried between the shells.
- **Name and marker must agree.** A file named `_alltime.sta` carries
  `"scope": "allTime"`; a file that does not carry the marker must not be given
  that name. Readers check the marker, `DeckPaths` owns the name, and a
  disagreement between the two is a bug in whichever tool wrote the file.

## `.sta` — `learningSeconds`, the record's learning time

`learningSeconds` is the learning time the record holds, as one whole number of
seconds for the **whole deck** — there is no per-unit or per-direction split
(ADR-0006). In a working file it is the **statistics time**: every sitting since
the current statistics were last cleared. In a lifetime file it is the **total
time**.

- **What it sums.** Each rated unit adds its unit time, capped at 300 seconds
  (`kUnitLearningSecondsCap`, `packages/core/lib/time/learning_time.dart`) —
  *No count* and think-only ratings included. A unit left unrated adds nothing.
  The time is added in the same write that records the answer's counters.
- **Written only when non-zero.** A record holding no time omits the key, so it
  encodes byte-identically to what earlier builds produced.
- **Absent, or not a whole non-negative number → `0`.** Every file written
  before the key existed reads as "no time recorded", never as an error.
- **Clearing the current statistics zeroes it;** loading a session file restores
  it; *Save stats as* writes it.
- **In the lifetime file it only grows.** Each answer adds its seconds in the same
  delta as its counters, under the same write authority (ADR-0001) — a *No count*
  answer moves no counter but still adds its time, so it alone can create the
  file. Clearing the current statistics leaves it alone; only the
  learner-confirmed clear of the all-time record zeroes it. Lifetime files
  written before the key read as `0`, so total time covers only sittings since
  then.
- **Loading a lifetime file by hand as the current statistics** takes its
  `learningSeconds` as the statistics time, along with its counters; the
  lifetime record itself is unchanged.
- **Additive at version `2`,** on the same terms as `hash` and `scope`: a build
  predating the key ignores it. Do **not** bump the version for it.
- **Android writes no `learningSeconds`.** The companion keeps no learning time;
  the phone and the desktop never exchange statistics.
