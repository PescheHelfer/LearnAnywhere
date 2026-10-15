# ADR-0004 — `flutter_tts` ships first, behind an interface, and Linux ships mute

**Status:** accepted (2026-09-05)
**Scope:** system-wide — `packages/core` owns the `TtsEngine` seam and
`UnavailableTtsEngine`, `packages/ui_kit` owns the one concrete engine, each shell picks
which engine it injects. `packages/desktop` is the shell where the platform gap is
visible.

## Context

Speech has to run **locally**: the learner's vocabulary is hand-authored and often
personal, so it may not be shipped to a cloud service, and using her own decks may not
generate a per-word bill. That rules out every hosted service and leaves two candidates.

**`flutter_tts`** speaks through the voices the operating system already has. Nothing is
downloaded, nothing is stored, no audio layer is needed — the plugin is handed a string
and a voice and sound comes out. It covers **Windows and Android**, which is every
platform this program currently ships a release for. It has **no Linux implementation**.

**`sherpa-onnx` with Piper voices** carries its own voices and covers Windows, Linux and
Android uniformly, with better-sounding neural output. It is the intended successor.

The repo rule in [`../../CLAUDE.md`](../../CLAUDE.md) says: before adding a package,
confirm it resolves a **Linux and an Android** implementation, not just Windows.
`flutter_tts` fails that rule. The rule exists so a feature built on one machine cannot
silently break another — a plugin that only exists on Windows is exactly the shape of
thing that compiles here and blows up over there.

The reason to accept it anyway is that the successor is **much more expensive than it
first looks**, and the honest cost belongs on the record now, while nobody is under time
pressure, rather than being rediscovered by whoever eventually picks the work up. A
`sherpa-onnx` engine does not simply replace one plugin call with another. It returns
**raw audio samples, not sound**, so it additionally needs:

- an **audio-playback dependency** to turn those samples into something audible, itself a
  plugin with its own three-platform story;
- a **shared phonemiser data directory** (`espeak-ng`-style data) that must be shipped,
  unpacked to a writable location and found again at run time on all three platforms;
- **per-voice model downloads** — the voices are not in the installer, so there is a
  download UI, progress, failure and retry;
- **somewhere to keep them**, which means a managed cache directory per platform, a size
  the learner can see, and a way to remove a voice again.

That is a feature in its own right, not a swap. And the one thing that would tell us
whether it is *necessary* — how the Microsoft French and Italian voices actually sound
saying a real word from a real deck — is answered by shipping the cheap engine and
listening.

## Decision

**The engine sits behind the `TtsEngine` interface in core. `flutter_tts` is the one
concrete implementation shipped in this round, in `ui_kit`. Each shell injects the engine
it wants: the real one where the plugin exists, `UnavailableTtsEngine` everywhere else.
Linux therefore ships mute, deliberately and visibly.**

Four rules follow and are not negotiable:

1. **Core never speaks.** It describes speech — the voices a host reports, the utterances
   to say, the interface to say them through — and performs no I/O and no plugin call.
   The concrete engine lives in `ui_kit` so both shells consume one implementation;
   neither shell writes its own.
2. **The platform branch has a working non-Windows arm**, as the repo requires. The
   desktop shell selects `FlutterTtsEngine` on Windows and `UnavailableTtsEngine`
   otherwise. Linux is never handed a plugin that is not there, so it cannot reach a
   `MissingPluginException`; it is handed an engine that reports itself unavailable.
3. **Unavailable means the feature is absent, not broken.** Where the engine reports
   itself unavailable there are no speaker icons, no `F4` utterance and no
   **Options ▸ Speech** entry at all. The program never offers something it cannot do,
   and the user guide says plainly that Linux speech is not available yet — silence the
   learner can look up beats silence she has to diagnose.
4. **A stored voice choice names an engine as well as a voice**
   (`VoiceChoice` = engine id + voice id within that engine), never a bare operating-system
   voice name. The two planned engines identify voices incompatibly — one by an installed
   OS voice name, the other by a model file — so this is what stops the settings key
   having to be reshaped when the engine changes. A choice made for an engine that is not
   the current one falls through to automatic resolution rather than silencing the field.

## Consequences

Accepted, and visible:

- **The repo's Linux-and-Android rule is knowingly deviated from, once, here.** This is
  the exception and it is bounded: it is accepted because the gap is *contained by the
  interface* (no core or `ui_kit` code path assumes the plugin exists), because it is
  *visible* (Linux users are told, in the guide, in both languages), and because it is
  *reversible* (the successor engine plugs into the same seam without touching the
  settings schema or the policy). It is not a precedent for adding a Windows-only
  dependency to anything that is not behind an interface with a working null
  implementation.
- **The Linux build cannot be verified from the authoring machine.** Adding a plugin with
  no Linux implementation is expected to compile with the plugin simply unregistered, but
  the generated `linux/flutter/generated_plugin_registrant.cc` and the lockfile must be
  checked on the Linux machine. Every commit in this feature says this was not done on
  Windows.
- **Voice quality is committed to on research, not on hearing it.** A listening spike was
  considered and deliberately dropped. If the operating system's voices turn out to be
  poor, `flutter_tts` becomes throwaway work and the successor's much larger cost arrives
  sooner than planned — which is precisely why the cost is written down above, so that
  decision is not made from the optimistic version of it.
- **The rate is expressed as a share of normal speed and mapped by the engine.** The app
  carries 0.5–1.5 with 1.0 as normal; `FlutterTtsEngine.pluginSpeechRate` maps that onto
  the plugin's own scale. A successor engine maps the same app-level number its own way,
  and no stored setting changes.
- **The engine keeps no state between utterances.** Everything about what is to be said —
  text, language, resolved voice, rate — is on the `SpeechUtterance` the policy produced.
  An engine is a dispatcher, which is what makes a recording fake a complete stand-in for
  it in tests.
- **A lead-in is planned, and made by the engine per host.** The utterance carries
  whether a short silence goes before it (`leadIn`); the engine decides how, because the
  hosts wake differently: Windows plays a muted filler, Android wraps the word in SSML
  with a `<break>`. That keeps the engine stateless, at one cost to name here: an Android
  speech engine without SSML support reads the markup aloud. That is audible, not silent,
  and the only remedy is the learner switching the lead-in off, which the help text says.
- **A plugin failure is silence, not an error.** `FlutterTtsEngine` treats a
  `PlatformException` or `MissingPluginException` as nothing said. Speech is presentation
  only: it creates no attempt, moves no counter, and touches neither mastery nor the
  Level-Learning ladder, so the worst case has to be that the learner hears nothing.
- **No test on any host plays audio.** The policy is pure in, pure out; the session tests
  drive a recording fake through the same interface the shells inject into. The
  consequence to be honest about is that **timing rules are pinned by assertion and not
  by ear**.

## Alternatives rejected

- **Shipping `sherpa-onnx` first.** Rejected on cost: audio playback, phonemiser data,
  model downloads and a managed store, all before a single word is spoken — with the
  question of whether the cheap engine would have sufficed still unanswered.
- **Waiting until an engine covers all three platforms.** Rejected because it holds
  Windows and Android speech hostage to Linux, indefinitely, for a feature two of three
  platforms could have today.
- **Driving Piper as an external process.** Rejected in the research: a subprocess, a WAV
  file and an audio player is more plumbing than `sherpa-onnx` for the same class of
  models, and it has no Android story at all.
- **`espeak-ng` for Linux only, alongside `flutter_tts` elsewhere.** Two concrete engines
  to maintain, and the one added for coverage is the one that sounds worst — a
  pronunciation teacher whose Linux users learn from the least natural voice available.
  Linux gets the successor engine, or it stays mute.
- **Letting the plugin throw on Linux and catching it.** Rejected: it makes an absent
  feature look like a failing one. Injecting an engine that reports itself unavailable
  lets the UI omit what it cannot offer, which is the difference between a program that
  does not speak and one that is broken.
