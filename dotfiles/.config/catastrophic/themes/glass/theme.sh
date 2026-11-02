#!/usr/bin/env bash

echo '@import "themes/glass/style.css";' > $HOME/.config/swaync/style.css
pgrep -x swaync >/dev/null && swaync-client -rs || true

echo 'rofi' > $HOME/.config/catastrophic/settings/launcher

echo 'glass' > $HOME/.config/catastrophic/settings/walker-theme

echo -e 'local name = "default.lua"\nload_variant(name,"windows")' > $HOME/.config/hypr/conf/window.lua

echo '* { border-width: 1px; }' > $HOME/.config/catastrophic/settings/rofi-border.rasi

echo ":: Theme set to Glass"