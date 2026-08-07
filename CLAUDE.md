# Learn Anywhere — Claude notes

One repo, three targets: **Windows** and **Linux** desktop (`packages/desktop`) and an
**Android** companion (`packages/mobile`, later stage). You can only build and run the
target you are sitting on. Everything below exists so work done on one machine cannot
break another.

## The rule that matters most

**Never edit another platform's runner directory blind.** From Windows, treat
`packages/desktop/linux/` as read-only; from Linux, treat `packages/desktop/windows/`
as read-only; likewise `packages/mobile/android/` unless you can build it.

`windows/runner/flutter_window.cpp` contains a deliberate **`SC_KEYMENU` patch** (it
stops Windows beeping on ALT mnemonics). Never regenerate or overwrite it, and never
run `flutter create` over an existing platform folder.

If a value must agree across runners, change the one you can build and **report the
mismatch** instead of silently editing the other. Values that must agree:

| | current value | Windows | Linux |
|---|---|---|---|
| binary name | `LearnAnywhere` | `windows/CMakeLists.txt` `BINARY_NAME` | `linux/CMakeLists.txt` `BINARY_NAME` |
| product / window title | `Learn Anywhere` | `runner/main.cpp` `kWindowTitle` + `Runner.rc` `ProductName` | `runner/my_application.cc` `kWindowTitle` |
| application ID | `com.sbitfire.LearnAnywhere` | `runner/main.cpp` `kAppUserModelId` | `linux/CMakeLists.txt` `APPLICATION_ID` |
| default size | `1280×720` | `runner/main.cpp` | `runner/my_application.cc` |
| company | `SbitFire Software` | `Runner.rc` `CompanyName` | — |

The native binary name is **not** the Dart package name: `packages/desktop/pubspec.yaml`
is still `learn_anywhere_desktop` and every `package:learn_anywhere_desktop/...` import
depends on it. Never "fix" one to match the other. When Android arrives, its
`applicationId` should be `com.sbitfire.LearnAnywhere` too.

## Paths — assume nothing about separators

- Use `DeckPaths` (`packages/core/lib/paths/deck_paths.dart`) or `package:path`
  (`p.join`, `p.dirname`, `p.basenameWithoutExtension`, `p.setExtension`).
- **Never** hand-roll `lastIndexOf(Platform.pathSeparator)`, never hardcode `\` or a
  drive letter, never split a path on `'/'` or `'\'`.
- A **backslash is a legal file-name character on Linux.** Splitting on both
  separators "to be safe" is a Linux bug, not a safety net.
- Put new path logic in **core** (pure Dart) and test it against **both** `p.windows`
  and `p.posix` explicitly, so it passes on any host. See `test/deck_paths_test.dart`.
- `Platform.isWindows` branches must always have a working non-Windows arm
  (`APPDATA` → `XDG_CONFIG_HOME`/`$HOME/.config`).

## Case sensitivity — Linux and Android are case-sensitive

Every import/export path, asset path, and fixture path must match the on-disk name
**character for character**. A rename that only changes case needs
`git mv --force old new`, then confirm with `git status` that git actually recorded it
— an unrecorded case rename still breaks Linux.

## Fonts — never depend on an installed system font

Fixed-width unit and field containers are sized by measuring one character, so their
geometry must not vary by host. Always style them via
`LearnAnywhereTokens.monospace(...)`, which pins the ui_kit-bundled JetBrains Mono.
Never reach for `'Consolas'`, `'Cascadia Mono'`, or a bare `'monospace'` as the family
— those are Windows-only or resolve to a *proportional* face. Bundle new fonts in
`packages/ui_kit/assets/fonts/` (both shells consume ui_kit) with a permissive licence.

## Documentation must move with the change

The user guide ships **inside** the app (`packages/ui_kit/assets/help/en/` and
`.../de/`), rendered by `HelpViewer` under **Help ▸ User guide** / `F1`. It is not a
side artefact — it is a screen of the program, and a stale chapter is a bug.

- Any **user-visible** change — a menu item, screen, option, shortcut, message, file
  format or behaviour — updates the guide **in both languages, in the same commit**.
- The two language folders keep **identical file names** and the same heading
  structure. Add a chapter by adding the file to both; the chapter list is discovered
  from the asset manifest, so there is no list in Dart to edit.
- One `#` heading per chapter (its title in the contents list). `##` headings are the
  anchors, the search granularity, and the **only** scroll targets — never link to a
  `#` or `###` anchor.
- Quote UI labels **verbatim from the matching catalog** in
  `packages/core/lib/i18n/i18n.dart` — the German guide names the German labels. Never
  translate a label freshly; a reader must be able to find it on screen.
- `packages/ui_kit/test/help_content_test.dart` enforces parity, single titles, and
  that every cross-chapter link and `#anchor` resolves. Run it after editing chapters.
- Changes to the feature list, install steps or build commands also update the root
  `README.md`. Developer-facing structure goes to `ARCHITECTURE.md` / `docs/`, not the
  user guide. A version bump follows the rule in `packages/desktop/CLAUDE.md`.

## Versions and tags — two products, two tracks

Desktop and Android ship **separately, with different feature sets**, so they carry
**independent versions**: `packages/desktop/pubspec.yaml` and
`packages/mobile/pubspec.yaml` move on their own. Neither is "the" project version, and
there is no version in the root `pubspec.yaml`.

Bump the version of **each app whose users see a difference** — not each package that
was touched. `core` and `ui_kit` are never versioned or released on their own; they
ship inside whichever shell they affect. Two consequences that look surprising but are
correct:

- A change that edits **only** `core` (say, a new engine behaviour desktop surfaces)
  still bumps **desktop**, because a desktop user sees it.
- A change that edits `core` **and** desktop files but alters nothing a desktop user
  can observe — e.g. adding mobile-only message keys to `i18n.dart` — bumps **Android
  only**.

Git tags are **prefixed per product**, because one tag namespace covers both:

| Product | Tag | Bump rule |
|---|---|---|
| Desktop | `desktop-v0.6.1` | `packages/desktop/CLAUDE.md` (pubspec **and** About history) |
| Android | `android-v0.1.0` | `packages/mobile/pubspec.yaml`; About shows version + licence only |

Bare `v0.2.0`…`v0.6.0` are pre-split desktop history; leave them alone. Prefixes also
keep `git describe --tags --match 'desktop-v*'` honest once the two series interleave —
with bare tags an Android release silently becomes the nearest tag to a desktop commit.

**Tag on `master`, after merging**, never on the feature branch: a squash or rebase
merge rewrites the branch's commits and strands the tag on an orphan.

**Android's `versionCode` must strictly increase, every single release.** It is not a
separate field to maintain — `app/build.gradle.kts` takes `versionCode =
flutter.versionCode`, which Flutter derives from the **build number after the `+`** in
`packages/mobile/pubspec.yaml` (`0.1.0+1` → `1`). Android's package manager refuses to
install an APK over an installed one with an equal or lower `versionCode`, and a
sideloaded build has no store to catch the mistake: the phone just says the app is not
installed and gives no reason. So bump `+N` on **every** shipped Android build, including
a rebuild of the same semver.

## Tags are not releases

A git tag — pushed or not — is only a marker. It appears under the **Tags** tab of
GitHub's releases page and nothing more. A **Release** (notes, attached binaries, and the
only thing `/releases/latest` considers) is a separate object created deliberately in the
UI or with `gh release create`. Nothing promotes a tag into one automatically.

So tagging a development milestone is free: `android-v0.1.0` marks where the Android
foundation landed without claiming the app is shippable.

Pushing follows the same split. `git push origin master` pushes the branch **only** —
tags never ride along with a branch push unless `push.followTags` is set.
`--follow-tags` adds the *annotated* tags reachable from the pushed commits; blunt
`git push --tags` shoves every local tag at the remote and is best avoided.

`README.md` must not link to GitHub's `/releases/latest`. That URL resolves to whichever
release was published most recently **across the whole repository** — GitHub ignores tag
prefixes — so once an Android release exists it can hand a desktop user an APK. Link to
`/releases` instead.

## Line endings

`.gitattributes` pins the repo to LF (`* text=auto eol=lf`). Don't run tools that
rewrite line endings in bulk (`sed -i`, `Set-Content` without `-Encoding`, editors set
to CRLF). `*.vok` / `*.inf` / `*.sta` are compared **byte for byte** by
`packages/core/test/core_test.dart` — one CRLF checkout fails that test.

## Dependencies and fixtures

- Before adding a package, confirm it resolves a **Linux and an Android**
  implementation, not just Windows. Check `pubspec.lock` and the generated
  `linux/flutter/generated_plugin_registrant.cc`.
- Anything a test reads must be **committed**, and must live under that package's own
  `test/fixtures/` — never in `docs/`. `core_test.dart` reads
  `packages/core/test/fixtures/example.{inf,vok}` by a package-root-relative path, so
  the test works under `melos run test:core` and under a bare `dart test` alike. A
  gitignored or out-of-package fixture passes locally and fails on every fresh clone.
- `docs/` is tracked and holds living developer reference only. Project history
  (requirements lineage, feedback rounds, implementation prompts, audits, legacy
  screenshots) is kept outside the repository in the maintainer's local archive; don't
  add it back, and don't reference its path from a tracked file.

## Verifying cross-platform work

`flutter analyze` and the `packages/core` + `packages/ui_kit` suites are
host-independent: they must pass on either machine, so run them for any change.
`packages/desktop` widget tests are host-independent too and will catch layout
overflow. Only build/run the target you are on; note in the commit what you could not
verify. One pre-existing `packages/mobile` widget-test failure is a known baseline —
confirm a mobile failure reproduces at `HEAD` before treating it as yours.

## Android (arriving later)

Keep `packages/mobile` depending only on `core` + `ui_kit`, never on `desktop`. Any
file/path behaviour it needs belongs in **core** behind the shared API so all three
shells derive paths identically.

## Agent skills

### Issue tracker

Local markdown under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Domain docs

Multi-context: root `CONTEXT-MAP.md` plus a `CONTEXT.md` and `docs/adr/` per package
(`packages/core`, `packages/ui_kit`, `packages/desktop`, `packages/mobile`). See
`docs/agents/domain.md`.
