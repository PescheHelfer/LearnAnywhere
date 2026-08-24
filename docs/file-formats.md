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

## `.vok` (deck) — `example.vok`

Top-level `format` is `learn-anywhere/lessons`, `version` `1`, then:

- **`mask`** — an embedded **read-only cache** of the mask (same shape as the
  `.inf` mask body, including the matching `maskId` and ids). The editable copy
  is the sibling `.inf`; this cache is only overwritten by propagation.
- **`units`** — each has a `categoryId` (referencing a category `id`) and a
  `fields` object whose **keys are field ids serialized as JSON strings**
  (`"0"`, `"1"`, …), never field names. A value is either a plain string or a
  list of rich-text runs (`{text, bold?, italic?, underline?, color?, highlight?}`
  with `#RRGGBB` colors). Fields may be omitted; absent = empty.

Only `attempts` + `correct` per unit+direction are stored (in the separate
`.sta` sidecar), and the super-query active pool is always a derived view.

## `.sta` (statistics sidecar) — per-unit `hash`

Top-level `format` is `learn-anywhere/statistics`, `version` `2`, then an
optional `scope`, `deckRef` and `perUnit`. Each `perUnit` entry has `index`
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

The two names, both derived in `DeckPaths`
(`packages/core/lib/paths/deck_paths.dart`), never the shell:

| File | Name for `mydeck.vok` | Written by |
|---|---|---|
| Session file | `mydeck_YYYYMMDD_HHMMSS.sta` | auto-save, save-as |
| Lifetime record | `mydeck_alltime.sta` | every answer, always |

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
