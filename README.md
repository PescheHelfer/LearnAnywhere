# Learn Anywhere

A drilling program for anything you can write down as a set of connected facts:
vocabulary, dates, legal paragraphs, anatomy terms.

Learn Anywhere is a modern rebuild of the German DOS program *Lern PC plus*
(© 1990/92 Ulrich Veigel Softwareservice). It runs on **Windows** and **Linux**, and a
read-only companion app lets you practise on **Android**.

Nothing about any subject is built in. You describe what a card looks like: its
fields, their roles, and which way round they can be asked. After that, the program
asks the questions and keeps track of how you do.

> **New here?** The quick start for Windows takes you from download to your first
> practised word in about 10 minutes, with a ready-made English deck:
> **[Deutsch](QUICKSTART.de.md)** · **[English](QUICKSTART.md)**

## Why give it a try

Most flashcard apps think in front and back. That is fine for word pairs. It stops
working as soon as one fact has more parts, like a verb with six forms or a process
with several steps. Learn Anywhere was made for this kind of material.

- **Cards can have real structure.** A deck can hold up to 20 kinds of cards, and each
  kind has its own fields. A simple word pair can sit next to a full conjugation table
  in the same deck, and each one is asked in its own shape.
- **One deck works in both directions.** Set up German → French once and you get
  French → German with it. Every field knows its role in each direction, so you never
  need a second deck for the way back.
- **It shows you what you don't know yet.** Statistics are kept for every card and
  every direction. The program can mark the cards you keep getting wrong as difficult,
  and then you practise only those. You can also save your weak cards as a new deck.
- **Your data stays with you.** There is no account to create, and the program never
  goes online. Your decks are plain UTF-8 JSON files on your own disk. You can open
  them in any text editor and back them up however you like.
- **An AI can make your decks.** The file format is plain and
  [documented](docs/file-formats.md), so a language model can read and write it.
  Take a photo of the vocabulary in a schoolbook and give it to an LLM together with
  the format and your preferences. You get a ready `.vok` file back, which saves a lot
  of typing. The same works for extending or cleaning up a deck you already have.
- **It reads your cards aloud, offline.** Speech uses the voices your operating system
  already has, so nothing is uploaded and nothing costs extra. This works on Windows
  and Android. Linux has no speech yet.
- **Practise on your phone without sync trouble.** The Android companion imports your
  decks and asks each card with two taps. It never changes a deck, so there is nothing
  to sync back. Your desktop files stay the master copy.
- **Free and open source.** No subscription and no ads. The code is GPL-3.0.

## Features

- **Four practice modes.** *Level learning* walks each item down a ladder of
  support, from the full solution shown to free recall. *Drill mode* keeps asking
  until everything reaches your chosen accuracy. *Endless mode* never stops, and
  *Once through* asks each item exactly once.
- **Several card shapes in one deck.** A mask holds up to 20 categories, each with
  its own set of fields. Simple vocabulary, a six-line conjugation table and a
  three-step process can live side by side in the same file, and each is asked in
  the form that suits it.
- **Bidirectional by design.** A mask defines two directions, e.g. German → French and
  French → German, and every field carries a role in each.
- **Answer evaluation you control.** Case and accent sensitivity, whether every field
  must be filled in, an optional *Almost* verdict for near misses, and the ability to
  overrule any verdict the program reaches.
- **Statistics that mean something.** Per-unit, per-direction accuracy grouped into
  seven buckets, with a unit list you can filter and then save as a new deck of
  exactly the items you keep getting wrong. They also keep your learning time: time
  pills in a session show the unit, the sitting, the current statistics and the deck's
  all-time total, each one optional.
- **Difficult units.** Mark a unit difficult per direction with F12 (in a session or in
  the unit editor) or in bulk from the unit list, or let the program detect them from
  your results. Practise **Difficult units only** from the setup page, filter the unit
  list and the Lexicon by **Difficult only**, and keep the flags when you export.
  **Update deck from new version** carries your flags onto a deck you received again.
- **Reads your cards aloud.** A mask says what language each field holds; in a session a
  speaker icon beside the field reads it out through the voices the operating system
  already has, and the answer is read aloud on its own unless you switch that off.
  It all stays local and offline: nothing is uploaded and nothing is downloaded.
  Windows and the Android companion; Linux ships mute.
- **A lexicon.** Search the units in memory, or sweep a whole folder tree of decks on disk.
- **Rich text in fields.** Bold, italic, underline, colour and highlight, stored portably.
- **English and German** interface and user guide, five themes, a zoom level from 75 % to 200 %, optional centring of the content on a wide screen, and full keyboard operation including ALT menu mnemonics.
- **Finds your decks.** Up to three recently opened decks are one click away from the
  welcome screen and the File operations screen, each showing when you last edited its
  units and when you last learned it, and each remembering the unit range you last
  learned. A start folder can be set so every file dialog opens where your decks live.
- **An Android companion.** Import your decks onto a phone and keep practising them
  away from the computer: think-only, two taps per card, with its own statistics. Units
  you flagged as difficult on the desktop carry their badge there too, and can be
  drilled on their own. Read-only by design, so nothing is edited or synced back.
- **No database, no account, no network.** Three plain UTF-8 JSON file types you can read, diff and back up with any tool.


## Screenshots

*Windows builds, shown in a few of the five available themes.*

<table>
<tr>
<td align="center" valign="top">

**Mask editor**

[<img src="screenshots/MaskEditor.png" width="420" alt="Mask editor">](screenshots/MaskEditor.png)

</td>
<td align="center" valign="top">

**Unit editor**

[<img src="screenshots/UnitEditor.png" width="420" alt="Unit editor">](screenshots/UnitEditor.png)

</td>
</tr>
<tr>
<td align="center" valign="top">

**Practice setup**

[<img src="screenshots/PracticeSetup.png" width="420" alt="Practice setup">](screenshots/PracticeSetup.png)

</td>
<td align="center" valign="top">

**Advanced learning options**

[<img src="screenshots/Options.png" width="420" alt="Advanced learning options">](screenshots/Options.png)

</td>
</tr>
<tr>
<td align="center" valign="top">

**Answering a card**

[<img src="screenshots/Learning.png" width="420" alt="Answering a card">](screenshots/Learning.png)

</td>
<td align="center" valign="top">

**A wrong answer, corrected**

[<img src="screenshots/Learning_wrong.png" width="420" alt="A wrong answer, corrected">](screenshots/Learning_wrong.png)

</td>
</tr>
<tr>
<td align="center" valign="top">

**Statistics overview**

[<img src="screenshots/Statistics.png" width="420" alt="Statistics overview">](screenshots/Statistics.png)

</td>
<td align="center" valign="top">

**Unit list — keep practicing**

[<img src="screenshots/Statistics_List.png" width="420" alt="Unit list — keep practicing">](screenshots/Statistics_List.png)

</td>
</tr>
</table>

## File types

| Extension | Contents |
|---|---|
| `.vok` | A **deck**: ordered learning units, plus a read-only copy of the mask that shapes them |
| `.inf` | A **mask**: the editable definition of categories, fields, roles and directions |
| `.sta` | **Statistics**: attempts and correct answers per unit and direction, kept on the desktop in a `statistics` folder beside the deck |

A deck is self-contained and opens correctly even if its `.inf` is missing. The
on-disk contract is documented in [`docs/file-formats.md`](docs/file-formats.md).

## Install

Download the newest **desktop** release — its tag is named `desktop-v*` — from the
[Releases page](https://github.com/PescheHelfer/LearnAnywhere/releases).

**Windows.** Unzip the downloaded folder anywhere you like, keeping its files
together, and run `LearnAnywhere.exe` from inside it. No installer; the program
writes only inside your own user profile. The `Examples` folder in the ZIP holds a
ready-made English deck and its mask. The [quick start](QUICKSTART.md)
([Deutsch](QUICKSTART.de.md)) walks a first-time user through every step.

**Linux.** Download the `.AppImage`, then:

```sh
chmod +x Learn_Anywhere-*.AppImage
./Learn_Anywhere-*.AppImage
```

Build details for the AppImage are in [`packaging/linux/README.md`](packaging/linux/README.md).

**Android.** The companion app is sideloaded, not published on the Play Store. From the
[Releases page](https://github.com/PescheHelfer/LearnAnywhere/releases), take the
`*-arm64-v8a.apk` file of the newest release that carries one: it is the right build for
essentially every phone sold in the last decade. The other two APKs are for older 32-bit
phones and for emulators. Open it with your file manager and allow the installation when
Android asks. Installing a newer APK over an older one keeps your library and statistics.

The companion carries its own version number, independent of the desktop app's, so one
release can pair desktop 1.2.0 with companion 0.9.0. The number in the APK's name is the
companion's.

Android refuses to install a build whose version is older than the installed one, and
says so only as a generic failure. If an install is rejected on a phone that already has
the app, check the version rather than the file.

## Build from source

Requires the Flutter SDK (>= 3.44.0, Dart >= 3.12.2) with desktop support enabled for your platform.

The **Windows** build additionally needs `nuget.exe` on the `PATH`: the speech plugin
fetches the CppWinRT package with it at configure time, and CMake stops with
`nuget.exe not found. Please install it.` when it is missing. Download the single
executable from <https://www.nuget.org/downloads> into any folder on the `PATH`. The
Linux and Android builds do not need it — neither builds the speech plugin.

```sh
git clone https://github.com/PescheHelfer/LearnAnywhere.git
cd LearnAnywhere
dart pub get                 # one pub workspace covers all four packages

melos run analyze            # static analysis across the workspace
melos run test:core          # pure-Dart core suite
flutter test                 # run inside packages/ui_kit and packages/desktop

flutter build windows        # from packages/desktop
flutter build linux          # from packages/desktop

# from packages/mobile; needs the Android SDK and NDK
flutter build apk --split-per-abi --obfuscate --split-debug-info=build/symbols
```

`melos` itself comes from the root dev dependency, so `dart run melos <script>` works
without a global install.

## Documentation

| For | Read |
|---|---|
| Using the program | The user guide — [English](packages/ui_kit/assets/help/en/00-index.md) · [Deutsch](packages/ui_kit/assets/help/de/00-index.md). The same text ships inside the app under **Help ▸ User guide** (`F1`). |
| Working on the code | [`ARCHITECTURE.md`](ARCHITECTURE.md), then [`docs/`](docs/README.md) |
| Data formats | [`docs/file-formats.md`](docs/file-formats.md) |
| Cross-platform rules | [`CLAUDE.md`](CLAUDE.md) and [`packages/desktop/CLAUDE.md`](packages/desktop/CLAUDE.md) |

## Project layout

One pub workspace, four packages:

| Package | Purpose |
|---|---|
| [`packages/core`](packages/core) | Pure Dart: domain model, file formats, learning engines, settings, message catalogs. Never imports Flutter. |
| [`packages/ui_kit`](packages/ui_kit) | Shared Flutter themes, tokens, rich-text rendering, widgets, and the bundled user guide. |
| [`packages/desktop`](packages/desktop) | The Windows and Linux application. |
| [`packages/mobile`](packages/mobile) | The read-only Android companion (depends only on core and ui_kit). |

## Status

The two applications ship separately, on independent version tracks and with different
feature sets. The desktop application is at 1.2.0; the Android companion is at 0.9.0 and
is distributed as a sideloaded APK.

## AI-Assisted Development

All code, documentation and configuration in this project was written by AI. The
first version was built with OpenAI's Codex via the
[ChatGPT extension for VS Code](https://marketplace.visualstudio.com/items?itemName=openai.chatgpt),
working from a build specification drafted by me and refined by ChatGPT. Development
since then has been done with Claude (Anthropic): feature ideas and implementation
approaches worked out in conversation in the Claude app, then turned into prompts for
[Claude Code for VS Code](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code),
which wrote the code.

### My Role

- **Feature documentation of the original** — Going through *Lern PC plus* screen
  by screen to write down how it behaved, what its data rules were and which keys
  did what, none of which existed in written form
- **Feature proposals** — Deciding which of the original's features to keep, which
  to drop, and what to add that it never had
- **Specification review** — Reading the generated build specification closely and
  correcting it before any code was written
- **Design decisions** — Working through feature ideas and implementation options
  with Claude, and deciding which approach to build
- **Testing** — Running the app, finding bugs, verifying features
- **Orchestration** — Managing the AI workflow effectively

## Credits

- *Lern PC plus — Universal-Lernprogramm*, © 1990/92 by Ulrich Veigel Softwareservice
  (UVS) — the original program this one rebuilds.
- Modern conversion: SbitFire Software.
- Bundled [Lab Mono](THIRD_PARTY_LICENSES.md) typeface by Martin Wecke, under OFL-1.1.

Learn Anywhere is an independent, unofficial project and is not affiliated with or
endorsed by Ulrich Veigel Softwareservice.

## License

Learn Anywhere is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version. See
[`LICENSE`](LICENSE) for the full text.

Third-party components bundled with the program are listed with their licences in
[`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md).
