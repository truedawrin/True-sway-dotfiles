#!/usr/bin/env bash
set -u

if ! command -v checkupdates >/dev/null 2>&1; then
    text=' !'
    class='error'
    tooltip='checkupdates is unavailable (install pacman-contrib).'
else
    error_file="$(mktemp)"
    trap 'rm -f "$error_file"' EXIT
    updates="$(checkupdates 2>"$error_file")"
    status=$?
    error_text="$(<"$error_file")"

    if [[ -n "$updates" ]]; then
        count="$(printf '%s\n' "$updates" | awk 'NF { n++ } END { print n+0 }')"
        text=" $count"
        class='available'
        tooltip="$count repo updates available:\n$updates\n\nLeft-click: pacman repo upgrade\nRight-click: paru repo + AUR upgrade"
    elif (( status == 0 || status == 2 )); then
        text=' 0'
        class='current'
        tooltip='No repo updates available.\n\nLeft-click: pacman repo upgrade\nRight-click: paru repo + AUR upgrade'
    else
        text=' !'
        class='error'
        tooltip="checkupdates failed: ${error_text:-unknown error}"
    fi
fi

python - "$text" "$tooltip" "$class" <<'PY'
import json
import sys
print(json.dumps({"text": sys.argv[1], "tooltip": sys.argv[2], "class": sys.argv[3]}))
PY
