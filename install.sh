#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_file="$repo_dir/packages.arch"

usage() {
    cat <<'EOF'
Usage: ./install.sh [--check] [--no-packages]

  (no option)    Install missing Arch packages, then link the configs.
  --check        Report missing packages and Stow conflicts without changes.
  --no-packages  Link the configs without installing packages.
EOF
}

check_only=false
install_packages=true
while (($#)); do
    case "$1" in
        --check) check_only=true ;;
        --no-packages) install_packages=false ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ ! -r /etc/arch-release ]]; then
    echo "This installer currently supports Arch Linux." >&2
    exit 1
fi

mapfile -t packages < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$package_file")
missing=()
for package in "${packages[@]}"; do
    pacman -Qq "$package" >/dev/null 2>&1 || missing+=("$package")
done

if ! command -v stow >/dev/null 2>&1; then
    echo "GNU Stow is required to link the configuration." >&2
    exit 1
fi

mkdir -p "$HOME/.config"
cd "$repo_dir"
if ! stow --target="$HOME/.config" --simulate --restow config; then
    echo "Resolve the Stow conflicts above before installing or linking anything." >&2
    exit 1
fi

if ((${#missing[@]})); then
    printf 'Missing Arch packages: %s\n' "${missing[*]}"
    if $check_only || ! $install_packages; then
        if $check_only; then
            echo "Check complete; install the missing packages and resolve any Stow conflicts." >&2
            exit 1
        fi
    else
        sudo pacman -S --needed "${missing[@]}"
    fi
else
    echo "All listed Arch packages are installed."
fi

if $check_only; then
    echo "Check complete; no files were changed."
    exit 0
fi

mkdir -p "$HOME/.config" "$HOME/.cache/wallpaper-theme" \
    "$HOME/Pictures/Wallpapers" "$HOME/Videos" \
    "$HOME/.local/share/mpd/playlists" "$HOME/.local/state/mpd"

if ! stow --target="$HOME/.config" --restow config; then
    echo >&2
    echo "Stow found existing files that conflict with this repo." >&2
    stow --target="$HOME/.config" --simulate --restow config 2>&1 | sed 's/^/  /' >&2 || true
    echo "Back up or move only the conflicting files, then run ./install.sh again." >&2
    exit 1
fi

printf '\nDotfiles are linked. Next steps:\n'
printf '  1. Put wallpapers in ~/Pictures/Wallpapers\n'
printf '  2. Start or reload Sway: swaymsg reload\n'
printf '  3. Start MPD if you use the music controls: systemctl --user enable --now mpd\n'
if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
    swaymsg reload >/dev/null 2>&1 || true
fi
