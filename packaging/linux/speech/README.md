# Setting up good Linux voices: Speech Dispatcher + Piper

**Audience: an agent (or a person) setting this up on another Linux machine.** Follow it
top to bottom; the commands are meant to be run as written.

Learn Anywhere speaks on Linux through Speech Dispatcher, using whatever voices the
*system* has (see [ADR-0008](../../../docs/adr/0008-linux-speaks-through-speech-dispatcher.md)).
By itself that is eSpeak NG — robotic, but universal. This runbook adds
[Piper](https://github.com/OHF-Voice/piper1-gpl) voices alongside it and fixes the two
things that make a naive Piper setup feel broken: a multi-second delay before speech, and
the app listing eSpeak NG's ~13,000 voice/variant entries before Piper's handful. **None
of this touches Learn Anywhere's code** — it is Speech Dispatcher and user-level systemd
configuration only. It was worked out on one machine (Zorin OS, PipeWire, Intel SOF
audio); the Gotchas section records what went wrong there.

## What you end up with

- Speech Dispatcher's `sd_generic` module driving Piper through a small wrapper script
  (`bin/piper_wrapper`).
- **One** background service, `piper-server`, that keeps voice models loaded in memory.
  The first use of a voice is still a few seconds; later uses are not.
- `DefaultModule piper` in `speechd.conf`, so Piper's voices — not eSpeak NG's — are what
  **Automatic** picks and what **Options ▸ Speech...** lists first.
- The Speech rate slider working for Piper voices, not just eSpeak NG's.
- A systemd override so a wedged `speech-dispatcher` recovers in ~10 s by itself.
- `bin/restart-audio.sh`, a one-command restart of the PipeWire stack for the "no sound
  anywhere" freeze (see *When all sound stops*).

That is the entire runtime: **one service, no always-on audio player.** Each spoken
sentence is played by a fresh, short-lived `pw-play` (or `aplay`) that the wrapper starts
and stops.

## Do not add a persistent audio player

An earlier version of this setup ran one permanent `pw-play` per sample rate, fed through
a named pipe, to avoid the cost of opening an audio connection per sentence. **Do not
re-introduce it**, and do not "optimise" this setup by keeping any audio stream open.

- **What went wrong.** The permanent players kept the sound card's stream open for the
  whole session. On the reference machine (Intel SOF DSP, kernel 7.0), sound was then
  dead after suspend/resume: the speaker's ALSA stream sat in `PREPARED` and never ran
  again. Restarting PipeWire, cycling the card profile, stopping the players and
  suspending a second time did not recover it; only a reboot did. A second user account
  without any of this setup resumed fine on the same hardware, and so did the original
  account once the six player units were disabled (boot and resume also felt quicker).
  The exact mechanism is not proven; the evidence is that with/without comparison.
- **The cost it was meant to avoid is small.** A fresh `pw-play` connection measured about
  0.1 s on that machine (0.33 s cold vs 0.24 s warm for a 0.1 s clip) — not the 2+ seconds
  originally believed. The multi-second delay is the model load, which `piper-server`
  already fixes.
- **It also broke stopping.** Speech Dispatcher cancels speech by killing the process it
  started. With a shared player that process was only the writer into a pipe, so a word
  kept playing after "stop". The wrapper now plays in the foreground of its own process,
  so cancelling really cuts the audio off.
- **It needed three of everything.** A long-lived player is fixed to one sample rate,
  and Piper voices differ (16000, 22050 and 44100 Hz all occur), so each rate needed its
  own player plus a "holder" process to keep its pipe open — six units, plus login-race
  workarounds for PipeWire not being ready yet. A per-utterance player reads the rate from
  the WAV header and needs none of that.

If speech ever feels too slow, look at the server and the wrapper first (see *If speech
starts late*), not at the audio path.

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
sudo apt install pipx     # Debian/Ubuntu/Zorin
sudo dnf install pipx     # Fedora/Nobara
```

Confirm the daemon actually speaks before going any further:

```sh
spd-say "Hello"
```

If nothing is heard, stop here and fix that first — nothing below helps a broken base
install.

## Everything else (no sudo, as the target user)

1. Copy this whole `packaging/linux/speech/` directory onto the target machine (or clone
   the repo there).
2. Decide which voices you want — see [`voices.md`](voices.md) for the download recipe and
   the known-good reference set (one male and one female per language). Download them into
   `~/.local/share/piper/voices/` *before* running `setup.sh`.
3. Edit [`speechd/piper.conf.template`](speechd/piper.conf.template)'s `AddVoice` lines to
   match the voices you downloaded, if different from the reference set.
4. Run the setup script. It is idempotent — re-run it after downloading more voices or
   editing the template:

   ```sh
   sh packaging/linux/speech/setup.sh
   ```

   It also **removes the retired persistent-player units** if an earlier version of this
   setup installed them (see above), so re-running it is the upgrade path.
5. `setup.sh` prints three commands instead of running them, because enabling a unit to
   start at login is a persistent change the user should confirm. **An agent should ask
   the user before running them**:

   ```sh
   systemctl --user daemon-reload
   systemctl --user enable --now piper-server.service
   systemctl --user restart speech-dispatcher
   ```

## Verifying it worked

```sh
spd-say "Hello"                                     # should now be Piper, not eSpeak NG
spd-say -o piper -y en_GB-alan-medium.onnx "Hello"  # a specific Piper voice by name
spd-say -O                                          # piper must be among the output modules
spd-say -o piper -L                                 # piper's own voices, with language tags
systemctl --user is-active piper-server             # active
```

From the repository root, the diagnostic the user guide points learners at doubles as a
setup check — it lists every module and voice, reports the default module and speaks one
sample per language using the voice Learn Anywhere's own code would pick:

```sh
dart run packages/ui_kit/tool/ssip_diagnostic.dart
```

On the reference machine it prints (trimmed — the `espeak-ng` line alone is ~13,000 voices):

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

`Default module: piper` and every sample resolving to a `piper:` voice (not `espeak-ng:`)
shows the voice ordering landed. If a sample resolves to `espeak-ng:`, re-check
`DefaultModule` in `speechd.conf`.

**After the first reboot** (autostart is the one part nothing above exercises):

```sh
spd-say -O                                  # piper must be listed
systemctl --user is-active piper-server     # active
ps -eo pid,stat,cmd | grep defunct          # no sd_generic zombie
pgrep -a pw-play                            # nothing — no player runs between sentences
```

**Then test suspend**, because that is what the retired design broke: play a sound, close
the lid (or run `systemctl suspend`), resume, and play a sound again. Run this test on any
machine you set up. Sound must come back by itself.

Finally open Learn Anywhere and check **Options ▸ Speech...**: Piper's voices should be
first for every language that has one.

## If speech starts late

Expect roughly a second between pressing the speaker icon and hearing a word on a voice
already used this session; the first use of each voice after the server starts takes a few
seconds while its model loads. If it is much slower:

1. `systemctl --user is-active piper-server` — if the server is down the wrapper falls
   back to running `piper` cold, which reloads the model every time (several seconds).
   `journalctl --user -u piper-server` shows why it stopped.
2. Time the pieces by hand: `time sh ~/.local/bin/piper_wrapper "Hello" en_GB-alan-medium.onnx 0`.
3. A very busy machine slows everything (see *Resource contention* below).

## When all sound stops

Sometimes *no* application can play sound — not Learn Anywhere, not a browser video. This
is not necessarily caused by Piper (see above for the one way this setup once caused it).
Two triggers have been reported on the reference machine: unplugging headphones, and
resuming from suspend. Symptoms: `pw-play` of any file never finishes,
`pw-top` shows a sink with a large ERR count, and the speaker's ALSA stream stays stuck:

```sh
cat /proc/asound/card0/pcm0p/sub0/status     # "state: PREPARED", hw_ptr stays 0
```

Try, in this order, stopping at the first that works:

1. `bin/restart-audio.sh` (installed as `~/.local/bin/restart-audio.sh`; worth a desktop
   shortcut). It restarts `pipewire`, `pipewire-pulse` and `wireplumber`. Nothing of
   Learn Anywhere's needs restarting afterwards. This clears a PipeWire-level freeze.
2. Reboot. When the sound card's DSP itself is stuck (the `PREPARED` state above), a
   PipeWire restart does not help, and neither did suspending and resuming again; on the
   reference machine only a reboot recovered it. Reloading the audio driver
   (`snd_sof_pci_intel_cnl` there) is the untested alternative.

If this happens on every suspend, the cause is the machine's audio driver or firmware, not
this setup: confirm by testing in a second user account that has none of this installed,
and look for a newer kernel or SOF firmware.

## Gotchas

**`spd-conf -u` deletes your custom module configs with no warning.** Run *after*
`piper.conf` exists in `~/.config/speech-dispatcher/modules/`, it silently wipes the whole
`modules/` directory, `piper.conf` included. That is why `setup.sh` copies
`/etc/speech-dispatcher/speechd.conf` instead of calling it. If you run it anyway, re-run
`setup.sh` afterwards.

**Adding one `AddModule` line turns off autodetection of every other module.** With no
explicit `AddModule` lines, Speech Dispatcher probes and loads every module it can find —
which is why eSpeak NG "just worked" before. Add **one** explicit line for `piper` and only
modules listed explicitly load. Forget `espeak-ng` and `dummy` and you silently lose them.
`setup.sh` and `speechd/speechd.conf.snippet` add all three together for this reason.

**A module in your `AddModule` list whose binary doesn't exist can break the whole
service.** The reference machine also had `sd_openjtalk` installed, so an earlier draft
added it unconditionally. Don't copy that line onto a machine that hasn't confirmed the
binary exists (`ls /usr/lib/speech-dispatcher-modules/ | grep openjtalk`); it isn't needed
for any of Learn Anywhere's languages.

**`pw-play` has no `--raw` flag**, despite several guides using one. For raw PCM pass
`--rate`, `--channels` and `--format`; it infers raw input from those. `--raw` fails with
"unknown option" and nothing plays. (The wrapper only streams raw PCM in its cold fallback;
the normal path plays a WAV file, whose header carries the rate.)

**`piper.http_server` needs Flask, and `pipx install piper-tts` does not pull it in.**
Without it the server dies with `ModuleNotFoundError: No module named 'flask'`. Fix:
`pipx inject piper-tts flask`. `setup.sh` does this.

**Each `piper` invocation reloads its ONNX model from disk**, which alone costs several
seconds. That is the reason `piper-server` exists: it keeps loaded voices in memory. The
wrapper falls back to a cold one-shot `piper` run only if the server is unreachable.

**Which module's voices list first, and what "Automatic" picks, is controlled entirely by
`DefaultModule` in `speechd.conf` — not by Learn Anywhere.** The app's
`listOutputModules()` (`packages/ui_kit/lib/src/speech/speech_dispatcher_voices.dart`)
puts whichever module `DefaultModule` names first, by design. Leave it at the distro
default (usually `espeak-ng`) and eSpeak NG's huge catalog buries Piper's handful at the
bottom of every dropdown even though Piper works.

**Hugging Face's voice-file URLs repeat the locale-speaker-quality triple in full** — a
shortened or guessed path 404s with no redirect:

```
.../resolve/main/<lang>/<locale>/<speaker>/<quality>/<locale>-<speaker>-<quality>.onnx
```

`voices.md` has a working download loop.

**The Speech rate slider needs explicit wiring to reach Piper.** `sd_generic` doesn't apply
Learn Anywhere's rate by itself; `GenericExecuteSynth` must pass `$RATE`, which
`piper.conf.template` does and `bin/piper_wrapper` turns into a `length_scale` multiplier.
Two traps:

- `GenericRateAdd`/`GenericRateMultiply` are parsed as **integers only** —
  `GenericRateMultiply 0.5` silently truncates to `0`, giving a flat result with no error.
  Use `GenericRateMultiply 100` to reconstruct the original value losslessly and do the
  float math (`1.0 - rate/200.0`) in the wrapper.
- `$RATE` is **not** SSIP's documented -100..100 by the time it reaches
  `GenericExecuteSynth`; `sd_generic` normalises it to -1.0..1.0 first.
  `GenericRateMultiply 100` undoes that too, so both fixes are one line. (Confirmed with
  `Debug 1` in `piper.conf` and `~/.config/speech-dispatcher/log/piper.log`, which prints
  the `synth command = |...|` line per utterance.)

**A voice that is unusually fast or slow needs its own fix, independent of the slider.**
`it_IT-paola` speaks noticeably faster than the rest of the reference set. Raise
`inference.length_scale` in that voice's `<name>.onnx.json` (default `1.0`; higher is
slower). The wrapper multiplies the slider's effect onto each voice's own base value, so
both apply, and the change touches only that voice.

**Resource contention is not a Learn Anywhere bug.** Cold-loading several ~60 MB models
back to back, restarting `speech-dispatcher` repeatedly and stress-testing the server is
enough load on a modest machine to make an unrelated GTK app feel sluggish for a few
seconds. If the symptom appeared only during heavy setup work, don't chase it.

**One stuck module can freeze the whole daemon and silence every other module.** After
hours of uptime (with a CPU-heavy build running), `sd_espeak-ng` got stuck in a blocking
PulseAudio call (`pa_simple_new() failed: Zeitüberschreitung` in the log). Speech
Dispatcher didn't isolate that: its main process blocked, `sd_generic` (Piper) died and
was never relaunched, and `systemctl --user stop/restart` hung for the default ~90 s.
Symptoms looked like two bugs — eSpeak NG voices present but silent, Piper voices gone —
from one wedged process. Recovery:

```sh
kill -9 <main speech-dispatcher PID>      # status shows "deactivating" for a long time
systemctl --user stop speech-dispatcher.service speech-dispatcher.socket
rm -f "$XDG_RUNTIME_DIR/speech-dispatcher/speechd.sock"
systemctl --user reset-failed speech-dispatcher.service
systemctl --user start speech-dispatcher.socket speech-dispatcher.service
```

`setup.sh` installs a small override (`TimeoutStopSec=10`, `Restart=on-failure`,
`RestartSec=2`) so systemd caps the hang and restarts the daemon, bringing back
`sd_espeak-ng` and `sd_generic` together. The underlying PulseAudio hiccup's root cause is
unconfirmed.

**Piper voices missing from the app although the config is right.** Run `spd-say -O`. If
`piper` isn't listed, the generic module died during start and left a defunct `sd_generic`
child (`ps -eo pid,stat,cmd | grep defunct`). `systemctl --user restart
speech-dispatcher.service` brings it back; reopen **Options ▸ Speech...**. The cause of the
one observed occurrence is unknown; it did not recur after a reboot.

## If you get stuck

Re-run `dart run packages/ui_kit/tool/ssip_diagnostic.dart` (repo root) and read its
module/voice listing closely — it shows exactly what Learn Anywhere's code sees, using the
same client. If `piper` isn't in the module list, the problem is in `speechd.conf` or
`piper.conf`, not in Learn Anywhere. If it is there with 0 voices,
`journalctl --user -u speech-dispatcher` and the module's own log
(`$XDG_RUNTIME_DIR/speech-dispatcher/log/piper.log`, created once the module has been
selected) show why `sd_generic` refused the voice list.
