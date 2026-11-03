#!/usr/bin/env bash

source "$HOME/.config/catastrophic/scripts/catastrophic-notification-handler"
APP_NAME="System"
NOTIFICATION_ICON="joystick"

cache_folder="$HOME/.cache/catastrophic/hyprland-dotfiles"
flag="$HOME/.config/catastrophic/settings/gamemode-enabled"
state="${XDG_RUNTIME_DIR:-/tmp}/catastrophic-gamemode"

units=(
    'app-blueman@*'
    'app-org.kde.kdeconnect.daemon@*'
    'app-arch\x2dupdate\x2dtray@*'
)

on_demand_apps=(
    "$HOME/.local/share/quickshell-overview"
    "$HOME/.local/share/catastrophic-dotfiles-settings/quickshell"
    "$HOME/.local/share/catastrophic-dock"
)

available_mb() {
    awk '/^MemAvailable:/ { printf "%d", $2 / 1024 }' /proc/meminfo
}

launch() {
    hyprctl dispatch "hl.dsp.exec_cmd('$1')" >/dev/null 2>&1
}

cgroup_of() {
    sed -n 's/^0:://p' "/proc/$1/cgroup" 2>/dev/null
}

reclaim_background() {
    local base="/sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service"
    [ -w "$base/app.slice/memory.reclaim" ] || return 0

    local -A keep=()
    local -A audio_comm=()
    local pid comm cg

    local protect=()
    protect+=($(pgrep -x Hyprland) $(pgrep -x Xwayland) $(pgrep -x pipewire) $(pgrep -x pipewire-pulse) $(pgrep -x wireplumber))
    for pid in $(pgrep -x qs); do
        [ "$(tr '\0' ' ' </proc/"$pid"/cmdline 2>/dev/null)" = "qs " ] && protect+=("$pid")
    done
    protect+=($(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null))
    protect+=($(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.fullscreen != 0) | .pid' 2>/dev/null))

    if command -v pactl >/dev/null 2>&1; then
        local kind value
        while IFS=$'\t' read -r kind value; do
            [ -n "$value" ] || continue
            if [ "$kind" = pid ]; then
                protect+=("$value")
                comm=$(cat "/proc/$value/comm" 2>/dev/null) && audio_comm["${comm,,}"]=1
            else
                audio_comm["${value,,}"]=1
            fi
        done < <(pactl -f json list sink-inputs 2>/dev/null | jq -r '.[].properties | (["pid", .["application.process.id"]], ["name", .["application.process.binary"]], ["name", .["application.name"]]) | select(.[1] != null) | map(tostring) | @tsv' 2>/dev/null)
    fi

    for pid in "${protect[@]}"; do
        cg=$(cgroup_of "$pid") && [ -n "$cg" ] && keep["$cg"]=1
    done
    if [ ${#audio_comm[@]} -gt 0 ]; then
        for pid in $(pgrep -u "$(id -u)" .); do
            comm=$(cat "/proc/$pid/comm" 2>/dev/null) || continue
            [ -n "${audio_comm[${comm,,}]:-}" ] && cg=$(cgroup_of "$pid") && keep["$cg"]=1
        done
    fi

    local dir rel current
    while IFS= read -r dir; do
        rel="${dir#/sys/fs/cgroup}"
        [ -n "${keep[$rel]:-}" ] && continue
        read -r _ <"$dir/cgroup.procs" 2>/dev/null || continue
        current=$(cat "$dir/memory.current" 2>/dev/null) || continue
        [ "$current" -ge $((64 * 1024 * 1024)) ] || continue
        timeout 5 sh -c 'echo "$1" > "$2"' _ "$((current * 6 / 10))" "$dir/memory.reclaim" 2>/dev/null
    done < <(find "$base/app.slice" "$base/session.slice" -mindepth 1 \( -name '*.scope' -o -name '*.service' \) -type d 2>/dev/null)
}

is_active() {
    [ -f "$state/active" ]
}

activate() {
    is_active && return 0
    mkdir -p "$state"
    : >"$state/units"
    : >"$state/restore"
    local before
    before=$(available_mb)

    if [ -f "$cache_folder/wallpaper-automation" ]; then
        touch "$cache_folder/restart-wpauto"
        "$HOME/.config/catastrophic/scripts/catastrophic-wallpaper-automation"
    fi

    touch "$state/active" "$flag"
    hyprctl eval "activate_gamemode()" >/dev/null

    local unit
    while IFS= read -r unit; do
        [ -n "$unit" ] || continue
        echo "$unit" >>"$state/units"
        systemctl --user stop "$unit" 2>/dev/null
    done < <(systemctl --user list-units --state=active --plain --no-legend "${units[@]}" 2>/dev/null | awk '{print $1}')

    if pgrep -x nm-applet >/dev/null; then
        echo "nm-applet" >>"$state/restore"
        pkill -x nm-applet
    fi

    if pgrep -x hypridle >/dev/null; then
        echo "hypridle" >>"$state/restore"
        pkill -x hypridle
    fi

    local dir
    for dir in "${on_demand_apps[@]}"; do
        [ -d "$dir" ] && qs kill -p "$dir" >/dev/null 2>&1
    done
    pgrep -x walker >/dev/null && pkill -x walker
    pgrep -x elephant >/dev/null && pkill -x elephant

    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl get >"$state/power-profile" 2>/dev/null
        powerprofilesctl set performance 2>/dev/null
    fi

    sleep 1
    reclaim_background
    local freed=$(($(available_mb) - before))
    [ "$freed" -lt 0 ] && freed=0
    echo "$freed" >"$state/freed"

    notify_user --a "${APP_NAME}" \
        --i "${NOTIFICATION_ICON}" \
        --s "Game mode on" \
        --m "Freed ${freed} MB of RAM. Effects, background apps, notifications and screen timeout are off."

    if [ "$(qs ipc call notifications dnd 2>/dev/null)" = "false" ]; then
        echo "dnd" >>"$state/restore"
        sleep 1
        qs ipc call notifications toggleDnd >/dev/null 2>&1
    fi
}

deactivate() {
    if ! is_active; then
        rm -f "$flag"
        hyprctl reload >/dev/null
        return 0
    fi

    if grep -qx dnd "$state/restore" 2>/dev/null && [ "$(qs ipc call notifications dnd 2>/dev/null)" = "true" ]; then
        qs ipc call notifications toggleDnd >/dev/null 2>&1
    fi

    rm -f "$state/active" "$flag"
    hyprctl reload >/dev/null

    if [ -s "$state/power-profile" ] && command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set "$(cat "$state/power-profile")" 2>/dev/null
    fi

    local unit
    while IFS= read -r unit; do
        [ -n "$unit" ] && systemctl --user start "$unit" 2>/dev/null
    done <"$state/units"

    grep -qx nm-applet "$state/restore" 2>/dev/null && ! pgrep -x nm-applet >/dev/null && launch "nm-applet --indicator"
    grep -qx hypridle "$state/restore" 2>/dev/null && ! pgrep -x hypridle >/dev/null && launch "hypridle"

    if grep -q '"enabled"[[:space:]]*:[[:space:]]*true' "$HOME/.config/catastrophic-dock/config.json" 2>/dev/null; then
        launch "catastrophic-dock start"
    fi

    if [ -f "$cache_folder/restart-wpauto" ]; then
        rm "$cache_folder/restart-wpauto"
        "$HOME/.config/catastrophic/scripts/catastrophic-wallpaper-automation" &
    fi

    rm -rf "${state:?}"

    notify_user --a "${APP_NAME}" \
        --i "${NOTIFICATION_ICON}" \
        --s "Game mode off" \
        --m "Effects, background apps, notifications and screen timeout are back."
}

case "${1:-toggle}" in
    on) activate ;;
    off) deactivate ;;
    status) is_active && echo on || echo off ;;
    toggle) if is_active || [ -f "$flag" ]; then deactivate; else activate; fi ;;
    *) echo "Usage: $(basename "$0") [toggle|on|off|status]" >&2; exit 2 ;;
esac
