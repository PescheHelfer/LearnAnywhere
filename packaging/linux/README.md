# Building the Linux AppImage

This produces a single `.AppImage` that runs on the machine it's built on and on newer
distros (older glibc runs on newer systems, never the reverse). Recipe lives at
`packaging/linux/AppImageBuilder.yml`; the built `.AppImage` itself is **not** committed —
it's attached to a GitHub Release (see the end of this file).

## One-time machine setup

```bash
sudo apt-get install -y pipx patchelf desktop-file-utils fakeroot strace \
                        squashfs-tools zsync libgdk-pixbuf2.0-dev
pipx install appimage-builder
pipx ensurepath

mkdir -p ~/bin && cd ~/bin
wget -O appimagetool \
  https://github.com/probonopd/go-appimage/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool
echo 'export PATH="$PATH:$HOME/bin"' >> ~/.profile
source ~/.profile
```

We use the `go-appimage` build of `appimagetool` (statically linked runtime) rather than
the classic one, because the classic runtime needs the host's `libfuse2`, which some
distros (e.g. Nobara) don't ship.

### Known `appimage-builder` bug on Ubuntu 24.04 — patch required

`appimage-builder` compares package versions with Python's `packaging.version.parse`,
which expects PEP440 version strings. Ubuntu 24.04's own `dpkg` package is versioned
`1.22.6ubuntu6`, which isn't valid PEP440, so a stock install crashes with
`InvalidVersion: '1.22.6ubuntu6'` partway through the apt-deploy step.

Find the file (path will vary slightly by Python version):

```bash
find ~/.local/share/pipx/venvs/appimage-builder -name package.py -path "*apt*"
```

Open it and change the `__gt__` method from:

```python
def __gt__(self, other):
    if isinstance(other, Package):
        return version.parse(self.version) > version.parse(other.version)
```

to:

```python
def __gt__(self, other):
    if isinstance(other, Package):
        try:
            return version.parse(self.version) > version.parse(other.version)
        except version.InvalidVersion:
            # Debian/Ubuntu version strings (e.g. "1.22.6ubuntu6") are not
            # always valid PEP440, unlike pip package versions. Fall back to
            # a chunked digit/non-digit comparison, which is good enough to
            # tell "newer" from "older" for the purpose of this filter.
            def chunks(v):
                return [
                    (0, int(c)) if c.isdigit() else (1, c)
                    for c in re.findall(r"\d+|\D+", v)
                ]

            return chunks(self.version) > chunks(other.version)
```

(`re` is already imported at the top of that file.) This is a pipx-managed venv, so a
`pipx reinstall` or `pipx upgrade appimage-builder` will wipe the patch — reapply it if
that happens and the build starts failing with the same `InvalidVersion` error again.

### apt sandbox needs a trusted keyring

`appimage-builder` runs its own sandboxed `apt-get update` under `appimage-build/apt/`
in the repo root (created on first run). If it fails with
`NO_PUBKEY ...` / "is not signed", it's missing a keyring in that sandbox:

```bash
cp /usr/share/keyrings/ubuntu-archive-keyring.gpg appimage-build/apt/keys/
```

Only needed once per repo checkout — `appimage-build/` is gitignored and persists
locally between builds.

## Every time you build a new version

1. Bump `version:` in `packages/desktop/pubspec.yaml`.
2. Update `version:` in `AppImageBuilder.yml` to match.
3. Build the release bundle:

   ```bash
   cd packages/desktop
   flutter build linux --release
   cd ..
   ```

4. Build the AppImage (two passes — assemble the AppDir, then package it):

   ```bash
   appimage-builder --recipe packaging/linux/AppImageBuilder.yml --skip-tests --skip-appimage
   VERSION=<the version from step 1/2> appimagetool AppDir
   ```

   Without `VERSION` set, `appimagetool` falls back to naming the file after the current
   git commit hash instead of the app version.

5. Verify it runs:

   ```bash
   chmod +x Learn_Anywhere-*.AppImage
   ./Learn_Anywhere-*.AppImage
   ```

   It should open, look correct, and load a `.vok` deck. If it prints
   `FlutterEngineCreateAOTData ... Invalid ELF path specified` and refuses to start, the
   `AppDir/lib/libapp.so` symlink the recipe's `script:` step creates is missing —
   check that step in `AppImageBuilder.yml` hasn't been edited out.

## Verifying speech

Linux speaks through Speech Dispatcher, over its socket, in pure Dart (see
[ADR-0008](../../docs/adr/0008-linux-speaks-through-speech-dispatcher.md)). For adding
Piper voices on top of the distro's bundled eSpeak NG — and fixing the multi-second
startup delay and voice-ordering issues a naive Piper setup has — see
[`speech/README.md`](speech/README.md), a runbook reproduced from one working machine.
The automated
tests drive a fake daemon on loopback TCP and never hear a word, so a release that changes
speech is checked by ear, on each distro, before it counts as supported there. A pass on
one distro says nothing about the other.

The diagnostic below talks to the real daemon with the same client the program uses,
lists what it finds, says one sample per language, and logs every line on the wire. It
needs only the Dart SDK that comes with Flutter. Run it from the repository root:

```bash
dart run packages/ui_kit/tool/ssip_diagnostic.dart
```

It exits with 1 when anything failed, including no service at all.

1. Note whether `speech-dispatcher` is preinstalled. Then run the program **without** it:
   speaker icons still show, `F4` names the language with no voice, and every row under
   **Options ▸ Speech...** says the computer has no voice for it.
2. Install it with the `apt` or `dnf` line from the user guide's *Installing speech on
   Linux* section, confirming the package names on this distro, and check that
   `spd-say "Hello"` is audible.
3. Run the diagnostic: voices are listed with their languages, the default module is
   reported, and the `en`, `de`, `fr` and `it` samples are all audible, accents included.
4. From the **AppImage**, not a debug build: a speaker icon, `F4`, a multi-field answer read
   field by field in order, and the sample button under **Options ▸ Speech...**.
5. Hold `Enter` through several units and press `F4` repeatedly: words never stack. Leaving
   a session stops speech. Audio from other applications is not cut off. A change of
   **Speech rate** is audible.
6. Listen for a lost first syllable after a pause in typing, through headphones as well as
   speakers. That decides whether **Wake the audio output before speaking** comes back on
   Linux, and how.

## Publishing

The `.AppImage` is a build artifact, not source — don't commit it. Attach it to a
GitHub Release instead:

Desktop tags are prefixed `desktop-v*`, because one tag namespace covers both the
desktop app and the Android companion, which version independently. See "Versions and
tags" in the root [`CLAUDE.md`](../../CLAUDE.md).

```bash
git tag -a desktop-v0.6.1 -m "Desktop 0.6.1"
git push origin desktop-v0.6.1
gh release create desktop-v0.6.1 Learn_Anywhere-0.6.1-x86_64.AppImage
```

Push the one tag, not `git push --tags` — the latter shoves every local tag at the
remote, including any Android or scratch tags that aren't ready to be published.

Only a **Release** (this `gh release create`) is a download. A bare pushed tag just
appears under the Tags tab, so tagging a development milestone publishes nothing.

## Before a public release

Ship a build made against Ubuntu 22.04 (glibc 2.35), not whatever base this machine
runs — building on a newer base raises the glibc floor and excludes anyone on an older
LTS. Do stages 1–2, 5–8 above inside an `ubuntu:22.04` container, and change
`AppImageBuilder.yml`'s `noble` → `jammy` and `gcc-14-base` → `gcc-12-base` for that
build.
