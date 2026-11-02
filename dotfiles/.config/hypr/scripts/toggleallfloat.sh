#!/usr/bin/env bash

hyprctl dispatch workspaceopt allfloat

source "$HOME/.config/catastrophic/scripts/catastrophic-notification-handler"

notify_user \
        --a "System" \
        --m "Windows on this workspace toggled to floating/tiling"
