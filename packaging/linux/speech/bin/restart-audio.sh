#!/bin/sh
# Recovers from the "no sound anywhere, even after unplugging headphones"
# PipeWire freeze. See packaging/linux/speech/README.md's Gotchas section
# in the LearnAnywhere repo for background.
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service
sleep 2
# Our own persistent Piper audio players were holding connections into the
# now-dead PipeWire session; they need restarting too or Piper voices stay
# silent even after the above fixes everything else.
systemctl --user restart \
  piper-audio-holder@16000.service piper-audio-holder@22050.service piper-audio-holder@44100.service \
  piper-audio-player@16000.service piper-audio-player@22050.service piper-audio-player@44100.service \
  2>/dev/null
notify-send "Audio restarted" "PipeWire and Piper's audio players have been restarted." 2>/dev/null
