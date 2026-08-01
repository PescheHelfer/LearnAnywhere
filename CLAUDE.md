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
