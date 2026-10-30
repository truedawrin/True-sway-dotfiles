#!/usr/bin/env bash
set -euo pipefail

chosen="$(printf '%s\n' \
    '󰐥  Shut down' \
    '󰜉  Reboot' \
    '󰤄  Suspend' \
    '󰒲  Hibernate' \
    '󰍃  Log out' \
    '󰌾  Lock screen' |
    rofi -dmenu -p 'Power Menu:' -i \
        -theme-str 'window { width: 24%; } listview { lines: 6; padding: 12px; } element { padding: 8px; }')" || exit 0

case "$chosen" in
    *"Shut down") systemctl poweroff ;;
    *"Reboot") systemctl reboot ;;
    *"Suspend") systemctl suspend ;;
    *"Hibernate") systemctl hibernate ;;
    *"Log out") swaymsg exit ;;
    *"Lock screen") "$HOME/.config/wallpaper/lock-screen" ;;
esac
