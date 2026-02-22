#!/bin/sh
#
# OpenCode / oh-my-opencode config (symlink into ~/.config/opencode)
#

set -e

# Config files live in opencode/ (parent of scripts/)
SOURCE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TARGET_DIR="$HOME/.config/opencode"

mkdir -p "$TARGET_DIR"

link_if_missing() {
  src="$1"
  dst="$2"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  Skipping (already exists): $dst"
    return 0
  fi

  ln -s "$src" "$dst"
  echo "  Linked: $dst -> $src"
}

link_dir_if_missing() {
  src="$1"
  dst="$2"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  Skipping (already exists): $dst"
    return 0
  fi

  ln -s "$src" "$dst"
  echo "  Linked: $dst -> $src"
}

echo "Installing OpenCode config..."
link_if_missing "$SOURCE_DIR/opencode.json" "$TARGET_DIR/opencode.json"
link_if_missing "$SOURCE_DIR/oh-my-opencode.json" "$TARGET_DIR/oh-my-opencode.json"

exit 0
