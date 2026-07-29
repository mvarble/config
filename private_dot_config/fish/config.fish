# clear the greeting
set fish_greeting

# update PATH
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
fish_add_path ~/.local/share/fnm
fish_add_path ~/.pixi/bin
fish_add_path ~/.local/share/commands

# set editor to neovim and alias
set -x EDITOR nvim
alias oldvim=/bin/vi
alias vim=nvim
alias vi=nvim

# plugins
fundle plugin danhper/fish-ssh-agent
fundle plugin edc/bass
fundle init

# pnpm
set -gx PNPM_HOME "~/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# tinty
if command -v tinty >/dev/null
    tinty init
end

# bat
set -x BAT_THEME base16-256

# hi
