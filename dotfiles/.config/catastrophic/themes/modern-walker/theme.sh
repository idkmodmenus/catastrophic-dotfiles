#!/usr/bin/env bash

echo '@import "themes/modern/style.css";' > $HOME/.config/swaync/style.css
pgrep -x swaync >/dev/null && swaync-client -rs || true

echo 'walker' > $HOME/.config/catastrophic/settings/launcher

echo 'modern' > $HOME/.config/catastrophic/settings/walker-theme

echo -e 'local name = "border-2.lua"\nload_variant(name,"windows")' > $HOME/.config/hypr/conf/window.lua

echo '* { border-width: 2px; }' > $HOME/.config/catastrophic/settings/rofi-border.rasi

echo ":: Theme set to Modern"