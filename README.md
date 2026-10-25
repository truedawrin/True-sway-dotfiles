# my-dotfiles

Stow-based dotfiles. `config/` mirrors `~/.config/`.

## Install on a new machine

```sh
sudo pacman -S stow
git clone <this-repo> ~/dotfiles
cd ~/dotfiles && ./install.sh
```

## Daily use

- Edit files **in the repo** (`~/dotfiles/config/...`); `~/.config/...` points here.
- Add a new app: `mkdir -p config/<app>`, add files, `./install.sh`.
- Commit: `git add -A && git commit -m "waybar: add battery warning"`.

## What is here

| Path | Purpose |
|---|---|
| `config/sway/` | compositor, split into `config.d/*.conf` modules |
| `config/waybar/` | status bar |
| `config/kitty/` | terminal |
| `config/rofi/` | launcher |
| `config/fish/` | shell |
| `config/starship.toml` | prompt |
