# Setting up good Linux voices: Speech Dispatcher + Piper

Learn Anywhere speaks on Linux through Speech Dispatcher, using whatever voices the
*system* has (see [ADR-0008](../../../docs/adr/0008-linux-speaks-through-speech-dispatcher.md)).
By itself that's eSpeak NG — robotic, but universal. This runbook adds
[Piper](https://github.com/OHF-Voice/piper1-gpl) voices alongside it, and fixes the two
things that make a naive Piper setup feel broken: multi-second startup delay, and the app
listing eSpeak NG's ~13,000 voice/variant entries before Piper's handful. **None of this
touches Learn Anywhere's code** — it's entirely Speech Dispatcher and system
configuration, reproduced from one working machine (Zorin OS, PipeWire).

Read this top to bottom before running anything. The **Gotchas** section at the end
covers failures that are easy to hit and non-obvious to diagnose; several steps below
exist specifically to avoid them, and the reasoning is there, not repeated at each step.

## What you end up with

- Speech Dispatcher's `sd_generic` module driving `piper` through a small wrapper script.
- A background `piper.http_server` instance that keeps voice models warm in memory
  (first use of a voice is still a few seconds; every use after that is not).
- One persistent audio-playback process **per sample rate** your installed voices use,
  so playback skips PipeWire's own multi-second per-connection cost.
- `DefaultModule piper` in `speechd.conf`, so Piper's voices — not eSpeak NG's — are what
  **Automatic** picks and what `Options ▸ Speech...` lists first for every language.

## Distro packages (needs sudo — do this first, as yourself)

Speech Dispatcher itself, and eSpeak NG as its always-present fallback:

```sh
# Debian/Ubuntu/Zorin:
sudo apt install speech-dispatcher speech-dispatcher-espeak-ng

# Fedora/Nobara:
sudo dnf install speech-dispatcher speech-dispatcher-espeak-ng speech-dispatcher-utils
```

Also needed, almost certainly already present on a desktop install: `python3`, `curl`,
and one of `pipewire-utils` (`pw-play`) or `alsa-utils` (`aplay`). `pipx` may not be:

```sh
# Debian/Ubuntu/Zorin:
sudo apt install pipx
# Fedora/Nobara:
sudo dnf install pipx
```

Confirm the daemon actually speaks before going any further:

```sh
spd-say "Hello"
```

If nothing is heard, stop here and fix that first — nothing below will help a broken
base install.

## Everything else (no sudo, as the target user)

1. Copy this whole `packaging/linux/speech/` directory onto the target machine (or just
   clone the repo there).
2. Decide which voices you want — see [`voices.md`](voices.md) for the download
   recipe, the voice sample gallery, and the known-good reference set (one male + one
   female per language). Download them into `~/.local/share/piper/voices/` *before*
   running `setup.sh`, so it can see their sample rates.
3. Edit [`speechd/piper.conf.template`](speechd/piper.conf.template)'s `AddVoice` lines
   to match the voices you actually downloaded, if different from the reference set.
4. Run the setup script:

   ```sh
   sh packaging/linux/speech/setup.sh
   ```

   It is idempotent — re-run it after downloading more voices, or after editing the
   template. It prints the exact `systemctl --user enable --now ...` commands to run at
   the end, rather than running them itself, because enabling a unit to autostart at
   login is a persistent change worth looking at first. (An agent running this under
   Claude Code will likely be stopped and asked to get the user's confirmation at that
   step — that is expected, not a failure.)
5. Run those printed commands.
6. Restart Speech Dispatcher so it picks up the new `speechd.conf`:

   ```sh
   systemctl --user restart speech-dispatcher
   ```

## Verifying it worked

```sh
spd-say "Hello"                                    # should now be Piper, not eSpeak NG
spd-say -o piper -y en_GB-alan-medium.onnx "Hello"  # a specific Piper voice by name
spd-say -O                                          # lists output modules; piper should be in there
spd-say -o piper -L                                 # lists piper's own voices with their language tags
```

From the repository root, the full diagnostic the user guide points learners at for a
silent install also doubles as a setup check — it lists every module and voice, reports
the default module, and speaks one sample per language using the exact voice Learn
Anywhere's own code would pick:

```sh
dart run packages/ui_kit/tool/ssip_diagnostic.dart
```

On the reference machine this prints (trimmed — the `espeak-ng` line alone is ~13,000
voices):

```
Default module: piper
Module piper: 17 voices
Module espeak-ng: 13362 voices
en: piper: en_GB-alan-medium.onnx (en)
de: piper: de_DE-thorsten-medium.onnx (de)
fr: piper: fr_FR-tom-medium.onnx (fr)
it: piper: it_IT-riccardo-x_low.onnx (it)
All samples spoken.
```

`Default module: piper` and every sample resolving to a `piper:` voice (not
`espeak-ng:`) is the signal that both the warm-start and voice-ordering fixes actually
landed. If a sample instead resolves to `espeak-ng:`, re-check `DefaultModule` in
`speechd.conf` (gotcha below).

Finally, open Learn Anywhere itself and check **Options ▸ Speech...**: Piper's voices
should be the first ones listed for every language that has one, and the speaker icon /
`F4` in a learning session should start speaking in well under a second on a voice
that's already been used once this session.

## Gotchas — all of these were hit building this, in this order

**`spd-conf -u` deletes your custom module configs with no warning.** If you ever run
`spd-conf -u` (Speech Dispatcher's own "create user config" tool) *after* `piper.conf`
already exists in `~/.config/speech-dispatcher/modules/`, it silently wipes the entire
`modules/` directory as part of "recreating" the user config — `piper.conf` included.
This is why `setup.sh` copies `/etc/speech-dispatcher/speechd.conf` directly instead of
calling `spd-conf -u`. If you do run it anyway for some other reason, re-run `setup.sh`
afterward to restore `piper.conf`.

**Adding one `AddModule` line turns off autodetection of every other module.** With *no*
explicit `AddModule` lines anywhere in `speechd.conf`, Speech Dispatcher auto-probes
every module it can find and silently loads whichever ones work — this is almost
certainly why eSpeak NG (and maybe others) "just worked" before you touched anything.
The moment you add **one** explicit `AddModule` line for `piper`, that autodetection
switches off completely, and *only* the modules you listed explicitly will load. Forget
to also list `espeak-ng` and `dummy`, and you will silently lose them both. `setup.sh`
and `speechd/speechd.conf.snippet` both add all three together for exactly this reason.

**A module in your `AddModule` list whose binary doesn't exist can break the whole
service, not just that module.** The reference machine also had `sd_openjtalk`
installed and working, so an earlier draft of this setup added it unconditionally.
Don't copy that line onto a machine that hasn't confirmed the binary exists:

```sh
ls /usr/lib/speech-dispatcher-modules/ | grep openjtalk
```

If it's not there, leave that `AddModule` line out — it isn't needed for any of Learn
Anywhere's languages anyway.

**`pw-play` has no `--raw` flag**, despite several setup guides online using one. Pass
`--rate`, `--channels` and `--format` directly; `pw-play` infers raw PCM input from
those flags alone. Using `--raw` fails with "Unbekannte Option" / "unknown option" and
nothing plays.

**Not every Piper voice shares a sample rate**, even within "medium" quality — on the
reference set, `fr_FR-tom-medium` is 44100 Hz while every other `medium` voice here is
22050 Hz, and the two `low`/`x_low` voices are 16000 Hz. A persistent audio player
started at a fixed rate makes every other-rate voice sound wrong (pitch-shifted, too
fast or too slow) — never hardcode one rate. Read `audio.sample_rate` out of each
voice's own `.onnx.json` and run one persistent player per **distinct** rate actually
present (`piper-audio-holder@<rate>` / `piper-audio-player@<rate>` in this runbook);
`setup.sh` derives the rate list from whatever is in `~/.local/share/piper/voices/`
rather than assuming any fixed set.

**`piper.http_server` needs Flask, and `pipx install piper-tts` does not pull it in.**
Running it straight after a plain install fails with
`ModuleNotFoundError: No module named 'flask'`. Fix: `pipx inject piper-tts flask`.
`setup.sh` does this automatically.

**The multi-second delay has two separate, unrelated causes — fixing one without the
other still feels slow.**
1. `piper` reloads its ONNX model from disk on every single invocation, which alone
   costs several seconds regardless of sentence length. `piper.http_server` keeps
   voices loaded in memory between requests once they've been used once — fixes this
   half.
2. Independently, opening a *brand-new* audio connection per utterance — which is what
   a naive `GenericExecuteSynth` command does if it ends in a fresh `pw-play` (or
   `aplay`) every time — itself costs roughly 1.8-2.7 seconds **on this machine**,
   regardless of which player binary is used (`pw-play`, `aplay` and `pw-cat` were all
   equally slow in testing: this is PipeWire connection/negotiation overhead, not a
   player-specific problem). Fixing #1 alone leaves this cost in place and the delay
   still feels like "a couple of seconds," just not four. The FIFO-fed persistent player
   in this runbook fixes this half.

**The persistent player has a real, accepted trade-off: it breaks "stop and read the
next word" interrupting mid-playback.** Speech Dispatcher's own cancel mechanism works
by killing the process `GenericExecuteSynth` started. With a short-lived
one-player-per-utterance design, that process *is* the thing making sound, so killing
it genuinely stops the audio. With the shared persistent player here, the process
Speech Dispatcher can kill is just the wrapper script that *wrote into a pipe* — by the
time a "stop" arrives, that write likely already finished, and the shared player will
keep playing what it already received. In practice: revealing a new unit in Learn
Anywhere while a previous word is still being read may let that previous word finish
instead of being cut off. This was a deliberate, informed choice (the alternative is the
2-3 second delay above on every single utterance) — if that trade-off isn't acceptable
on a given machine, skip the persistent-player half of this setup and keep the
per-utterance `pw-play` call; the warm HTTP server alone still saves several seconds.

**Which module's voices list first in Learn Anywhere, and what "Automatic" picks, is
controlled entirely by `DefaultModule` in `speechd.conf` — not by anything in Learn
Anywhere.** The app's own `listOutputModules()`
(`packages/ui_kit/lib/src/speech/speech_dispatcher_voices.dart`) always puts whichever
module `DefaultModule` names first, by design, so "Automatic" matches how the machine
itself is configured. Forget this line (or leave it at its distro default, usually
`espeak-ng`), and eSpeak NG's huge voice catalog will bury Piper's handful at the bottom
of every per-language dropdown even though Piper is fully working. No code touches this
— it's one line in `speechd.conf`.

**Hugging Face's voice-file URLs repeat the locale-speaker-quality triple in full — a
shortened or guessed path 404s with no redirect.** The pattern is:

```
.../resolve/main/<lang>/<locale>/<speaker>/<quality>/<locale>-<speaker>-<quality>.onnx
```

Not `.../<speaker>/<quality>.onnx` or any other shortened form. See `voices.md` for a
working download loop.

**A voice that's unusually fast or slow compared to the others can't be fixed by Learn
Anywhere's Speech rate slider**, which applies to every voice equally. `it_IT-paola`
specifically speaks noticeably faster than every other voice in the reference set, for
no documented reason — just how that voice was trained. Fix it per-voice, in Piper's own
config: raise `inference.length_scale` in that voice's `<name>.onnx.json` (default
`1.0`; higher is slower). This only affects that one voice, nowhere else.

**Apparent "the whole app got sluggish" during setup was resource contention, not a
Learn Anywhere bug.** Cold-loading several ~60 MB ONNX models back to back, plus
repeatedly restarting `speech-dispatcher`, plus stress-testing the HTTP server, is
enough background CPU/memory load on a modest machine to make an unrelated GTK app feel
sluggish for a few seconds — don't go chasing an app-level performance bug if the
symptom only showed up *during* heavy setup work and disappeared once things were idle.

## If you get stuck

Re-run `dart run packages/ui_kit/tool/ssip_diagnostic.dart` (repo root) and read its
module/voice listing closely — it shows you exactly what Learn Anywhere's own code sees,
using the same client. If `piper` isn't in the module list at all, the problem is in
`speechd.conf`/`piper.conf`, not in Learn Anywhere. If it's there but has 0 voices,
`journalctl --user -u speech-dispatcher` and the module's own log
(`$XDG_RUNTIME_DIR/speech-dispatcher/log/piper.log`, created after the module has been
selected at least once) will show why `sd_generic` refused the voice list.
