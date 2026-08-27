#include "flutter_window.h"

#include <cwctype>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Every letter used as an `&`-accelerator anywhere in the desktop menu bar
// (top-level entries AND submenu items, EN and DE), upper-cased. Windows has no
// visibility into Flutter's menu widgets - there is no native HMENU on this
// window - so DefWindowProc's default WM_SYSCHAR handling beeps for *every*
// Alt+<letter> regardless of whether Flutter recognizes it as a mnemonic. To
// silence the beep only for keystrokes Flutter actually acts on, this list must
// mirror the `&`-prefixed characters in
// packages/core/lib/i18n/i18n.dart (search for "// top-bar" and the trailing
// "// <letter>" comments). Update it by hand whenever a menu label's
// accelerator letter changes there; see docs/menu-alt-mnemonics.md.
//
// U+00DC (Latin capital letter U with diaeresis, the DE accelerator for the
// "practice/Ueben" menu item) is spelled as a universal character escape
// rather than a literal non-ASCII byte, so this compiles correctly regardless
// of the MSVC source-file encoding/code-page in effect.
constexpr wchar_t kMenuAcceleratorChars[] = L"ABCDEFGHIJKLMNOPSTUVXYZ\u00DC";

bool IsMenuAcceleratorChar(WPARAM wparam) {
  const wchar_t upper = std::towupper(static_cast<wchar_t>(wparam));
  for (const wchar_t* candidate = kMenuAcceleratorChars; *candidate;
       ++candidate) {
    if (*candidate == upper) {
      return true;
    }
  }
  return false;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    // Window is shown by window_manager from the Dart side.
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_SYSCOMMAND:
      if (wparam == SC_KEYMENU) {
        // Disable ALT application menu (SC_KEYMENU) so Windows does not
        // intercept the Alt keypress before Flutter's key event system sees it.
        // Without this, MenuAcceleratorLabel highlights appear with ~1s delay.
        // See: https://github.com/flutter/flutter/issues/177822
        return 0;
      }
      break;
    case WM_SYSCHAR:
      // Flutter's KeyboardManager deliberately never marks a "sys" message
      // handled from the Dart side - per the framework's own comment, "SYS
      // messages must not be consumed by HandleMessage so that they are
      // forwarded to the system" - so HandleTopLevelWindowProc above always
      // returns nullopt for WM_SYSCHAR and we always reach this switch. This
      // window has no native HMENU (the menu bar is entirely Flutter-drawn),
      // so DefWindowProc's default WM_SYSCHAR handling has no accelerator to
      // match and calls MessageBeep() unconditionally - the Windows "ding" on
      // every Alt+<letter>, even though the Dart-side menu (see
      // packages/desktop/lib/main.dart and docs/menu-alt-mnemonics.md) opens
      // or activates correctly regardless. Swallow the message ourselves for
      // characters that ARE one of our accelerators so no beep occurs; Flutter's
      // own mnemonic handling runs off the earlier WM_SYSKEYDOWN and is
      // unaffected either way. Letters that aren't a registered accelerator
      // fall through to DefWindowProc and still beep, which is expected. Note
      // AltGr combinations (e.g. German @, EUR, braces) never reach this case
      // at all: Windows reports them as Control+AltRight, which suppresses the
      // WM_SYSKEYDOWN/WM_SYSCHAR "sys" path entirely in favor of ordinary
      // WM_CHAR - the same distinction the Dart-side isControlPressed check
      // relies on to detect AltGr.
      if (IsMenuAcceleratorChar(wparam)) {
        return 0;
      }
      break;
    case WM_MENUCHAR:
      // Defensive safety net, not expected to actually fire: WM_MENUCHAR is
      // only sent while Windows' own native menu-tracking loop is active, and
      // that loop never starts here because the WM_SYSCOMMAND/SC_KEYMENU case
      // above (and the Dart-side bare-Alt swallow) prevent the window from
      // ever entering it. If some future change did let it start, returning
      // MNC_CLOSE tells Windows to silently close the (nonexistent) menu
      // instead of beeping. Uses MAKELONG (windows.h) rather than MAKELRESULT
      // to avoid pulling in windowsx.h for a single macro.
      return static_cast<LRESULT>(MAKELONG(0, MNC_CLOSE));
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
