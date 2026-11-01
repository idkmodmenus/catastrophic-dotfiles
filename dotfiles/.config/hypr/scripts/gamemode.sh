#!/usr/bin/env bash
#                                      __   
#   ___ ____ ___ _  ___ __ _  ___  ___/ /__ 
#  / _ `/ _ `/  ' \/ -_)  ' \/ _ \/ _  / -_)
#  \_, /\_,_/_/_/_/\__/_/_/_/\___/\_,_/\__/ 
# /___/                                     
# 


catastrophic_cache_folder="$HOME/.cache/catastrophic/hyprland-dotfiles"

# Notifications
source "$HOME/.config/catastrophic/scripts/catastrophic-notification-handler"
APP_NAME="System"
NOTIFICATION_ICON="joystick"

if [ -f $HOME/.config/catastrophic/settings/gamemode-enabled ]; then
  if [ -f $catastrophic_cache_folder/restart-wpauto ]; then
    rm $catastrophic_cache_folder/restart-wpauto
    $HOME/.config/catastrophic/scripts/catastrophic-wallpaper-automation &
  fi
  hyprctl reload
  rm $HOME/.config/catastrophic/settings/gamemode-enabled
  notify_user --a "${APP_NAME}" \
            --i "${NOTIFICATION_ICON}" \
            --s "Gamemode deactivated" \
            --m "Animations and blur are now enabled."
else
  if [ -f $catastrophic_cache_folder/wallpaper-automation ]; then
    touch $catastrophic_cache_folder/restart-wpauto
    $HOME/.config/catastrophic/scripts/catastrophic-wallpaper-automation
  fi
  hyprctl eval "activate_gamemode()"
  touch $HOME/.config/catastrophic/settings/gamemode-enabled
  notify_user --a "${APP_NAME}" \
          --i "${NOTIFICATION_ICON}" \
          --s "Gamemode activated" \
          --m "Animations and blur are now disabled."
fi