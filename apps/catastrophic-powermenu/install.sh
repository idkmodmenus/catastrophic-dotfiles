#!/usr/bin/env bash

set -euo pipefail

REPO_TARBALL="https://github.com/idkmodmenus/catastrophic-dotfiles/archive/refs/heads/main.tar.gz"
APP_NAME="catastrophic-powermenu"
INSTALL_DIR="$HOME/.local/share/catastrophic-powermenu"
BIN_DIR="$HOME/.local/bin"

for tool in curl tar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo ":: ERROR: $tool is required but not installed."
        exit 1
    fi
done

if ! command -v qs >/dev/null 2>&1; then
    echo ":: WARNING: quickshell (qs) is not installed. The power menu needs it to run."
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
echo ":: Downloading catastrophic-powermenu"
curl -fsSL "$REPO_TARBALL" | tar -xz -C "$TMP_DIR" --strip-components=3 "catastrophic-dotfiles-main/apps/$APP_NAME"
if [ ! -f "$TMP_DIR/shell.qml" ]; then
    echo ":: ERROR: download did not contain $APP_NAME."
    exit 1
fi
mkdir -p "$INSTALL_DIR"
cp -a "$TMP_DIR/." "$INSTALL_DIR/"
echo ":: catastrophic-powermenu installed to $INSTALL_DIR"

echo ":: Linking catastrophic-powermenu into $BIN_DIR"
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/bin/catastrophic-powermenu" "$BIN_DIR/catastrophic-powermenu"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo ":: WARNING: $BIN_DIR is not in your \$PATH."
        echo ":: Add it to your shell configuration, e.g. in ~/.bashrc or ~/.zshrc:"
        echo ":: export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

echo ":: Start the power menu with: catastrophic-powermenu"
