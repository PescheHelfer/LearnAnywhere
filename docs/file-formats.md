# Learn Anywhere file-format contract (`.inf` / `.vok`)

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
