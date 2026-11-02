#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if command -v walker > /dev/null 2>&1; then
    THEME_OPTIONS=$(find "$SCRIPT_DIR" -maxdepth 1 -mindepth 1 -type d | awk -F/ '{ print $NF }')
else
    THEME_OPTIONS=$(find "$SCRIPT_DIR" -maxdepth 1 -mindepth 1 -type d -not -name "*walker*" | awk -F/ '{ print $NF }')
fi

selected_theme=$($HOME/.config/catastrophic/scripts/catastrophic-launcher dmenu -p "Search Theme" -l 5 --rofi-args "-no-show-icons -width 30" <<<"$THEME_OPTIONS")

source $HOME/.config/catastrophic/themes/$selected_theme/theme.sh