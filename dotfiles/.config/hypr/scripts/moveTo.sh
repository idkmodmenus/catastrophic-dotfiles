#!/usr/bin/env bash

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

target_workspace=$1

if [ -z "$target_workspace" ]; then
    log_message "Error: No target workspace provided"
    exit 1
fi

current_workspace=$(hyprctl activewindow -j | jq '.workspace.id')

if [ -z "$current_workspace" ]; then
    log_message "Error: Couldn't determine current workspace"
    exit 1
fi

log_message "Moving from workspace $current_workspace to $target_workspace"

window_addresses=$(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $current_workspace) | .address")

for address in $window_addresses; do
    log_message "Moving window $address to workspace $target_workspace"
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$target_workspace\", silent = true, window = \"address:$address\" })"
done

log_message "Finished moving windows"

hyprctl dispatch "hl.dsp.focus({ workspace = \"$target_workspace\" })"

log_message "Switched to workspace $target_workspace"
