#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_file="$repo_dir/packages.arch"
aur_package_file="$repo_dir/packages.aur"

usage() {
    cat <<'EOF'
Usage: ./install.sh [--check] [--no-packages]

  (no option)    Install missing packages, configure services, and link configs.
  --check        Report missing packages, service setup, and Stow conflicts.
  --no-packages  Link configs without installing packages or configuring services.
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
for required in pacman; do
    if ! command -v "$required" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$required" >&2
        exit 1
    fi
done

read_packages() {
    sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$1"
}
mapfile -t packages < <(read_packages "$package_file")
mapfile -t aur_packages < <(read_packages "$aur_package_file")

missing=()
missing_aur=()
for package in "${packages[@]}"; do
    pacman -Qq "$package" >/dev/null 2>&1 || missing+=("$package")
done
for package in "${aur_packages[@]}"; do
    pacman -Qq "$package" >/dev/null 2>&1 || missing_aur+=("$package")
done

preflight_stow() {
    links_needed=true
    command -v stow >/dev/null 2>&1 || return 0
    if [[ ! -d "$HOME/.config" ]]; then
        # Keep --check read-only; normal installs create the target directory.
        if $check_only; then return 0; fi
        mkdir -p "$HOME/.config"
    fi
    cd "$repo_dir"
    stow_output="$(stow --target="$HOME/.config" --simulate --verbose=1 config 2>&1)" || {
        printf '%s\n' "$stow_output" >&2
        echo "Resolve the Stow conflicts above, then run ./install.sh again." >&2
        exit 1
    }
    links_needed=false
    if grep -qE '^(LINK|UNLINK|MKDIR|RMDIR):' <<<"$stow_output"; then
        links_needed=true
    fi
    return 0
}

# Preflight Stow before changing packages when it is available. If it is
# missing, install it from packages.arch and preflight afterward.
preflight_stow

service_setup_needed=false
if command -v systemctl >/dev/null 2>&1; then
    systemctl is-enabled --quiet bluetooth.service 2>/dev/null || service_setup_needed=true
    systemctl is-active --quiet bluetooth.service 2>/dev/null || service_setup_needed=true
    systemctl --user is-enabled --quiet mpd.service 2>/dev/null || service_setup_needed=true
    systemctl --user is-active --quiet mpd.service 2>/dev/null || service_setup_needed=true
else
    service_setup_needed=true
fi

if $check_only; then
    if ((${#missing[@]})); then printf 'Missing official packages: %s\n' "${missing[*]}"; fi
    if ((${#missing_aur[@]})); then printf 'Missing AUR packages: %s\n' "${missing_aur[*]}"; fi
    $service_setup_needed && echo "Bluetooth and/or MPD service setup is incomplete."
    $links_needed && echo "Some configuration links still need to be created or refreshed (or Stow is missing)."
    if ((${#missing[@]} + ${#missing_aur[@]})) || $service_setup_needed || $links_needed; then
        echo "Check complete; run ./install.sh to complete setup." >&2
        exit 1
    fi
    echo "Everything is installed, configured, and linked."
    exit 0
fi

if $install_packages; then
    if ((${#missing[@]})); then
        printf 'Installing missing Arch packages: %s\n' "${missing[*]}"
        sudo pacman -S --needed "${missing[@]}"
    fi

    if ((${#missing_aur[@]})); then
        aur_helper=""
        if command -v paru >/dev/null 2>&1; then
            aur_helper=paru
        elif command -v yay >/dev/null 2>&1; then
            aur_helper=yay
        else
            echo "No AUR helper found; installing the prerequisites to build paru."
            sudo pacman -S --needed base-devel git
            build_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-paru.XXXXXX")"
            trap 'rm -rf -- "$build_dir"' EXIT
            git clone https://aur.archlinux.org/paru.git "$build_dir/paru"
            (cd "$build_dir/paru" && makepkg -si)
            rm -rf -- "$build_dir"
            trap - EXIT
            command -v paru >/dev/null 2>&1 || {
                echo "paru did not become available after its build." >&2
                exit 1
            }
            aur_helper=paru
        fi
        printf 'Installing missing AUR packages with %s: %s\n' "$aur_helper" "${missing_aur[*]}"
        "$aur_helper" -S --needed "${missing_aur[@]}"
    fi

    # Verify the package transaction really installed every declared package.
    still_missing=()
    for package in "${packages[@]}" "${aur_packages[@]}"; do
        pacman -Qq "$package" >/dev/null 2>&1 || still_missing+=("$package")
    done
    if ((${#still_missing[@]})); then
        printf 'Installation did not complete; still missing: %s\n' "${still_missing[*]}" >&2
        exit 1
    fi

    # If Stow was installed as part of this run, preflight now before linking.
    preflight_stow

    echo "Enabling Bluetooth and MPD services..."
    sudo systemctl enable --now bluetooth.service
    systemctl --user enable --now mpd.service
fi

if ! command -v stow >/dev/null 2>&1; then
    echo "GNU Stow is still unavailable; cannot link the dotfiles." >&2
    exit 1
fi

mkdir -p "$HOME/.config" "$HOME/.cache/wallpaper-theme" \
    "$HOME/Pictures/Wallpapers" "$HOME/Videos" \
    "$HOME/.local/share/mpd/playlists" "$HOME/.local/state/mpd" \
    "$HOME/.config/btop/themes"

cd "$repo_dir"
stow --target="$HOME/.config" --restow config

if $install_packages; then
    # Mako starts through Sway's autostart. Reloading now applies that change
    # when this installer is run from the configured desktop session.
    if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
        swaymsg reload >/dev/null 2>&1 || true
    fi
fi

if ! $install_packages; then
    echo "Configuration links refreshed. Package and service setup was skipped (--no-packages)."
elif ! $links_needed && ((${#missing[@]} == 0)) && ((${#missing_aur[@]} == 0)) && ! $service_setup_needed; then
    echo "Everything is already installed, configured, and linked."
else
    echo "Setup completed successfully: packages, services, and dotfile links are ready."
fi
printf 'Wallpapers go in ~/Pictures/Wallpapers.\n'
printf 'The Wi-Fi menu uses Impala with iwd; enable iwd.service only if iwd is your Wi-Fi backend.\n'
