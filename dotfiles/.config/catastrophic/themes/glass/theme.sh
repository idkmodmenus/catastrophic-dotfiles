#!/usr/bin/env bash
# Catastrophic Theme Glass

# Set swaync
echo '@import "themes/glass/style.css";' > $HOME/.config/swaync/style.css
# swaync was replaced by the Quickshell notification server; only reload it if it is running
pgrep -x swaync >/dev/null && swaync-client -rs || true

# Set launcher
echo 'rofi' > $HOME/.config/catastrophic/settings/launcher

# Set walker theme
echo 'glass' > $HOME/.config/catastrophic/settings/walker-theme

# Set Window Border
echo -e 'local name = "default.lua"\nload_variant(name,"windows")' > $HOME/.config/hypr/conf/window.lua

# Set rofi
echo '* { border-width: 1px; }' > $HOME/.config/catastrophic/settings/rofi-border.rasi

echo ":: Theme set to Glass"