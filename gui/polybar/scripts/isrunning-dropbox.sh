#!/bin/sh

case $1 in 
  --toggle)
    if [ "$(pgrep dropbox)" ]; then
      dropbox stop &
    else
      dropbox start &
    fi
    ;;
  *)
    STATUS="$(dropbox status)"
    if [ "$STATUS" = "Up to date" ]; then
      echo "synced"
    elif [ "$STATUS" = "Dropbox isn't running!" ]; then
      echo "off"
    elif [ "$STATUS" = "Syncing paused" ]; then
      echo "paused"
    else
      echo "syncing"
    fi
    ;;
esac
