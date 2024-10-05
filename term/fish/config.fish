# clear the greeting
set fish_greeting

# update PATH
fish_add_path ~/.cargo/bin
fish_add_path ~/.npm/bin
fish_add_path ~/.local/bin
fish_add_path ~/.pixi/bin
fish_add_path ~/.local/share/commands

# set editor to neovim and alias
set -x EDITOR nvim
alias oldvim=/bin/vi
alias vim=nvim
alias vi=nvim

# Base16 Shell
if status --is-interactive
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"
end

# set python to a virtual environment so that I can install packages
source ~/.env/bin/activate.fish

# plugins
fundle plugin danhper/fish-ssh-agent
fundle plugin edc/bass
fundle init
