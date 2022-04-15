#!/bin/sh

# Terminate already running bar instances
polybar-msg cmd quit

#Launch main bar
polybar --reload main 2>&1 | tee -a /tmp/polybar-main.log & disown
polybar --reload alt 2>&1 | tee -a /tmp/polybar-alt.log & disown
