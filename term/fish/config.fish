# clear the greeting
set fish_greeting

# update PATH
fish_add_path ~/.cargo/bin
fish_add_path ~/.npm-global/bin
fish_add_path ~/.local/bin
fish_add_path ~/.pixi/bin

# set editor to neovim and alias
set -x EDITOR nvim
alias oldvim="vim"
alias vim="nvim"
alias vi="nvim"

# Base16 Shell
if status --is-interactive
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"
end

# plugins
fundle plugin danhper/fish-ssh-agent
fundle plugin edc/bass
fundle init
