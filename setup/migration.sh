#!/usr/bin/env bash
# Sourced after the dotfiles are deployed. Variables: FINAL_TARGET, profile_id
# Rewrites the author's absolute home path in a few config files to the current user's.

AUTHOR_HOME="/home/nyx"
if [ "$HOME" != "$AUTHOR_HOME" ] && [ -d "$FINAL_TARGET" ]; then
    info "Adjusting home paths for $HOME..."
    grep -rIl --exclude-dir=.git "$AUTHOR_HOME" "$FINAL_TARGET" 2> /dev/null \
        | xargs -r sed -i "s|$AUTHOR_HOME|$HOME|g"
fi
