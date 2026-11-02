#!/bin/bash

for panel in sidebar wallpaper calendar; do
    if [ "$(qs ipc call "$panel" isOpen 2>/dev/null)" = "true" ]; then
        qs ipc call "$panel" close
        exit 0
    fi
done

ACTIVE_TITLE=$(hyprctl activewindow -j | jq -r '.title')

if [ -z "$ACTIVE_TITLE" ] || [ "$ACTIVE_TITLE" == "null" ]; then
    exit 0
fi

case "$ACTIVE_TITLE" in
    "Catastrophic Welcome")
        qs ipc call welcome toggle
        ;;
    "Catastrophic Dotfiles Settings")
        "$HOME/.config/catastrophic/scripts/catastrophic-app" settings toggle
        ;;
    *)
        hyprctl dispatch 'hl.dsp.window.close()'
        ;;
esac