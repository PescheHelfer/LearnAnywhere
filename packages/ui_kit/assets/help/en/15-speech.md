# Speech

A deck knows that a word is French. Until you tell it so, the program does not — and a
word you can only read is a word you cannot say. Speech starts in the mask: you say what
language each field holds, and which fields may be read aloud.

Once a field has a language and permission to be spoken, a speaker icon beside it in a
learning session reads it aloud — see [Hearing a field](#hearing-a-field). With automatic
speech, which is on from the start, the answer reads itself out at every reveal, with `F4` to hear it
again — see [Reading the answer automatically](#reading-the-answer-automatically). What
decides the *voice* is your computer, not your deck, and you pick which of its voices to
use under [Choosing a voice](#choosing-a-voice). Which computers speak, and what Linux
needs first, is under [Where speech runs](#where-speech-runs).

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

## Reading the answer automatically

Clicking an icon for every single word gets old, so **Read the answer aloud
automatically** is ticked from the start: the answer is read out the moment it is
revealed — you can leave the mouse alone and keep typing. Untick it under
[Choosing a voice](#choosing-a-voice) if you would rather choose what to hear.

What is read is the answer and only the answer: every field that may be spoken and holds
the answer role in the direction you are being asked in, in the order the mask lists
them. The question is not read out — you have been looking at it all along — and neither
is a remark field, which is a remark in both directions. Remarks keep their own icon, so
an example sentence is still one click away when you want it.

Speech follows the rows you see. If you typed an
[equal group](02-concepts.md#equal-group) in a different order, **Correction** and
**Your answer** show it in your order, so it is read in your order: each row reads the
solution value it shows. **Solution** shows the deck's order, and `F4` there reads that
order.

It is read whether you got it right, got it wrong, or were told it was *Almost*. A
mistake is precisely the moment hearing the word said properly is worth most, so nothing
is held back as a penalty. It works the same way at every
[level-learning](07-level-learning.md) level, and on a plain reveal when you are not
typing at all.

Three details you would notice within ten seconds if they were wrong:

- The answer is read **once** per revealed unit. Cycling the answer view with `F9` does
  not make it repeat.
- Revealing a new unit **cuts off** whatever is still being said instead of queueing
  behind it. Holding `Enter` through ten units leaves you hearing the tenth word, not all
  ten on top of each other.
- A unit with nothing to read — no answer field with **Speak** ticked, or nothing written
  in one — is simply silent. Nothing is announced, and nothing goes wrong.

`F4` reads the same thing again, at any time, whether the switch is on or off. It plays
exactly what automatic speech plays, so there is one rule to learn and not two. Before
you have revealed the answer there is nothing for it to play — `F4` cannot show you the
solution early. The one exception is the top of the
[level ladder](07-level-learning.md), where the solution is on screen to be memorised: it
carries an icon there, and `F4` reads it there too.

The **Read aloud** button among the session's buttons does exactly what `F4` does, and
is there exactly when `F4` would play something: after the reveal, and at the top of the
ladder while the solution is shown. On a computer that cannot speak, or for a unit with
no answer field to read, it is not there at all. When the answer's language has no
installed voice the button stays, and pressing it tells you which language is missing,
just as `F4` does — see [When nothing is said](#when-nothing-is-said).

With the switch off, the program never says anything unless you ask it to, by an icon or
by `F4`. Either way, listening is never an attempt: play a word ten times and your
[statistics](09-statistics.md) and your place on the level ladder are exactly where they
were.

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
language telling you in advance that it will be silent.
[Installing a voice on Windows](#installing-a-voice-on-windows) is how to change that on
Windows. On Linux, that sentence on *every* row usually means the speech service itself
is missing, and [Installing speech on Linux](#installing-speech-on-linux) is the cure.

## When the first syllable is missing

Some headphones — simple wired ones in the headphone jack especially — doze off while you
type. The next word wakes them, and its first syllable is lost while they do: the first
word read after you confirm an answer starts in the middle, while `F4` straight away plays
it in full. The built-in speakers, and other programs, are not affected.

**Wake the audio output before speaking**, under [Choosing a voice](#choosing-a-voice), is
the cure, and it is on from the start: before each read the program plays a tenth of a
second of silence, which wakes the output before the word begins. Only the first field of
an answer gets it; the fields after it follow too closely for the output to doze off again.
If you only ever listen through speakers, you can switch it off and lose that short delay.

On **Linux** the checkbox is not offered. The program does not play that silence there, so
a switch for it would do nothing.

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

## Installing speech on Linux

On Linux, Learn Anywhere speaks through **Speech Dispatcher**, the speech service of the
Linux desktop, with whichever voices it offers. It may already be installed on your
computer, together with the **eSpeak NG** voices. When it is missing, speaker icons still
appear, and using one tells you that no voice speaks the field's language;
**Options ▸ Speech...** shows the same sentence on every row.

Speech Dispatcher comes with your distribution. Install it from a terminal:

**Ubuntu, Linux Mint, Zorin OS and other Debian-based systems:**

```
sudo apt install speech-dispatcher speech-dispatcher-espeak-ng
```

**Fedora, Nobara and other Fedora-based systems:**

```
sudo dnf install speech-dispatcher speech-dispatcher-espeak-ng speech-dispatcher-utils
```

To check that the service speaks at all, run `spd-say "Hello"` in the same terminal: you
should hear it. Then open a learning session or **Options ▸ Speech...** again. The program
finds the service by itself, and starts it if it is not running yet. Nothing needs
restarting, and nothing needs setting up inside Learn Anywhere.

When Learn Anywhere stops a word, it stops only its own: a screen reader or another
program speaking at the time is not cut off by it.

**Better voices.** eSpeak NG speaks a great many languages, and sounds robotic doing it.
Speech Dispatcher can speak through other voices installed on the system, and every one it
offers is listed under **Options ▸ Speech...**, with the name of the module it comes from in
front of the voice — Learn Anywhere needs no change to use them. The most natural-sounding
free voices today are **Piper** voices, downloaded from
[the Piper project](https://github.com/OHF-Voice/piper1-gpl) — each voice is a pair of files,
`<name>.onnx` and `<name>.onnx.json`. Speech Dispatcher has no Piper support of its own; it
reaches Piper through its **generic module** (`sd_generic`), which runs a command you write
yourself. In outline:

1. Install the `piper` program itself (a release binary, or `pipx install piper-tts`) and
   download the voices you want into a folder of your choosing.
2. Write a module file — commonly `~/.config/speech-dispatcher/modules/piper.conf` — whose
   `GenericExecuteSynth` line pipes the text Speech Dispatcher hands it through `piper` and
   into an audio player (`paplay`, `pw-play` or `aplay`, depending on your system), with one
   `AddVoice` line per voice and a `DefaultVoice` line.
3. Register it in `speechd.conf` with `AddModule "piper" "sd_generic" "piper.conf"`, and
   restart Speech Dispatcher.

Done correctly, **Options ▸ Speech...** lists the new voices under the module name `piper`,
right beside eSpeak NG's. Most Piper voices play at 22050 Hz; one with `-low` in its name
plays at 16000 Hz, and using the wrong rate in the module file is what makes Piper audio
sound sped-up or slowed-down rather than silent. The exact commands depend on your
distribution and audio server, so Piper's own instructions, linked above, are the authority
on the details.

**If Piper feels slow to start speaking.** Two different things can each cost a few
seconds before a Piper voice is heard, and fixing them never touches Learn Anywhere —
both live entirely in Speech Dispatcher's own module.

The first is the `piper` command loading its voice model straight from disk every time it
is asked to speak, which alone takes several seconds regardless of how short the sentence
is. Piper's own `piper.http_server` keeps a voice's model in memory between requests,
cutting a repeat request to a fraction of a second; point `GenericExecuteSynth` at it (a
small `curl` call) instead of invoking `piper` directly each time, and start the server
once as a `systemd --user` service so it is already warm by the time you need it.

The second, independent cost is specific to PipeWire: opening a brand-new audio
connection for every utterance — which is what a `GenericExecuteSynth` command does if it
ends in a fresh `pw-play` (or `aplay`) each time — can itself take a couple of seconds on
some systems, no matter how fast the voice already is. eSpeak NG does not have this
problem because its own module keeps one audio connection open for its whole lifetime
instead of opening a new one per sentence. The matching fix for a `sd_generic` module is
to keep one playback process running permanently too, reading from a named pipe
(`mkfifo`) that `GenericExecuteSynth` appends raw audio to rather than spawning a player
of its own each time — one such player per sample rate your installed voices use, since a
player is started at a fixed rate.

This has a real cost: Speech Dispatcher's own "stop and read the next word" works by
killing the process `GenericExecuteSynth` started, and with a shared, long-running player
that process is no longer the one actually producing sound — so a word can keep playing
past the point a new one starts, instead of being cut off. Weigh that against how much
the delay bothers you.

**Putting the good voices first.** Both the voice **Options ▸ Speech...** offers first
for *every* language and which voice **Automatic** chooses come from one Speech
Dispatcher setting: `DefaultModule` in `speechd.conf`. Whichever module is named there is
listed first; eSpeak NG's dozens of entries otherwise push a module like `piper` — which
may hold only one or two voices per language — to the bottom of every list.
`DefaultModule piper` (or whichever module holds your better voices) fixes both at once,
with no change to Learn Anywhere itself.

**A voice that is unusually fast or slow.** Learn Anywhere's own **Speech rate** slider
applies to every voice equally, so it cannot correct one voice that is markedly faster or
slower than the rest — some Piper voices simply are, independently of quality. Piper
reads its own default pace from `length_scale` in that voice's `<name>.onnx.json` file,
under `"inference"`: raising it slows that one voice down, lowering it speeds it up, and
`1.0` is "as trained." Edit only that voice's file — it has no effect on Learn Anywhere's
slider, and none on any other voice.

## Choosing a voice

**Options ▸ Speech...** is where you decide *which* of your computer's voices speaks
each language, how fast everything is read, and whether the answer is read out by itself.

**Read the answer aloud automatically** sits at the top of the screen. It is on until
you switch it off, it is remembered between sessions, and what it does is described under
[Reading the answer automatically](#reading-the-answer-automatically).

**Wake the audio output before speaking** sits just below it, and is on from the start
too. It plays a moment of silence before each read so that the start of the word is not
lost — see [When the first syllable is missing](#when-the-first-syllable-is-missing). It is
not offered on Linux.

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

On Linux the entry is there even before Speech Dispatcher is installed. Every row then
says it has no voice, which is the cue for
[Installing speech on Linux](#installing-speech-on-linux) — a missing entry would give
you nothing to find.

## What travels with the deck, and what does not

The spoken language and the **Speak** flag live in the mask, so they follow a deck to
another computer or to the phone, exactly like a field's name or length. Changing either
is a safe change: no stored data can be lost by it, so decks built from the mask
[update themselves](05-mask-editor.md#keeping-decks-in-sync) with no warning to
acknowledge.

Which *voice* speaks a language is deliberately not stored in the deck. A voice belongs
to the machine it is installed on, and a deck carrying one machine's voice names to
another machine would be carrying something meaningless.

## Where speech runs

Speech runs on **Windows**, on **Linux** and on the **Android companion** — see its own
chapter, [The Android companion](14-android-companion.md#speech). Each uses the voices its
system already has: on Windows those that come with its language features (see
[Installing a voice on Windows](#installing-a-voice-on-windows)), on Linux those of
Speech Dispatcher (see [Installing speech on Linux](#installing-speech-on-linux)).

Linux differs in two details. **Wake the audio output before speaking** is not offered
there. And a Linux machine without Speech Dispatcher keeps its speaker icons and its
**Options ▸ Speech...** entry, so that both can tell you what is missing instead of
quietly leaving speech out.
