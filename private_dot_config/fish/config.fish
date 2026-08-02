# clear the greeting
set fish_greeting

# update PATH
fish_add_path /home/mvarble/.cargo/bin
fish_add_path /home/mvarble/.local/bin
fish_add_path /home/mvarble/.local/share/fnm
fish_add_path /home/mvarble/.pixi/bin
fish_add_path /home/mvarble/.local/share/commands

# set editor to neovim and alias
set -x EDITOR nvim
alias oldvim=/bin/vi
alias vim=nvim
alias vi=nvim

# plugins
fundle plugin danhper/fish-ssh-agent
fundle plugin edc/bass
fundle plugin catppuccin/fish
fundle init

# theme
fish_config theme choose catppuccin-mocha --color-theme light
set -g fish_color_valid_path $fish_color_valid_path --underline

# pnpm
set -gx PNPM_HOME "/home/mvarble/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
