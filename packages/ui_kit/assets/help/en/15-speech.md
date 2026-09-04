# Speech

A deck knows that a word is French. Until you tell it so, the program does not — and a
word you can only read is a word you cannot say. Speech starts in the mask: you say what
language each field holds, and which fields may be read aloud.

Once a field has a language and permission to be spoken, a speaker icon beside it in a
learning session reads it aloud — see [Hearing a field](#hearing-a-field). What decides
the *voice* is your computer, not your deck, and you pick which of its voices to use
under [Choosing a voice](#choosing-a-voice). Not everything is here yet: see
[What is not there yet](#what-is-not-there-yet).

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

## Hearing a field

In a [learning session](06-learning-sessions.md#during-a-session), a small speaker icon
sits beside every field that may be spoken and whose value is on screen. Click it and
that one field is read aloud, in a voice your computer already has for the field's
language. Nothing is downloaded and nothing leaves your machine.

There is one rule, and it needs no exceptions: **an icon is wherever its field's value
is.** A question field carries one from the moment the card appears, so you can hear the
word while you are still working out the answer. An answer or a remark field gains one
the moment it is revealed, which is when you can read it anyway — so there is no way to
hear the solution before you have tried it.

The rule holds in [level learning](07-level-learning.md) too, and it pays off there: at
the top of the ladder the whole solution is on screen to be read and memorised, so it
carries an icon — hearing the word is exactly what that step is for. Press
**Hide & type** and the icon goes away with the solution.

No icon appears beside:

- a field whose **Speak** is not ticked,
- a field with **"(none)"** as its spoken language,
- a hidden field (one with no name),
- an answer or remark field before you check,
- a field this unit leaves empty.

What you hear is exactly what is written in the field, including any part of it you have
struck through: the program says what the author wrote and does not edit it.

Listening costs you nothing. It is never an attempt, it moves no
[statistics](09-statistics.md), and it cannot move you up or down the
[level ladder](07-level-learning.md). Play a word ten times if it helps.

## When nothing is said

A voice belongs to the computer you are sitting at, never to your deck. The program takes
the first of these it can: the voice you chose for that language under
[Choosing a voice](#choosing-a-voice); then a voice for that exact language; then any
voice for the same language from another region — a Canadian French voice reads a
France-French field rather than leaving it silent.

If neither is installed, the icon stays where it is and tells you so when you use it:
**"No installed voice speaks fr-FR. The "Speech" chapter of the user guide (F1) explains
how to add one."** The icon deliberately does not disappear. A missing icon looks exactly
like a field nobody enabled speech for, and you would have no way to tell which it was.

**Options ▸ Speech...** says the same thing before a session starts, and for every
language at once: a row reading **"This computer has no voice for it-IT"** is that
language telling you in advance that it will be silent. The next section is how to
change that.

## Installing a voice on Windows

Windows installs speech voices along with its **language features**, one language at a
time. There is no separate list of voices to buy or download, and a language added this
way costs nothing.

**Windows 11.** Open Windows' own **Settings**, go to **Time & language ▸ Language &
region**, and press **Add a language**. Pick the one you need — *Français (France)* for
`fr-FR`, *Deutsch (Deutschland)* for `de-DE`, *Italiano (Italia)* for `it-IT`, *English
(United Kingdom)* for `en-GB`. On the **Install language features** page that follows,
leave **Speech** (called **Text-to-speech** in some builds) ticked: that component *is*
the voice, and with it unticked the language installs without one. The other components
— display language, handwriting, the keyboard — are not needed for speech and can be
left off.

**Windows 10.** Open **Settings ▸ Time & Language ▸ Speech**. Under **Manage voices**,
press **Add voices** and choose the language you need. If it is not in that list, add
the language first under **Time & Language ▸ Language ▸ Add a language**, then come
back to **Speech**.

**Each region is its own voice.** `fr-FR` and `fr-CA` are two separate installs, and so
are `en-GB` and `en-US`. If a field is Canadian French and only France French is
installed, Learn Anywhere uses the France voice rather than staying silent — but
installing the Canadian one is what makes the pronunciation right.

A newly installed voice is picked up the next time you open a learning session or the
**Options ▸ Speech...** screen. Nothing needs restarting, and nothing needs setting up
inside Learn Anywhere for a new voice to be found.

## Choosing a voice

**Options ▸ Speech...** is where you decide *which* of your computer's voices speaks
each language, and how fast everything is read.

The screen lists one row per language: every language the open deck's mask uses, plus
any language you have already chosen a voice for — so a choice made for another deck is
never lost, and never invisible. With no deck open, only the languages you have
configured remain.

Each row offers:

| | |
|---|---|
| **Voice** | The voices installed for that language, best match first. **"Automatic"** is where every row starts: it leaves the choice to the program, exactly as described under [When nothing is said](#when-nothing-is-said). |
| The speaker button | Reads a short sample sentence aloud in that row's language and chosen voice, so you can hear a voice before settling on it. |

A language your computer has no voice for shows that sentence instead of an empty list.

**Speech rate** sits above the rows and applies to *everything* the program says — the
samples on this screen and every speaker icon in a session alike. In a language you
barely know it is the most useful control here: slowed down, a word you could not make
out at all becomes a word whose parts you can hear. It is set as a share of each voice's
own normal speed, and it is set by ear, since voices interpret it a little differently.

Both the voices and the rate are remembered on **this machine**, in the settings file
described in [Settings](11-settings.md#where-settings-live). Neither is ever written
into a deck: a deck carrying one computer's voice names to another computer would be
carrying something meaningless. The deck says only that a field is French; each machine
decides which of its French voices says it.

Uninstalling a voice you had chosen breaks nothing. That row falls back to
**"Automatic"** and the field is spoken by whatever else fits, exactly as if you had
never chosen at all.

The whole entry is missing on a machine that cannot speak — **Linux** today — rather
than present and empty. A screen for choosing between voices a machine does not have
would offer nothing.

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

Speech is asked for, one field at a time, by clicking its icon. Reading the answer out
automatically the moment it is revealed, and a key that repeats it, are still to come.

Speech runs on **Windows**. **Linux** has none — no speaker icons appear there at all,
rather than icons that would do nothing when clicked, and **Options ▸ Speech...** is
not in the menu. The **Android companion** cannot speak yet either.
