# ADR-0002 — Zoom scales the theme's own text sizes; it never overrides the text scaler

**Status:** accepted (2026-08-27)
**Scope:** system-wide — `packages/ui_kit` owns the scaled theme and the level model,
`packages/desktop` owns the setting, the menu and the keys. `packages/mobile` offers no
zoom today; if it ever does, it uses the same mechanism.

## Context

The learner picks a zoom level between 75 and 200 per cent and the whole program follows
it. Flutter offers two obvious ways to do that, and they are not interchangeable here.

The first is `MediaQuery.textScaler` (or a `TextScaler` on individual widgets). It is the
platform's own accessibility mechanism, it is one line, and it reaches every piece of
text in the tree. It is the approach a reader would expect, and the one a future reader
would "correct" this code towards.

The second is to build the application theme's `TextTheme` with its font sizes already
multiplied by the factor.

The mask makes the difference decisive. A field's box is **fixed-width by design**: a
field declared 80 characters long gets a box 80 monospace characters wide, so the answer
column lines up with the question column, and so the same deck has the same geometry on
Windows, Linux and Android. That width is computed in Dart, before layout, by measuring
one character with a `TextPainter` — and what the painter measures is the `fontSize` of
the `TextStyle` handed to it (see `measureMonospaceCharWidth` and
`computeFieldValueWidth` in `packages/ui_kit/lib/src/fields/field_row.dart`, and the
call sites in the unit editor and the learn session).

A `TextScaler` is applied **at paint time**, downstream of that measurement, and is
invisible to it. Set one and the numbers diverge: the box is still measured for
100-per-cent characters while the text inside it renders at 200 per cent. Every field
clips. Nothing crashes and no test that only inspects a font size notices — the learner
finds it, mid-session, with half of her answer cut off.

A theme carrying the scaled sizes has no such gap: the very style that is measured is
the style that is painted, so the box and its text grow together — for this setting.

It does not follow that the mask is safe from every text scaler. The **platform's** own
one (`MediaQuery.textScaler`, fed by Windows' text-size setting and GNOME's
`text-scaling-factor`) is not read by `measureTextWidth`, and never has been. That is a
pre-existing hazard, older than this decision and outside it; what this decision settles
is that the zoom level must not add a second one.

## Decision

**Zoom is applied by building the application theme with its text sizes multiplied by
the zoom factor, at the single point where the shell constructs its themes. It is never
applied by overriding `MediaQuery.textScaler` or by wrapping the app in a `TextScaler`.**

Three consequences of that follow and are not negotiable:

1. **The level lives in the theme, not in an inherited widget of its own.** Every screen
   and the menu bar scale because they all read text styles from the theme; no screen has
   to opt in, and no screen can opt out.
2. **A hard-coded number expressed in text-sized units follows the level too**, and there
   are two kinds of them. `LearnAnywhereZoom.scaleText` scales a font size written as a
   literal because the M3 scale has nothing small enough — the key-name caption under a
   button — in **both** directions. `LearnAnywhereZoom.scaleBox` scales a box dimension —
   a dropdown sized for its longest entry, a numeric field, the bounds a field-label
   column is clamped to, a two-column breakpoint — but **never below its unzoomed value**,
   because such a box also holds chrome that does not shrink (a dropdown's arrow, the
   padding inside an input decoration); scaling one down to match 75-per-cent text
   overflowed it on exactly that. Together these keep every screen free of overflow, and
   free of ellipsis, at both ends of the range.
3. **The mechanism is asserted by geometry, not by font size.** The shell test measures a
   mask field row at 100 and at 200 per cent and requires the box to grow by more than
   the text it holds. A test that read a `fontSize` would pass against the broken
   implementation, which is the whole failure being guarded against.

## Consequences

Accepted, and visible:

- **Icon sizes, paddings and hairlines do not scale.** Chrome is proportionally tighter
  at high zoom: the outcome emoji, the 4-pixel accent bar on a field row and the padding
  inside it all keep their size while the text beside them grows. This is deliberate —
  scaling everything turns a zoom level into a second window size — and it is why a field
  row grows by nearly the full factor in width but by less in height. **Text is not in
  that set**, including the `F3`/`Esc` captions under the buttons: a caption naming the
  key the learner is about to press is useless at 10 pixels beside text she deliberately
  doubled, so it goes through `scaleText` like any other literal size.
- **Below 100 per cent, only the text gets smaller.** Every `scaleBox` dimension holds at
  its unzoomed value, so the 75-per-cent layout is the 100-per-cent layout with smaller
  text in it — provably safe, since text that fits at 100 fits in the same box at 75. The
  cost is that 75 per cent is slightly less compact than a fully proportional shrink would
  be. The gain is that a level meant to fit more on screen cannot clip a dropdown arrow.
- **The text geometry is pinned to Flutter's `englishLike` set.** The colour half of a
  `Typography` carries no font sizes at all; the geometry half does, and Flutter normally
  merges it in later, during localization. To have sizes to multiply, the theme merges
  the geometry in itself. Both languages this program ships are `englishLike`, so nothing
  is lost today; a script needing `dense` or `tall` geometry would have to pick its
  geometry inside `LearnAnywhereTheme` instead.
- **The operating system's own display scaling is untouched and unread.** Zoom is the
  program's setting alone: it does not follow the desktop's scale factor and does not
  change it. The two multiply, which is what a learner who has already scaled her desktop
  expects.

## Alternatives rejected

- **`MediaQuery.textScaler`** — the subject of this record. Correct for a program with no
  measured containers; wrong for this one.
- **Measuring the mask through the text scaler as well.** It closes the gap in principle:
  `TextPainter` accepts a `textScaler`, so the measurement could be taught about it. It
  was rejected because it makes correctness depend on every present and future
  measurement site remembering to pass it, and one that forgets clips silently. Scaling
  the theme makes the two agree by construction.
- **A free-form percentage.** Rejected with the setting itself: six discrete levels mean
  the learner always lands on a size that has been laid out and tested, and the keys have
  something to step between.
- **Deriving the level automatically from the deck or the screen.** Rejected in the
  ticket: it would guess, it would change under the learner whenever she switched decks,
  and not everybody wants large characters.
