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
    # load the base16 theme helper
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"

    # grab the theme from file in home directory if it exists
    if test -f ~/.theme
        source ~/.theme
    end
    if test -z $BASE16_THEME
        base16-tomorrow-night-eighties
    end
end

# plugins
fundle plugin danhper/fish-ssh-agent
fundle plugin edc/bass
fundle init

# pnpm
set -gx PNPM_HOME "/home/mvarble/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# refresh tmux theme if it does not agree
# TODO: find more efficient way of doing this... maybe look into tinted again
set TMUX_THEME (tmux show-option -g @tinted-color | cut -d ' ' -f2 )
if [ $TMUX_THEME != base16-$BASE16_THEME ]
    tmux set -g @tinted-color base16-$BASE16_THEME
    tmux run '~/.tmux/plugins/tpm/tpm'
    tmux set -g mode-style 'bg=blue,fg=black'
    tmux set -g pane-active-border-style 'fg=blue'
end
