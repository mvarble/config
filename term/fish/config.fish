# variables for software versions
set NODE_VERSION 16.14.0
set JULIA_VERSION 1.7.2
set BLENDER_VERSION 3.0.1

# clear the greeting
set fish_greeting

# update PATH
set PATH ~/.node-v$NODE_VERSION/bin $PATH
set PATH ~/.julia-$JULIA_VERSION/bin $PATH
set PATH ~/.blender-$BLENDER_VERSION $PATH
set PATH ~/.nvim/bin $PATH
set PATH ~/.cargo/bin $PATH
set PATH ~/.npm-global/bin $PATH
set PATH ~/.local/bin $PATH

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

# set DISPLAY
set -x LIBGL_ALWAYS_INDIRECT 1
set -x DISPLAY localhost:10.0
