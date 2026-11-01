#!/usr/bin/env bash
# Catastrophic Theme Modern

# Set swaync
echo '@import "themes/modern/style.css";' > $HOME/.config/swaync/style.css
# swaync was replaced by the Quickshell notification server; only reload it if it is running
pgrep -x swaync >/dev/null && swaync-client -rs || true

# Set launcher
echo 'walker' > $HOME/.config/catastrophic/settings/launcher

# Set walker theme
echo 'modern' > $HOME/.config/catastrophic/settings/walker-theme

# Set Window Border
echo -e 'local name = "border-2.lua"\nload_variant(name,"windows")' > $HOME/.config/hypr/conf/window.lua

# Set rofi
echo '* { border-width: 2px; }' > $HOME/.config/catastrophic/settings/rofi-border.rasi

echo ":: Theme set to Modern"