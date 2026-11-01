#!/usr/bin/env bash
#
# Install or update the Catastrophic Dock
#

set -euo pipefail

REPO_URL="https://github.com/catastrophic-os/catastrophic-dock"
INSTALL_DIR="$HOME/.local/share/catastrophic-dock"
BIN_DIR="$HOME/.local/bin"

if ! command -v git >/dev/null 2>&1; then
    echo ":: ERROR: git is required but not installed."
    exit 1
fi

if ! command -v qs >/dev/null 2>&1; then
    echo ":: WARNING: quickshell (qs) is not installed. The dock needs it to run."
fi

if [ -d "$INSTALL_DIR/.git" ]; then
    echo ":: Updating catastrophic-dock in $INSTALL_DIR"
    git -C "$INSTALL_DIR" pull --ff-only
    echo ":: catastrophic-dock updated successfully."
elif [ -d "$INSTALL_DIR" ]; then
    echo ":: ERROR: $INSTALL_DIR exists but is not a git repository."
    echo ":: Please remove or rename it and run this script again."
    exit 1
else
    echo ":: Cloning catastrophic-dock into $INSTALL_DIR"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO_URL" "$INSTALL_DIR"
    echo ":: catastrophic-dock installed successfully."
fi

echo ":: Linking catastrophic-dock into $BIN_DIR"
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/bin/catastrophic-dock" "$BIN_DIR/catastrophic-dock"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo ":: WARNING: $BIN_DIR is not in your \$PATH."
        echo ":: Add it to your shell configuration, e.g. in ~/.bashrc or ~/.zshrc:"
        echo ":: export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

echo ":: Start the dock with: catastrophic-dock"
