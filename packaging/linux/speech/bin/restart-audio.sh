#!/bin/sh
# Recovers from the "no sound anywhere" PipeWire freeze by restarting the audio
# stack. See packaging/linux/speech/README.md, "When all sound stops", for what
# this does and does not fix.
#
# Learn Anywhere's own speech needs nothing restarted afterwards: Piper plays each
# utterance through a fresh, short-lived player, so there is no connection into the
# old PipeWire session to repair.
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
sleep 2
notify-send "Audio restarted" "PipeWire has been restarted." 2>/dev/null || true
