#!/usr/bin/env bash

_sleep1="0.1"
_sleep2="0.5"
_sleep3="2"
_sleep4="1"

sleep $_sleep4

killall -e xdg-desktop-portal-hyprland
killall -e xdg-desktop-portal-gnome
killall -e xdg-desktop-portal-kde
killall -e xdg-desktop-portal-lxqt
killall -e xdg-desktop-portal-wlr
killall -e xdg-desktop-portal-gtk
killall -e xdg-desktop-portal

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland

systemctl --user stop pipewire
systemctl --user stop wireplumber
systemctl --user stop xdg-desktop-portal
systemctl --user stop xdg-desktop-portal-gnome
systemctl --user stop xdg-desktop-portal-kde
systemctl --user stop xdg-desktop-portal-wlr
systemctl --user stop xdg-desktop-portal-hyprland
sleep $_sleep1

/usr/lib/xdg-desktop-portal-hyprland &
sleep $_sleep3

if [ -f /usr/lib/xdg-desktop-portal-gtk ]; then
    /usr/lib/xdg-desktop-portal-gtk &
    sleep $_sleep1
fi

/usr/lib/xdg-desktop-portal &
sleep $_sleep2

systemctl --user start pipewire
systemctl --user start wireplumber
systemctl --user start xdg-desktop-portal
systemctl --user start xdg-desktop-portal-hyprland

sleep $_sleep3
