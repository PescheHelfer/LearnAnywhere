#!/bin/sh
# Installs this runbook's Piper + Speech Dispatcher setup for the CURRENT
# user. Idempotent — safe to re-run after downloading more voices, or after
# editing a template. Never calls sudo; every distro package this setup
# needs (speech-dispatcher itself, espeak-ng, python3, pipx, curl, an audio
# player) must already be installed — see README.md's "Distro packages"
# step, which differs between apt and dnf.
#
# What this does NOT do: download voice files (see ../voices.md — voice
# choice is a personal decision, not something to automate), or run
# `systemctl --user enable` silently. The enable/start step is printed at
# the end for you to run yourself, once you've confirmed the config looks
# right — enabling a unit to autostart at login is a persistent change,
# and an agent running this under Claude Code will likely be asked to
# confirm it explicitly at that step; that's expected, not a bug in this
# script.
set -eu

SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HOME_DIR="$HOME"

echo "== Checking prerequisites =="
missing=0
for cmd in python3 pipx curl spd-say; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "MISSING: $cmd — install it via your distro's package manager first." >&2
    missing=1
  fi
done
if ! command -v pw-play >/dev/null 2>&1 && ! command -v aplay >/dev/null 2>&1; then
  echo "MISSING: no pw-play or aplay found — install pipewire-utils or alsa-utils." >&2
  missing=1
fi
if [ "$missing" -ne 0 ]; then
  echo "Install the missing commands above, then re-run this script. No sudo here." >&2
  exit 1
fi

echo "== Installing piper-tts (idempotent) =="
if ! pipx list --short 2>/dev/null | grep -q '^piper-tts '; then
  pipx install piper-tts
else
  echo "piper-tts already installed via pipx."
fi
# http_server needs Flask, which piper-tts does NOT pull in on its own —
# this is the single most common reason the server fails at startup with
# "ModuleNotFoundError: No module named 'flask'".
pipx inject piper-tts flask >/dev/null 2>&1 || pipx inject piper-tts flask

PIPER_PYTHON="$HOME_DIR/.local/share/pipx/venvs/piper-tts/bin/python"
if [ ! -x "$PIPER_PYTHON" ]; then
  echo "Expected $PIPER_PYTHON after pipx install — pipx's venv layout may have" >&2
  echo "changed; find it with: pipx list -v | grep piper-tts" >&2
  exit 1
fi

VOICES_DIR="$HOME_DIR/.local/share/piper/voices"
mkdir -p "$VOICES_DIR"

echo "== Installing the wrapper script =="
mkdir -p "$HOME_DIR/.local/bin"
cp "$SOURCE_DIR/bin/piper_wrapper" "$HOME_DIR/.local/bin/piper_wrapper"
chmod +x "$HOME_DIR/.local/bin/piper_wrapper"

echo "== Installing the Speech Dispatcher module config =="
mkdir -p "$HOME_DIR/.config/speech-dispatcher/modules"
sed "s|{{HOME}}|$HOME_DIR|g" "$SOURCE_DIR/speechd/piper.conf.template" \
  > "$HOME_DIR/.config/speech-dispatcher/modules/piper.conf"
echo "Wrote $HOME_DIR/.config/speech-dispatcher/modules/piper.conf"
echo "Edit its AddVoice lines to match the voices you actually downloaded —"
echo "see ../voices.md. A voice named there but not present in"
echo "$VOICES_DIR is simply not offered, so this is safe to leave broad."

echo "== Speech Dispatcher's speechd.conf =="
SPEECHD_CONF="$HOME_DIR/.config/speech-dispatcher/speechd.conf"
if [ ! -f "$SPEECHD_CONF" ]; then
  # Deliberately NOT using `spd-conf -u` here: on the machine this runbook
  # was written on, running it AFTER piper.conf already existed wiped the
  # whole user modules/ directory (piper.conf included) with no prompt
  # warning that would happen. Copying the system default is equivalent
  # and does not touch modules/.
  if [ -f /etc/speech-dispatcher/speechd.conf ]; then
    mkdir -p "$HOME_DIR/.config/speech-dispatcher"
    cp /etc/speech-dispatcher/speechd.conf "$SPEECHD_CONF"
    echo "Copied the system default to $SPEECHD_CONF"
  else
    echo "No /etc/speech-dispatcher/speechd.conf to copy from — is" >&2
    echo "speech-dispatcher actually installed? See README.md." >&2
    exit 1
  fi
fi
add_line_if_missing() {
  line=$1
  grep -qxF "$line" "$SPEECHD_CONF" || { echo "" >> "$SPEECHD_CONF"; echo "$line" >> "$SPEECHD_CONF"; }
}
# Every explicit AddModule line below is required SIMULTANEOUSLY, because
# adding even one turns off speech-dispatcher's autodetection of every
# OTHER module — see speechd/speechd.conf.snippet for the long version of
# why. openjtalk is deliberately not added here; it needs its own optional
# package and isn't needed for Learn Anywhere's languages.
add_line_if_missing 'AddModule "espeak-ng" "sd_espeak-ng" "espeak-ng.conf"'
add_line_if_missing 'AddModule "dummy"     "sd_dummy"    ""'
add_line_if_missing 'AddModule "piper" "sd_generic" "piper.conf"'
# A second uncommented DefaultModule line is a config error, not silently
# ignored, so replace rather than append if one is already there.
if grep -qE '^DefaultModule ' "$SPEECHD_CONF"; then
  sed -i 's/^DefaultModule .*/DefaultModule piper/' "$SPEECHD_CONF"
else
  add_line_if_missing 'DefaultModule piper'
fi
echo "speechd.conf has the required AddModule/DefaultModule lines."

echo "== Installing the Piper HTTP server unit =="
mkdir -p "$HOME_DIR/.config/systemd/user"
default_voice=$(ls "$VOICES_DIR"/*.onnx 2>/dev/null | head -n1 | xargs -r basename | sed 's/\.onnx$//')
if [ -z "$default_voice" ]; then
  echo "No voices in $VOICES_DIR yet — using a placeholder default voice" >&2
  echo "name. Download at least one voice (see ../voices.md), then re-run" >&2
  echo "this script so the server unit names a real one." >&2
  default_voice="PLACEHOLDER-no-voice-downloaded-yet"
fi
sed -e "s|{{HOME}}|$HOME_DIR|g" -e "s|{{DEFAULT_VOICE}}|$default_voice|g" \
  "$SOURCE_DIR/systemd/piper-server.service.template" \
  > "$HOME_DIR/.config/systemd/user/piper-server.service"

echo "== Removing the retired persistent audio player units (if present) =="
# An earlier version of this setup ran permanent per-sample-rate pw-play players
# (piper-audio-holder@/piper-audio-player@). They kept the sound card open for the
# whole session and, on the machine this was developed on, left ALL audio dead after
# suspend/resume - see README.md "Do not add a persistent audio player". Machines
# set up with that version must lose them, so this is cleanup, not an optional step.
# Disabling units that are going away is safe to do here; nothing else depends on them.
USER_UNITS="$HOME_DIR/.config/systemd/user"
# Instances (piper-audio-player@22050.service) are not shown by list-unit-files, so
# gather them from the enable symlinks and from whatever is currently loaded.
old_units=$( {
  for f in "$USER_UNITS"/default.target.wants/piper-audio-*.service; do
    [ -e "$f" ] || [ -L "$f" ] && basename "$f"
  done
  systemctl --user list-units --all --plain --no-legend 'piper-audio-*' 2>/dev/null | awk '{print $1}'
} | sort -u | grep -v '^$' || true)
if [ -n "$old_units" ]; then
  # shellcheck disable=SC2086
  systemctl --user disable --now $old_units 2>/dev/null || true
fi
rm -f "$USER_UNITS/piper-audio-holder@.service" "$USER_UNITS/piper-audio-player@.service"
rm -f "$USER_UNITS"/default.target.wants/piper-audio-*.service
rm -f "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/piper_audio_*.fifo

echo "== Bounding speech-dispatcher's hang/restart time =="
# See README.md's "One stuck module can freeze the whole daemon" gotcha: a module
# stuck in a blocking audio call can wedge the WHOLE speech-dispatcher process, not
# just itself, for the default ~90s stop timeout, silently stranding every other
# module (Piper included) in the meantime. This override doesn't fix that underlying
# hang, but bounds recovery to seconds and restarts automatically instead of needing
# a manual `kill -9`.
mkdir -p "$HOME_DIR/.config/systemd/user/speech-dispatcher.service.d"
cat > "$HOME_DIR/.config/systemd/user/speech-dispatcher.service.d/override.conf" <<'EOF'
[Service]
TimeoutStopSec=10
Restart=on-failure
RestartSec=2
EOF

echo "== Installing the audio-stack recovery script =="
# See README.md's "Unplugging headphones can wedge PipeWire itself" gotcha - a
# separate, unrelated PipeWire bug, not caused by this setup, but worth having
# a one-command fix on hand for regardless.
cp "$SOURCE_DIR/bin/restart-audio.sh" "$HOME_DIR/.local/bin/restart-audio.sh"
chmod +x "$HOME_DIR/.local/bin/restart-audio.sh"
echo "Installed to $HOME_DIR/.local/bin/restart-audio.sh - consider a desktop"
echo "shortcut to it, the same way as to Learn Anywhere itself."

echo
echo "== Done. Review the files above, then run: =="
echo
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now piper-server.service"
echo "  systemctl --user restart speech-dispatcher"
echo
echo "That is the whole runtime: one background server (keeps voice models in memory)"
echo "and nothing else. No audio player is kept running - see README.md."
echo
echo "Then verify with (see README.md's 'Verifying it worked' for detail):"
echo "  spd-say \"Hello\""
echo "  spd-say -o piper -y $default_voice \"Hello from Piper\""
echo "  dart run packages/ui_kit/tool/ssip_diagnostic.dart   # from the repo root"
