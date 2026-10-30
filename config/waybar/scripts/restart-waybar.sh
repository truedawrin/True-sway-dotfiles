#!/usr/bin/env bash
set -Eeuo pipefail

palette="$HOME/.config/waybar/wallust-colors.css"
if [[ ! -s "$palette" ]]; then
    old_palette="$HOME/.cache/wallpaper-theme/waybar-colors.css"
    if [[ -s "$old_palette" ]]; then
        cp -- "$old_palette" "$palette"
    else
        "$HOME/.config/wallpaper/wallpaper-theme" --restore
    fi
fi

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pkill -f "^cava -p ${runtime_dir}/waybar-cava-${UID}\\.conf$" 2>/dev/null || true
pkill -x waybar 2>/dev/null || true
sleep 0.3
exec waybar
