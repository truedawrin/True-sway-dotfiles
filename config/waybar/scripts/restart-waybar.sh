#!/usr/bin/env bash
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pkill -f "^cava -p ${runtime_dir}/waybar-cava-${UID}\\.conf$" 2>/dev/null || true
pkill -x waybar 2>/dev/null || true
sleep 0.3
exec waybar
