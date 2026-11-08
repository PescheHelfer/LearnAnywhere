# Piper voices used by the working reference setup

Not committed to the repo — `.onnx` files run 15-65 MB each. Each voice is a pair of
files, `<name>.onnx` and `<name>.onnx.json`, downloaded from the Piper project's voice
repository on Hugging Face:

```
https://huggingface.co/rhasspy/piper-voices/resolve/main/<lang>/<locale>/<speaker>/<quality>/<locale>-<speaker>-<quality>.onnx
https://huggingface.co/rhasspy/piper-voices/resolve/main/<lang>/<locale>/<speaker>/<quality>/<locale>-<speaker>-<quality>.onnx.json
```

`<lang>` is the bare two-letter code (`en`, `de`, `it`, `fr`); `<locale>` is
`<lang>_<REGION>` (`en_GB`, `de_DE`); the full path repeats the locale-speaker-quality
triple. Get this wrong and you get a 404, not a redirect — there is no fallback
resolution.

## The reference set (male + female per language, one machine's choice)

| File (without extension) | Locale | Variant | Sample rate | Notes |
|---|---|---|---|---|
| `en_GB-alan-medium` | en-GB | MALE1 | 22050 | preferred first for plain `en` |
| `en_GB-jenny_dioco-medium` | en-GB | FEMALE1 | 22050 | |
| `en_US-amy-medium` | en-US | FEMALE1 | 22050 | extra, not required |
| `de_DE-thorsten-medium` | de-DE | MALE1 | 22050 | |
| `de_DE-kerstin-low` | de-DE | FEMALE1 | 16000 | no medium/high female German voice exists yet |
| `it_IT-paola-medium` | it-IT | FEMALE1 | 22050 | **speaks unusually fast** — `length_scale` raised to `1.25` in her `.onnx.json`, see the README's gotchas |
| `it_IT-riccardo-x_low` | it-IT | MALE1 | 16000 | no medium/high male Italian voice exists yet |
| `fr_FR-tom-medium` | fr-FR | MALE1 | 44100 | note the higher rate — not every "medium" voice is 22050 |
| `fr_FR-siwis-medium` | fr-FR | FEMALE1 | 22050 | |

Browse [the voice sample gallery](https://rhasspy.github.io/piper-samples/) to audition
others before downloading — some voices for a given language are much better than
others, and there is no quality metric besides listening.

`AddVoice`'s middle argument (the "variant") must be one of `MALE1`-`MALE3`,
`FEMALE1`-`FEMALE3`, `CHILD_MALE` or `CHILD_FEMALE` — anything else is silently not
offered.

## Downloading the reference set

```sh
VOICES_DIR="$HOME/.local/share/piper/voices"
mkdir -p "$VOICES_DIR"
BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main"

download() { # lang locale speaker quality
  local lang=$1 locale=$2 speaker=$3 quality=$4
  local name="${locale}-${speaker}-${quality}"
  curl -sSfL -o "$VOICES_DIR/$name.onnx" "$BASE/$lang/$locale/$speaker/$quality/$name.onnx"
  curl -sSfL -o "$VOICES_DIR/$name.onnx.json" "$BASE/$lang/$locale/$speaker/$quality/$name.onnx.json"
}

download en en_GB alan medium
download en en_GB jenny_dioco medium
download de de_DE thorsten medium
download de de_DE kerstin low
download it it_IT paola medium
download it it_IT riccardo x_low
download fr fr_FR tom medium
download fr fr_FR siwis medium
```

Then raise Paola's rate (see the README's "A voice that is too fast or slow" gotcha):

```sh
python3 -c "
import json
path = '$HOME/.local/share/piper/voices/it_IT-paola-medium.onnx.json'
with open(path) as f: d = json.load(f)
d['inference']['length_scale'] = 1.25
with open(path, 'w') as f: json.dump(d, f, indent=2)
"
```
