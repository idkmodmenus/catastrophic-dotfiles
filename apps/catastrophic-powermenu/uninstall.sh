#!/usr/bin/env bash
#
# Uninstall the Catastrophic Power Menu
#

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/catastrophic-powermenu"
CONFIG_DIR="$HOME/.config/catastrophic-powermenu"
BIN_LINK="$HOME/.local/bin/catastrophic-powermenu"

if pgrep -f "qs.* -p $INSTALL_DIR" >/dev/null 2>&1; then
    echo ":: Stopping the running power menu"
    pkill -f "qs.* -p $INSTALL_DIR" || true
fi

if [ -L "$BIN_LINK" ]; then
    echo ":: Removing $BIN_LINK"
    rm -f "$BIN_LINK"
fi

if [ -d "$INSTALL_DIR" ]; then
    echo ":: Removing $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    echo ":: Done."
else
    echo ":: Nothing to do: $INSTALL_DIR does not exist."
fi

if [ -d "$CONFIG_DIR" ]; then
    echo ":: Your configuration in $CONFIG_DIR was kept. Remove it manually if you no longer need it."
fi
