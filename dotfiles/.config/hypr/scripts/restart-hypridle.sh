#!/usr/bin/env bash

source "$HOME/.config/catastrophic/scripts/catastrophic-notification-handler"

killall hypridle
sleep 1
hypridle &

notify_user --a "Hypridle" \
        --s "Hypridle has been restarted." \
        --m ""
