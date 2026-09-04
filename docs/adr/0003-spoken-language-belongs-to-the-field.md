# ADR-0003 — The spoken language is a property of the field, never of a direction or a deck

**Status:** accepted (2026-09-05)
**Scope:** system-wide — `packages/core` owns the mask schema and the speech policy,
`packages/desktop` owns the mask editor that authors it, both shells render the icons and
dispatch the utterances. Nothing here is platform-specific.

## Context

A deck can now be read aloud, and something has to say **which language a piece of text
is in** so that a voice can be chosen for it. There are three places that fact could
live, and they are not equivalent.

The obvious one — and the first instinct here — is the **query direction**. A direction
already names a question side and an answer side, the learner already thinks of
"German → French" as one thing, and a per-direction language needs exactly two settings
per deck instead of one per field. Almost every deck in existence would be configured
correctly by two dropdowns, and the mask editor would grow no columns at all.

The second is the **deck**: one language for the whole file. That is even less UI and it
is wrong immediately — a vocabulary deck is bilingual by definition, so a single tag
mis-speaks half of every unit.

The third is the **field**, which is what this record settles on.

The counterexample that decides it is small and completely ordinary. Take a deck whose
mask has a German field, a French field and a remark field holding a French example
sentence, learned in both directions:

- In direction 1 the German field is the question and the French field is the answer. A
  per-direction setting of "question = German, answer = French" is exactly right.
- In **direction 2 the same two fields swap roles**. The French field is now the
  *question*, so the "question language" applies to it — and a German voice reads
  *anniversaire*. The very same field, holding the very same word, is spoken correctly
  in one direction and wrongly in the other.
- The **remark field** has no honest answer at all under the per-direction scheme. It is
  neither question nor answer, so whichever side it is attached to, a French example
  sentence gets read in German in half of the directions the learner practises.

That is the whole argument: a per-direction language is correct **exactly at its own
default** — the direction the mask author happened to configure it in — and wrong
everywhere else. It cannot be fixed by adding a third slot for remarks, because the
question/answer slots themselves swap under the learner's own feet whenever she reverses
the direction, which is the normal way this program is used.

The language is not a fact about the *role a field plays in one direction*. It is a fact
about **the text in the field**: `anniversaire` is French in every direction, in the
Lexicon, in the unit editor, and on a phone. Attaching it anywhere else means restating
the same fact once per context and keeping the copies in agreement.

## Decision

**The spoken language is stored per field, in the mask, as a BCP-47 tag. No direction, no
deck and no session carries a language, and nothing anywhere derives one from a field's
role.**

Four rules follow from that and are not negotiable:

1. **The tag lives on `FieldDefinition`** (`language`, alongside `speak`), so it travels
   with the deck to any machine and is authored once, in the mask editor, beside the
   columns that already say what each field is for.
2. **The role decides *whether* a field is spoken, never *how*.** The automatic-speech
   set is "`speak` is on **and** this field holds the answer role in the current
   direction" — a filter over fields, applied at the moment of speaking. The direction
   selects; it never supplies a language.
3. **A field's language is direction-invariant by construction.** Reversing the direction
   changes which utterances are produced and cannot change what voice speaks any of them.
   This is what makes the remark field work: it is spoken in its own language on demand,
   in both directions, with nothing special-cased.
4. **The voice is resolved from the tag at speaking time, on the machine doing the
   speaking** — never stored beside it. See [ADR-0004](0004-flutter-tts-first-linux-mute.md)
   and the glossary entry for *voice*.

## Consequences

Accepted, and visible:

- **The mask editor grows two columns rather than a deck-level dialog.** Per field is
  more rows to look at than two dropdowns would have been. It is still *strictly less*
  UI than the alternative in total: the per-direction scheme needs a language slot per
  role **per direction** — question, answer and something for remarks, times two
  directions — plus the rules for what happens when a field's role changes. Per field is
  one tag, once, and no rules.
- **Every field starts with no language**, so an existing mask opened in a new build says
  nothing and does nothing differently. The feature costs the learner nothing until she
  asks for it.
- **A field with `speak` on but no language carries no icon.** There is nothing to
  resolve a voice from, and an icon that can do nothing is worse than no icon.
- **`speak` is auto-ticked when a field becomes the answer of a direction, and never
  auto-unticked.** That is the common case, and it is the one place where a role is
  allowed to touch a speech setting — it sets a *default at authoring time*, not a
  meaning at speaking time. A field the author deliberately silenced stays silent through
  every later edit.
- **The two keys are additive at the existing mask format version and omitted at their
  defaults**, so an unconfigured mask stays byte-identical to what current builds write
  and older builds keep reading new masks. In mask-compatibility terms they are
  *compatible*, like a role change: editing them bumps the mask revision and propagates
  through the existing sync path, and can never drop stored unit data.
- **Extending speech to other screens costs nothing.** The Lexicon and the unit editor
  are out of scope today, but they show the same fields, and a field that knows its own
  language needs no session and no direction to be spoken. Under the rejected scheme
  neither screen would have had a direction to ask.

## Alternatives rejected

- **A language per query direction** — the subject of this record. Rejected on the
  counterexample above: it mis-speaks the question side of direction 2 and has no answer
  at all for remark fields.
- **One language per deck.** Rejected immediately: a bilingual deck has at least two
  languages in it by definition.
- **Detecting the language from the field's content.** Rejected in the spec: the program
  would be guessing, single-word fields are exactly the case detection is worst at, and a
  wrong guess is silent — it produces a confidently mispronounced word with nothing on
  screen to explain it. The mask author says what the language is.
- **Storing the language on the unit rather than the mask.** It would let one unit differ
  from its neighbours, at the cost of authoring the same tag on every unit in the deck
  and of a fact about the deck's *structure* living in its data. The mask is where
  structure belongs.
