#!/usr/bin/env bash

if [ -f ~/.cache/gamemode ]; then
    rm ~/.cache/gamemode
    echo ":: ~/.cache/gamemode removed"
fi

if [ -f ~/.config/catastrophic/settings/gamemode-enabled ] && [ ! -f "${XDG_RUNTIME_DIR:-/tmp}/catastrophic-gamemode/active" ]; then
    rm ~/.config/catastrophic/settings/gamemode-enabled
    echo ":: stale gamemode flag removed"
fi
