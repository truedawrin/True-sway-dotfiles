#!/usr/bin/env bash
set -o pipefail

source_config="$HOME/.config/cava/config"
umask 077
temp_config="${XDG_RUNTIME_DIR:-/tmp}/waybar-cava-${UID}.conf"
trap 'rm -f "$temp_config"' EXIT

# Reuse Cava's input, smoothing, and Wallust color settings, but stream a compact
# ASCII spectrum to Waybar instead of opening a terminal visualizer.
sed -e '/^\[general\]/a bars = 14' -e '/^\[output\]/a method = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 7\nbar_delimiter = 59\nframe_delimiter = 10' "$source_config" > "$temp_config"

cava -p "$temp_config" | while IFS= read -r frame; do
    IFS=';' read -r -a levels <<< "$frame"
    bars=''
    for level in "${levels[@]}"; do
        case "$level" in
            0) bars+="▁" ;;
            1) bars+="▂" ;;
            2) bars+="▃" ;;
            3) bars+="▄" ;;
            4) bars+="▅" ;;
            5) bars+="▆" ;;
            6) bars+="▇" ;;
            *) bars+="█" ;;
        esac
    done
    printf '%s\n' "$bars" 2>/dev/null || exit 0
done
