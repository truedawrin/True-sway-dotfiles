#!/usr/bin/env bash
set -u

emit_status() {
    local source mute

    source="$(pactl get-default-source 2>/dev/null)" || source=""
    if [[ -z "$source" ]]; then
        printf '{"text":" Mic ?","class":"unavailable","tooltip":"No default microphone source is available"}\n'
        return
    fi

    mute="$(pactl get-source-mute "$source" 2>/dev/null | awk '{print tolower($2)}')" || mute=""
    case "$mute" in
        yes)
            printf '{"text":" Muted","class":"muted","tooltip":"Microphone muted · click or press F4 to unmute"}\n'
            ;;
        no)
            printf '{"text":" Mic","class":"on","tooltip":"Microphone on · click or press F4 to mute"}\n'
            ;;
        *)
            printf '{"text":" Mic ?","class":"unavailable","tooltip":"Could not read microphone mute state"}\n'
            ;;
    esac
}

case "${1:---status}" in
    --toggle)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        pkill -RTMIN+9 -x waybar 2>/dev/null || true
        ;;
    --status)
        emit_status
        ;;
    *)
        printf 'Usage: %s [--status|--toggle]\n' "$0" >&2
        exit 2
        ;;
esac
