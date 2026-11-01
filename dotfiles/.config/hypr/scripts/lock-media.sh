#!/usr/bin/env bash
# One line for the lock screen: what is playing, or a fallback
t=$(playerctl metadata --format '{{ artist }} - {{ title }}' 2>/dev/null | cut -c1-38)
if [ -n "$t" ] && [ "$t" != " - " ]; then
    echo "󰎆  $t"
else
    echo "󰝚  Nothing playing"
fi
