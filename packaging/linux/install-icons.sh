#!/bin/sh
#
# Install the Learn Anywhere icons and desktop entry into a freedesktop icon
# theme. Intended for .deb/.rpm packaging and for local testing; the AppImage
# does not need this — it carries its own icon.
#
# Usage:
#   ./install-icons.sh                 # system-wide, into /usr
#   DESTDIR=/tmp/pkg ./install-icons.sh   # staged install for a package build
#   PREFIX="$HOME/.local" ./install-icons.sh   # per-user install
#
# Icons are installed as <size>x<size>/apps/learn_anywhere.png, matching
# Icon=learn_anywhere in com.sbitfire.learnanywhere.desktop and kIconName in
# packages/desktop/linux/runner/my_application.cc.

set -eu

SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SOURCE_DIR/../.." && pwd)
ICON_SOURCE_DIR="$REPO_ROOT/design/icons/linux"

DESTDIR=${DESTDIR:-}
PREFIX=${PREFIX:-/usr}
ICON_NAME=learn_anywhere
DESKTOP_ENTRY=com.sbitfire.learnanywhere.desktop

ICON_ROOT="$DESTDIR$PREFIX/share/icons/hicolor"
APPLICATIONS_DIR="$DESTDIR$PREFIX/share/applications"

install_icon() {
  size=$1
  source_file="$ICON_SOURCE_DIR/learn-anywhere-${size}x${size}.png"
  if [ ! -f "$source_file" ]; then
    echo "missing source icon: $source_file" >&2
    exit 1
  fi
  target_dir="$ICON_ROOT/${size}x${size}/apps"
  install -d "$target_dir"
  install -m 644 "$source_file" "$target_dir/$ICON_NAME.png"
}

for size in 16 24 32 48 64 128 256; do
  install_icon "$size"
done

# The icon set currently ships PNGs only. Install the scalable variant if and
# when an SVG master is added, rather than failing the whole install over it.
svg_source="$ICON_SOURCE_DIR/learn-anywhere.svg"
if [ -f "$svg_source" ]; then
  install -d "$ICON_ROOT/scalable/apps"
  install -m 644 "$svg_source" "$ICON_ROOT/scalable/apps/$ICON_NAME.svg"
else
  echo "note: no $svg_source — skipping scalable/apps/$ICON_NAME.svg" >&2
fi

install -d "$APPLICATIONS_DIR"
install -m 644 "$SOURCE_DIR/$DESKTOP_ENTRY" "$APPLICATIONS_DIR/$DESKTOP_ENTRY"

# Refresh the theme cache so the shell picks the icons up without a re-login.
# Skipped for staged installs (DESTDIR), where the package manager does it.
if [ -z "$DESTDIR" ] && command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache --force --quiet "$ICON_ROOT"
fi

if [ -z "$DESTDIR" ] && command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATIONS_DIR"
fi

echo "installed $ICON_NAME icons and $DESKTOP_ENTRY under $DESTDIR$PREFIX"
