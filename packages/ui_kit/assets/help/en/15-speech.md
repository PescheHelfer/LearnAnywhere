# Speech

A deck knows that a word is French. Until you tell it so, the program does not — and a
word you can only read is a word you cannot say. Speech starts in the mask: you say what
language each field holds, and which fields may be read aloud.

Nothing is read aloud yet in this version. What you set here is stored in the mask and
travels with your decks, so the work is not wasted — see [What is not there yet](#what-is-not-there-yet).

## Where speech is set

In the [mask editor](05-mask-editor.md#fields), each field has two columns after its two
role columns:

| Column | Meaning |
|---|---|
| Spoken language | The language this field is written in, chosen from a list |
| Speak | Whether this field may be read aloud |

Both belong to the **field**, not to a direction: French is French whether it is being
asked or answered, so one setting covers both directions.

## Choosing a spoken language

The list offers the languages this program is built to drill, each with the regional
variants that actually sound different — **"Deutsch (Deutschland) (de-DE)"**,
**"Deutsch (Österreich) (de-AT)"**, **"Deutsch (Schweiz) (de-CH)"**,
**"English (United Kingdom) (en-GB)"**, **"English (United States) (en-US)"**,
**"Français (France) (fr-FR)"**, **"Français (Canada) (fr-CA)"** and
**"Italiano (Italia) (it-IT)"**. Pick the pronunciation you want to learn: a British
voice and an American one say the same word differently, and that difference is the
point of the choice.

Two entries are not languages:

- **"(none)"** is the default and means the field is never spoken. Every mask you
  already have starts here, so nothing about your existing decks changes.
- **"Other..."** asks you to type a language tag yourself, for a language the list does
  not offer — `es-ES` for Spanish, `ru-RU` for Russian, `pt-BR` for Brazilian
  Portuguese. The form is a language, then optionally a region, joined by a hyphen. A
  word like `spanish` is not a tag, and you are told so: **"Not a language tag. Use a
  form like fr-FR."** Once accepted, the tag joins that field's own list, so reopening
  the list shows it rather than losing it. Another field in the same language needs the
  tag typed again.

## The Speak flag

**Speak** decides whether a field is eligible to be read aloud at all. It is ticked for
you when you make a field the **answer** of either direction, because that is nearly
always the field worth hearing.

It is never unticked for you. If you switch it off — a gender column answered only `m`
or `f` is not worth hearing spoken — it stays off through every later edit of that
field. The program only ever offers; the decision stays yours.

A field with **Speak** ticked but no spoken language chosen cannot be spoken: there is
nothing to say which voice should read it.

## What travels with the deck, and what does not

The spoken language and the **Speak** flag live in the mask, so they follow a deck to
another computer or to the phone, exactly like a field's name or length. Changing either
is a safe change: no stored data can be lost by it, so decks built from the mask
[update themselves](05-mask-editor.md#keeping-decks-in-sync) with no warning to
acknowledge.

Which *voice* speaks a language is deliberately not stored in the deck. A voice belongs
to the machine it is installed on, and a deck carrying one machine's voice names to
another machine would be carrying something meaningless.

## What is not there yet

This version records the intent only — no field is read aloud, and there is no speech
setting anywhere outside the mask editor. What you set here is what the reading will use
when it arrives, on the machines that can speak: Windows and the Android companion.
Linux has no speech and will say so plainly rather than hiding a setting that does
nothing.
