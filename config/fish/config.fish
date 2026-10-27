# ~/.config/fish/config.fish — interactive shell setup.

if status is-interactive
    set -g fish_greeting ""

    if type -q starship
        starship init fish | source
    end

    # Aliases
    if type -q eza
        alias ls 'eza --icons=auto --group-directories-first'
        alias ll 'eza -lah --icons=auto --group-directories-first'
    end
    if type -q bat
        alias cat 'bat --paging=never'
    end
    type -q nvim; and alias vim nvim

    # Colours
    set -g fish_color_command      7aa2f7
    set -g fish_color_param        c0caf5
    set -g fish_color_autosuggestion 565f89
end

# yazi wrapper: quit yazi and stay in the directory you navigated to.
function y
    set tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file="$tmp"
    if read -z cwd < "$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
fastfetch
