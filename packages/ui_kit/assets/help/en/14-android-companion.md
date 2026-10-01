# The Android companion

Learn Anywhere has a second, much smaller app for Android phones. It is a **companion**,
not a port: it exists so you can keep practising decks you built on the computer while
you are away from it. Everything that creates or changes material — the unit editor, the
mask editor, the lexicon — stays on the desktop.

The phone app carries this chapter of the guide inside it, and only this chapter. The
rest of the guide describes menus, function keys and editors that a phone does not have.

## What the companion does and does not do

The companion is **read-only** and **think-only**. It shows you a card, you decide in
your head whether you knew it, and you tell the app which it was. There is nothing to
type.

It has:

- Your imported decks, in a library on the phone.
- Practice in **Drill mode**, **Endless mode** and **Once through**.
- Speaker icons and, if you switch it on, the answer read aloud automatically — see
  [Speech](#speech) below.
- Per-deck statistics, saved after every card you rate.
- The badge on units you flagged as difficult on the desktop, and practice restricted
  to them — see [Difficult units](#difficult-units).
- Theme and language settings, and the two guardrails described below.

It deliberately does not have:

- **Typing.** No answer is ever entered, so nothing is spell-checked or compared.
- **Level learning.** That mode works by asking for a typed answer with progressively
  less support, so it cannot exist without typing.
- **Editing.** No unit editor, no mask editor, no lexicon. Decks are made on the
  desktop.
- **Marking difficult units.** The phone shows the flags set on the desktop, but never
  sets, clears or detects one, and has no settings for them.
- **Sync.** The phone never sees the computer's statistics and the computer never sees
  the phone's. See "Two devices, two sets of statistics" below.

## Getting your decks onto the phone

The library screen is the app's home, titled **Library**. The first time you open it,
it says **No decks yet**.

Tap **Import decks** in the top bar and pick one or more `.vok` files with Android's own
document picker. You can select several at once. The files are **copied** into the app's
own storage, so the originals — on your SD card, in your downloads folder, in a cloud
app — are left untouched, and deleting them later does not affect the copies.

Two things to know about the copies:

- **No mask file.** Android decks never use a separate `.inf` file; the mask travels
  inside the `.vok` file itself. If you have an old deck whose mask lives in a separate
  file, open and save it once on the desktop first.
- **The library is flat.** However your decks are arranged in folders on the computer,
  on the phone they are one list, identified by file name. Android's picker hands the
  app a display name and no folder path, so the structure cannot be reconstructed.

Each entry is titled by the deck's file name, without the `.vok` extension. Beneath it
is the name of the mask the deck was built from, so decks made from the same mask are
told apart by their file names. The number of units in the deck sits at the right-hand
edge of the row. Everywhere else — **Practice setup** and the learning session — a deck
is named by its file name alone. Tapping an entry opens it; tapping the delete icon
offers **Delete**, which removes the deck **and its statistics from this device**.

**The list is ordered by when you last practised each deck, newest first**, so the deck
you are working through is at the top and resuming takes one tap. Decks you have never
practised come first of all — a deck you have just imported is the one you came to the
app to open. Within either group, decks are ordered by name, so the list does not
reshuffle between two visits when nothing has changed. There is nothing to configure and
no dates are shown: the order itself is the information.

**Importing a deck you already have replaces it and keeps its statistics.** This is the
normal way to update a deck you have edited on the computer: export it again, import it
again, and your accuracy figures survive. The app matches your old statistics to the new
units by their question and answer text, so units that only moved keep their history.
Units whose question or answer text you actually changed start again from zero, because
their statistics no longer describe the card in front of you. Editing a remark changes
nothing.

## Setting up practice

Opening a deck shows **Practice setup**, the same settings as the desktop's setup screen
minus everything that only makes sense when you type:

| Setting | What it does |
|---|---|
| **Direction** | Which way the cards are asked. The two names come from the deck's own mask, or **Both**. |
| **Mode** | **Drill mode**, **Endless mode**, or **Once through**. |
| **Mastery threshold (%)** | Drill mode only: the accuracy a unit must reach before it leaves the pool. |
| **Shuffle units** | On, cards come in a fresh random order each pass; off, they come in deck order. |
| **Difficult units only ({count})** | Ask only the units flagged as difficult, each only in the direction it is difficult in; the count shows how many there are — see [Difficult units](#difficult-units). |
| **Start unit** / **End unit** | Practise only part of the deck. |

Your choices are remembered — all except the unit range, which resets each time you open
a deck, because a range that fits one deck means nothing in the next.

**Start session** begins. There is no "require typed answers" option here: on the phone
it is always off.

## A card, in two taps

Each card takes exactly two taps.

**First tap.** The card shows the **Prompt**, anchored at the top of the screen and
filling its width, and one button, **Show answer**. A short prompt and a long one leave
the card the same shape; a prompt too long to fit shrinks to fit and then scrolls, so
nothing is cut off.

Directly beneath the card, against its lower edge, two lines tell you what it is asking.

**Category** names the unit's category — the kind of entry this is. That is how you tell
a category the deck's author called "Synonyms", where the order of your recalled answers
does not matter, from a two-line category, where it does.

**Expected solution fields:** lists what the answer is made of, one small rounded box per
field. On a simple category that is a single box; on a verbs category it may be three, so
you rehearse the infinitive, the participle *and* the auxiliary instead of stopping at
the first. Each field name is its own box, so a name containing a space is one field and
not two. The list describes the direction you are practising, and fields the deck's
author hid are left out. On a category whose answer has no fields at all, the line is not
shown — but the category line still is.

Both disappear the moment you reveal the solution: by then the solution itself names
every field beside its value.

Because these two lines take room from the card, a prompt on a category with many fields
may be set one step smaller than it would otherwise be.

**Second tap.** The card now shows the **Solution** and any **Remarks**, with a
**Prompt** / **Solution** switch above them and three rating buttons underneath:

- **Knew it** — counts as a correct attempt.
- **Didn't know** — counts as a wrong attempt.
- **No count** — shows you the card without recording anything. Use it when you were
  interrupted, or when you want to look something up without spoiling the figures.

The **Prompt** / **Solution** switch lets you look at the question again as often as
you like before you rate the card — the three rating buttons stay in place and stay
usable in either position.

Whichever rating button you tap both records the card and moves on to the next one, so
there is no separate "next" step. This mirrors the desktop, where you reveal the answer
and then press one of three keys. The next card always starts back on the question,
however the switch was left on the one before.

Above the card, a progress bar and two figures — **Mastered** and **Accuracy** — describe
**the whole deck, in the direction this session asks**, not the run you are in and not
the unit range you chose: restricting the range narrows what you are asked, never what
these count, so the bar does not jump when you narrow it. **Mastered** is a fraction of
the whole deck, so how much is left is the rest of it — and the progress bar above shows
the same thing as a bar. The desktop, which has a wider window to fill, spells that
remainder out as a figure of its own. **Accuracy** — correct attempts out of total
attempts, with a percentage — counts that
same direction only. These match the desktop's own live readouts for the same deck and
direction; the phone's Statistics screen always shows the combined figure, since it has
no direction view of its own, so it only matches exactly when you practise **Both**
directions.

When the session asks less than the whole deck — a unit range, or
[Difficult units only](#difficult-units) — a third figure joins them: **Remaining: 120
(4)** means 120 questions of the deck are not yet mastered, and 4 of them are in what
this session asks. That second figure is the one to watch: Drill mode ends with
everything mastered exactly when it reaches 0. Both figures count questions, so with
**Both** a unit counts once per direction. Touch and hold any of the figures for a
reminder of what it counts.

Between those deck-wide figures and the card sits the unit's own line: **Unit x/y**, then
**Unit accuracy** — the attempts recorded against *this* unit in the direction being
asked, as a fraction and a percentage, exactly as the desktop shows it — and, on a unit
flagged as difficult, its [badge](#difficult-units). Do not confuse
the two: **Accuracy** is the whole deck, **Unit accuracy** is the card in front of you. A
unit you
have never been asked reads **0/0 (0%)**, so "new to me" is never a blank. The figure
comes from the deck's saved statistics rather than from the run you are in, so it
survives leaving the session and closing the app — and it updates the moment you rate the
card. In a **Both** directions session it changes when the same unit comes round the
other way, because each direction keeps its own record.

When a Drill or Once-through session runs out of cards, the app says so and offers
**Extend session** to keep going.

**Your statistics are saved after every card you rate.** Nothing is left unsaved, and
there is no save button — which matters on a phone, where Android may close the app the
moment you switch away from it.

## Difficult units

On the desktop you can flag a unit as **difficult**, separately for each direction —
by hand, or let the program flag the ones you keep getting wrong. The flags are stored
in the deck file itself, so they arrive with the deck when you import it, and importing
it again after marking more units on the computer brings the new flags along. The phone
only reads them: it never sets, clears or finds a difficult unit on its own.

**The badge.** A card that is difficult in the direction being asked shows a badge at
the end of its unit line: a flag icon for a manual flag, a sparkle for an automatic one,
or both, followed by **Difficult**. Touch and hold the badge to read which it is —
**Manual flag**, **Automatic flag** or **Manual and automatic flag**. A unit that is
difficult only the other way round shows no badge, because it is not hard in this
question.

**Practising only them.** Switch on **Difficult units only** in **Practice setup** to be
asked just the difficult units, each only in the direction it is difficult in: with
**Both** directions, a unit difficult only one way is never asked the easy way round. It
works in every mode, within the unit range.

- The option shows how big the session will be, in units: **(3)** when the range holds
  every unit that is difficult in the chosen direction, **(1/3)** when the range leaves
  some out — one of the deck's three. With **Both** a unit difficult either way counts
  once. The count follows **Start unit**, **End unit** and the direction as you change
  them; touch and hold the option to have it spelled out.
- If no unit in the range is difficult in the chosen direction, the setup says so and
  **Start session** stays unavailable until you switch the option off, widen the range
  or choose another direction.
- During the session, **Remaining** shows how much of it is left, as described in
  [A card, in two taps](#a-card-in-two-taps).
- Mastering a unit takes it out of a Drill session as usual, but does not take its flag
  away. Only the desktop can unmark it.

## Speech

This is the one screen where the phone is ahead of the desktop: your phone already has
speech voices for far more languages than a typical Windows machine, and headphones are
usually already in your ears.

A speaker icon sits beside every field the deck's mask has marked as speakable — the same
authoring choice described in the desktop guide's
[Speech](15-speech.md#the-speak-flag) chapter, which travels with the deck itself. On the
**Prompt** screen that means the question field; on the **Solution** screen it means the
answer and any remark fields, and the question is a tap away behind the **Prompt** /
**Solution** switch. Tap an icon and that one field is read aloud, in a voice the phone
already has for the field's language.

Turn on **Read the answer aloud automatically** in the Speech screen (below) and the
answer is read out the moment you tap **Show answer** — right or wrong makes no
difference, so nothing is held back as a penalty. It reads once per card: switching the
**Prompt** / **Solution** toggle back and forth does not repeat it, and tapping **Show
answer** on the next card cuts off anything still being said rather than talking over it.
There is no `F4` on a phone — a per-field speaker icon is always there to hear a word
again.

Listening costs nothing: it is never an attempt, and it moves no statistics.

Reach the Speech screen two ways: the speaker icon in a deck's **Practice setup**, or
**Speech** under the overflow menu's **Settings**, reached with no deck open. Either way
it offers the same things:

- One row per language the open deck uses (from Practice setup) or per language you have
  already chosen a voice for (from Settings) — the voices your phone has installed for
  it, and a speaker button that reads a short sample so you can hear a voice before
  choosing it. A language your phone has no voice for says so instead of an empty list.
- **Speech rate**, applying to everything the phone reads aloud.
- **Read the answer aloud automatically**, described above.

Which voice speaks a language is a choice that belongs to **this phone**, exactly as it
belongs to each desktop machine on its own — a deck says only that a field is French, and
each machine decides which of its own French voices says it. A deck carried over from the
desktop therefore speaks on the phone without you touching the deck at all; only the
voice choices differ, because they were never part of the deck to begin with.

## Statistics

The chart icon on a deck's setup screen opens **Statistics** for that deck:

- **Total units**, **Practiced units**, **Total Attempts**, **Correct Attempts** and
  **Accuracy** across the whole deck.
- The seven accuracy groups — **Perfect**, **Good**, **Fair**, **Unsure**, **Very
  unsure**, **Never known** and **Not yet practiced** — as labelled rows with a bar
  showing each group's share of the whole deck; a full bar is every unit.
- **Clear stats...**, which asks for confirmation and then wipes this deck's history on
  this device.

This is a summary only. The per-unit list, the filters, and building a new deck out of
your worst units are desktop features.

## Two devices, two sets of statistics

The phone's statistics are **per-device, by design, and they never travel**.

Android keeps the app's library in private storage that no other app and no PC can read,
which is exactly what makes statistics work at all on a phone — an earlier approach that
wrote alongside the picked file lost every figure as soon as the app was reopened. The
price is that there is no folder for you to copy back to the computer.

So: practise the same deck on both devices and you will build two independent records of
how you are doing. Re-importing an updated deck preserves the phone's own figures, but it
never brings the computer's figures with it.

Because the phone's history is disposable, there is no export or backup feature. Android
includes app storage in its own automatic backup; if you lose it anyway, re-import the
decks and start the figures fresh.

## Settings

The overflow menu in the library's top bar holds **User guide**, **Settings** and
**About**.

**Settings** has five things:

**Speech** — opens the [Speech](#speech) screen described above.

**Theme** — **System**, **Light**, **Dark**, **Dark Blue** (the default) or **Light
Blue**, the same five looks as the desktop.

**Language** — **English** or **German**. This is an in-app setting rather than
Android's own per-app language, which only exists on Android 13 and newer. It switches
every label in the app and this chapter with it.

**Minimum-attempts guard** and **Minimum attempts** (default off, 2) — a unit may not
count as mastered until it has been asked at least this many times. Without it, one
lucky **Knew it** puts a unit at 100% accuracy, which clears the mastery threshold
immediately and empties a Drill pool almost as fast as you can tap. Turn it on if you
want mastery on the phone to mean what it means on the desktop.

**Wrong-answer ceiling** and **Wrong-answer ceiling value** (default off, 10) — stops a
unit's wrong-answer count from climbing without limit, so a card you once had trouble
with can still recover a decent accuracy figure.

Nothing else from the desktop's Advanced Learning Options appears here. Case sensitivity,
accent sensitivity, the *Almost* verdict, complete-input and the session clock all judge
typed answers, and there are none.

**Theme and language** are stored in Android's own preference store. **The two
guardrails and your Speech voice choices** go into `learn_anywhere.settings.json`, the
same file name and the same format the desktop uses, in the app's private documents
folder.

## Installing and updating the app

The companion is **not on the Play Store**. It is distributed as an APK file you install
yourself, published alongside the desktop downloads on the project's releases page.

- Download the **arm64** APK, which is the right build for essentially every phone sold
  in the last decade.
- Android will ask you to allow installing apps from your browser or file manager the
  first time. This is expected for an app that does not come from a store.
- To update, install the newer APK straight over the old one. Your library and your
  statistics are kept.

Two things that can go wrong:

- **Android refuses the install with no useful reason**, on a phone that already has the
  app. This is almost always a **downgrade**: Android will not install a build that is
  older than the installed one. Uninstalling first will clear it, at the cost of your
  library and statistics.
- **You picked the wrong architecture.** Only the arm64 build runs on a normal phone;
  the other files in a release are for emulators and much older devices.

The app's version and its licence are shown under **About**. Learn Anywhere is free
software under the GNU General Public License v3.0, on the phone exactly as on the
desktop.
