# True’s Sway setup

My Arch Linux desktop setup, built around Sway, Waybar, Rofi and Wallust. The configs live in this repository and GNU Stow links them into `~/.config`, so edits made here are the ones your apps use.



https://github.com/user-attachments/assets/d07f4f83-e2e4-425c-b4f8-2c2f4ec3ddd1



## Install

Start with Git and Stow, then clone the repo and run the installer:

```sh
sudo pacman -S --needed git stow
git clone https://github.com/truedawrin/True-sway-dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer checks for conflicts, installs any missing packages listed in `packages.arch`, and links `config/` into `~/.config`. It is safe to run again after pulling changes. Existing files that conflict with a Stow link are left alone; the installer prints the paths to move or back up before retrying.

To preview package gaps and link conflicts without changing anything, run `./install.sh --check`. To only refresh the links, use `./install.sh --no-packages`.

## First login

Put your images in `~/Pictures/Wallpapers`, then start a Sway session. The wallpaper helper picks up the last wallpaper and Wallust generates matching colors for Waybar, Rofi, Kitty, Sway, Swaylock, Mako and btop. The wallpaper menu is on **Mod+Shift+W**.

The clipboard history is saved by `cliphist` while Sway is running. Copy text or an image, then press **Mod+V** to search the history. The installer reloads Sway when it is run inside a Sway session; otherwise, run `swaymsg reload` once after installing to start the clipboard watchers.

If you use MPD, enable its user service:

```sh
systemctl --user enable --now mpd
```

## Key controls

| Keys | Action |
|---|---|
| Mod+Return | Open Kitty |
| Mod+D | Open the app launcher |
| Mod+V | Search clipboard history |
| Mod+Shift+W | Choose a wallpaper and update colors |
| Mod+Shift+A | Select a region and start or stop a screen recording |
| Mod+Shift+E | Open the power menu |
| F10 | Lock the screen |

Recordings are saved in `~/Videos`. Escape cancels the region selection. The recording helper captures system audio and the active microphone when available. The Waybar camera icon uses the same start/stop action.

## Make it yours

- Edit files under `config/`; they are the live files after installation.
- Change Sway bindings in `config/sway/config.d/30-keybinds.conf`.
- Arrange the bar in `config/waybar/config.jsonc` and `modules.jsonc`; style it in `style.css`.
- Adjust app packages in `packages.arch` before installing on another Arch machine.
- Add another app by creating `config/<app-name>/` and running `./install.sh`.
- Keep machine-specific files, passwords and generated themes out of Git. Wallust creates its runtime colors when Sway starts or a wallpaper is changed.

After editing Sway settings, reload them with `swaymsg reload`. To save changes in Git:

```sh
git add -A
git commit -m "describe the change"
git push
```
