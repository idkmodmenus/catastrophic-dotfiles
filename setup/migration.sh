#!/usr/bin/env bash
# Sourced after the dotfiles are deployed. Variables: FINAL_TARGET, profile_id
# Rewrites the author's absolute home path in a few config files to the current user's.

AUTHOR_HOME="/home/nyx"
if [ "$HOME" != "$AUTHOR_HOME" ] && [ -d "$FINAL_TARGET" ]; then
    info "Adjusting home paths for $HOME..."
    grep -rIl --exclude-dir=.git "$AUTHOR_HOME" "$FINAL_TARGET" 2> /dev/null \
        | xargs -r -d '\n' sed -i "s|$AUTHOR_HOME|$HOME|g"
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
