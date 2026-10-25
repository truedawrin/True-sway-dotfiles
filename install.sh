#!/usr/bin/env bash
# Link this repo into ~/.config with GNU stow.
# Re-run after adding files:  ./install.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

if ! command -v stow >/dev/null; then
    echo "GNU stow is required:  sudo pacman -S stow" >&2
    exit 1
fi

# --restow re-links everything; safe to run repeatedly.
if ! stow --target="$HOME" --restow config; then
    echo >&2
    echo "Stow hit a conflict. Simulated view of the offending paths:" >&2
    stow --target="$HOME" --simulate --restow config 2>&1 | sed 's/^/  /' >&2
    echo >&2
    echo "Move those existing files out of the way (or delete them) and retry." >&2
    exit 1
fi

echo "Linked into ~/.config. Reload sway with:  swaymsg reload"
