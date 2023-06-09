# variables for software versions
set NODE_VERSION 18.12.1
set JULIA_VERSION 1.8.3

# clear the greeting
set fish_greeting

# update PATH
set -x PATH ~/.node-v$NODE_VERSION/bin $PATH
set -x PATH ~/.julia-$JULIA_VERSION/bin $PATH
set -x PATH ~/.cargo/bin $PATH
set -x PATH ~/.npm-global/bin $PATH
set -x PATH ~/.local/bin $PATH
set -x PATH /opt/neovim/bin $PATH

# set editor to neovim and alias
set -x EDITOR lvim
alias oldvim="vim"
alias vim="lvim"
alias vi="lvim"

# allow node 8GB ram in node.js
set -x NODE_OPTIONS '--max_old_space_size=8192'

# set GOPATH
set -x GOPATH $HOME/.go

# Base16 Shell
if status --is-interactive
  set BASE16_SHELL "$HOME/.config/base16-shell/"
  source "$BASE16_SHELL/profile_helper.fish"
end

# plugins
fundle plugin 'danhper/fish-ssh-agent'
fundle init
