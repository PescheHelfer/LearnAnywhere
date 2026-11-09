# ADR-0008 — Linux speaks through Speech Dispatcher, over SSIP, in pure Dart

**Status:** accepted (2026-11-02). Supersedes the "successor engine or mute" decision of
[ADR-0004](0004-flutter-tts-first-linux-mute.md) for Linux; ADR-0004's other rules stand.
**Scope:** system-wide — `packages/core` derives the socket path, `packages/ui_kit` owns
`SpeechDispatcherEngine` and its SSIP client, `packages/desktop` selects it on Linux.
Windows, Android and the `linux/` runner are untouched.

## Context

ADR-0004 shipped `flutter_tts` on Windows and Android and left Linux mute until a successor
engine, `sherpa-onnx` with Piper voices, could cover all three platforms. It wrote down
what that successor costs: audio playback, phonemiser data, voice downloads and a managed
store. Nobody has started it, so "wait" has become "indefinitely", and a learner whose
decks travel between a Windows and a Linux machine gets a different program at each.

Linux has its own counterpart to the Windows and Android voices: **Speech Dispatcher**,
the desktop's speech service, which screen readers already use. A program hands it a
word and a voice, the system makes the sound, nothing leaves the machine and nothing is
downloaded by the program — the same shape as the other two hosts.

## Decision

**On Linux the desktop shell injects `SpeechDispatcherEngine`, which speaks through the
user's Speech Dispatcher by talking SSIP directly over its Unix socket, in pure Dart.
Windows keeps `FlutterTtsEngine`; any other host still gets `UnavailableTtsEngine`.**

Three things decide this, and each departs from something ADR-0004 recorded.

1. **The "`espeak-ng` for Linux only" rejection no longer decides it.** ADR-0004 turned
   down a second, Linux-only engine because the one added for coverage would be the one
   that sounds worst. Speech Dispatcher is not that engine: it is a **broker** in front
   of whatever synthesisers the machine has. eSpeak NG is only its usual default, and a
   better voice the learner adds to the system — Piper among them — is listed and used
   with no change to the program. The robotic baseline is accepted as a starting point,
   not a ceiling, and the user guide says how to get past it.
2. **The transport is SSIP over the socket, not `dart_speechd`.** `dart_speechd` has no
   end-of-speech event, so a multi-field answer could not be read field by field; it
   reports voices as bare strings with no language, so the speech policy could not
   resolve a field's language against them; its FFI calls are synchronous on the UI
   isolate; and it needs `libspeechd` present at run time. Also rejected: `spd-say` (no
   voice list with languages, no per-application stop) and a native `libspeechd` plugin
   (closest to `flutter_tts` in construction, but neither buildable nor checkable from
   the Windows machine, and one more library inside the AppImage). SSIP itself gives
   END and CANCEL events with message ids, voices with languages, `CANCEL self`, and
   priorities — and needs no package, no FFI, no native code and no change to the
   `linux/` runner or the AppImage recipe.
3. **ADR-0004 rule 3 is refined: "unavailable means absent" applies only where the
   learner cannot fix it.** A Linux machine without Speech Dispatcher is not a host that
   cannot speak; it is a host missing a package. So `SpeechDispatcherEngine.isAvailable`
   is always true, and an absent or unreachable service reports **no voices**. The
   existing paths do the explaining: speaker icons stay and say no voice is installed,
   automatic speech stays quiet, and every row of **Options ▸ Speech...** says the
   computer has no voice for its language. The guide then gives the `apt` and `dnf`
   steps. Hiding the feature would leave the learner nothing to look up.

ADR-0004's remaining rules hold unchanged: core performs no I/O (it only derives the
socket path), the engine lives in `ui_kit` and is injected by the shell, a failure is
silence, and the engine keeps no state between utterances beyond the connection itself.
A stored `VoiceChoice` keeps the system engine id, since these too are the machine's own
voices.

## Consequences

- **Linux speech depends on a system package the program does not ship.** Whether a
  given distribution installs it by default is unconfirmed; where it is missing, one
  `apt` or `dnf` line installs it, and the guide and the README carry that line.
  The engine connects lazily, starts the service once if nothing answers (without the
  AppImage's `LD_LIBRARY_PATH`, which must not reach a host daemon), and tries again on
  the next call, so a service installed later is found without restarting the program.
- **The program now speaks a wire protocol it maintains itself.** The SSIP manual
  recommends a language binding over raw sockets; this does not follow that. The client
  is small, and a scripted fake daemon on loopback TCP pins framing, replies, events and
  command order in tests that run on any host. Nothing was run against a real daemon
  while it was built; the Linux checklist in
  [`packaging/linux/README.md`](../../packaging/linux/README.md) is where that happens.
- **Wake audio is not offered on Linux.** The engine ignores `leadIn`, and the Speech
  screen hides the checkbox for this engine (asked of the engine, not the platform)
  rather than show a switch that does nothing. It comes back only if a Linux test shows
  first syllables are lost; an SSML break was considered and deferred, because a voice
  added through the generic module may read the markup. **Tested on Zorin (2026-11-09),
  both eSpeak NG and Piper, through speakers and headphones, across several idle-then-speak
  cycles: no clipped first syllable.** The condition for bringing it back has not been
  met, so it stays off; re-test if a future distro or output module changes this.
- **Only our own speech is ever stopped.** Stopping sends `CANCEL self`, never `all`, and
  words go out at `message` priority, so a screen reader is not silenced by the program.
- **Shell tests must inject an engine.** On Linux the default engine now reaches for a
  real socket and may start a real process, so every test that builds the desktop app
  passes one.
- **`sherpa-onnx` stays possible.** It would plug into the same `TtsEngine` seam, with
  its own engine id in `VoiceChoice`, if carried voices ever become worth their cost.
