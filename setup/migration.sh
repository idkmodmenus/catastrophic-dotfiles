#!/usr/bin/env bash
# Sourced after the dotfiles are deployed. Variables: FINAL_TARGET, profile_id
# Rewrites the author's absolute home path in a few config files to the current user's.

AUTHOR_HOME="/home/nyx"
if [ "$HOME" != "$AUTHOR_HOME" ] && [ -d "$FINAL_TARGET" ]; then
    info "Adjusting home paths for $HOME..."
    grep -rIl --exclude-dir=.git "$AUTHOR_HOME" "$FINAL_TARGET" 2> /dev/null \
        | xargs -r -d '\n' sed -i "s|$AUTHOR_HOME|$HOME|g"
fi

# Fit the Hyprland config to this computer: environment variant (NVIDIA-only, virtual machine),
# a neutral monitors.lua if there is none, and, only on a fresh install, the keyboard layout the
# system uses. Hybrid NVIDIA laptops are asked once whether to run the desktop on the integrated
# GPU so the NVIDIA GPU can power down. It writes only ~/.config/hypr/machine.lua (not part of
# the repository, so updates never overwrite it) and never changes monitors.lua or input.lua
# on an update.
hypr_tune="$FINAL_TARGET/.config/catastrophic/scripts/catastrophic-hypr-tune"
if [ -x "$hypr_tune" ] && [ -d "$FINAL_TARGET/.config/hypr" ]; then
    tune_args=(--install)
    [ "${CATASTROPHIC_YES:-0}" = "1" ] || tune_args+=(--ask)
    [ "${FRESH_INSTALL:-0}" = "1" ] && tune_args+=(--keyboard)
    info "Tuning Hyprland for this computer..."
    HYPR_DIR="$FINAL_TARGET/.config/hypr" CATASTROPHIC_SETTINGS="$FINAL_TARGET/.config/catastrophic/settings" \
        "$hypr_tune" "${tune_args[@]}" || warn "Could not tune Hyprland for this computer. Run catastrophic-hypr-tune later."
fi

# Point the default-app settings at the apps found (or installed) by post-arch.sh
DEFAULT_APPS_FILE="$HOME/.cache/catastrophic-default-apps"
if [ -f "$DEFAULT_APPS_FILE" ] && [ -d "$FINAL_TARGET/.config/catastrophic/settings" ]; then
    settings="$FINAL_TARGET/.config/catastrophic/settings"
    while IFS='=' read -r category cmd; do
        [ -n "$cmd" ] || continue
        case "$category" in
            terminal)    printf '%s' "$cmd" > "$settings/terminal.sh" ;;
            browser)     printf '%s' "$cmd" > "$settings/browser.sh" ;;
            filemanager)
                case "$cmd" in
                    nautilus|dolphin|nemo) printf '%s --new-window' "$cmd" > "$settings/filemanager" ;;
                    *)                     printf '%s' "$cmd" > "$settings/filemanager" ;;
                esac ;;
            editor)      printf '#!/bin/bash\n%s "$@"\n' "$cmd" > "$settings/editor.sh" ;;
        esac
    done < "$DEFAULT_APPS_FILE"
    info "Default apps set from what is installed."
fi

# The first releases shipped a fixed theme color (#475569, scheme-vibrant). While that file exists
# the wallpaper script ignores the wallpaper, so the theme never changed when the background did.
# Unless the user picked a color of their own, go back to following the wallpaper.
theme_color_file="$FINAL_TARGET/.config/catastrophic/settings/theme-color"
if [ -f "$theme_color_file" ] && [ "$(tr -s '[:space:]' ' ' < "$theme_color_file" | sed 's/^ //; s/ $//')" = "#475569 scheme-vibrant" ]; then
    rm -f "$theme_color_file"
    info "Theme colors now follow the wallpaper."
fi
