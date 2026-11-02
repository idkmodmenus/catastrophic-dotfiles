#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures"
SAVE_FILENAME="screenshot_$(date +%d%m%Y_%H%M%S).jpg"

if [ -f ~/.config/catastrophic/settings/screenshot-folder ]; then
    SAVE_DIR=$(cat ~/.config/catastrophic/settings/screenshot-folder)
fi
if [ -f ~/.config/catastrophic/settings/screenshot-filename ]; then
    SAVE_FILENAME=$(cat ~/.config/catastrophic/settings/screenshot-filename)
fi

eval screenshot_folder="$SAVE_DIR"
eval NAME="$SAVE_FILENAME"

image_format="png"
extension="${NAME##*.}"

case $extension in
    "jpg"|"jpeg")
        image_format="jpeg"
        ;;
    "ppm")
        image_format="ppm"
        ;;
esac

source "$HOME/.config/catastrophic/scripts/catastrophic-notification-handler"
APP_NAME="Screen Capture"
NOTIFICATION_ICON="camera-photo-symbolic"

export GRIMBLAST_EDITOR="$(cat ~/.config/catastrophic/settings/screenshot-editor)"

take_instant_full() {
    grim -t "$image_format" "$NAME" && notify_user \
        --a "${APP_NAME}" \
        --i "${NOTIFICATION_ICON}" \
        --s "Screenshot saved" \
        --m "$screenshot_folder/$NAME" \
        --t 1000

    [[ -f "$HOME/$NAME" && -d "$screenshot_folder" && -w "$screenshot_folder" ]] && mv "$HOME/$NAME" "$screenshot_folder/"
}

take_instant_area() {
    local pid_picker region

    hyprpicker -r -z &
    pid_picker=$!
    trap 'kill "$pid_picker" 2>/dev/null' EXIT
    sleep 0.1

    region=$(slurp -b "#00000080" -c "#888888ff" -w 1) || exit 0
    [[ -z "$region" ]] && exit 0

    kill "$pid_picker" 2>/dev/null
    trap - EXIT

    grim -g "$region" -t "$image_format" "$NAME" && notify_user \
        --a "${APP_NAME}" \
        --i "${NOTIFICATION_ICON}" \
        --s "Screenshot saved" \
        --m "$screenshot_folder/$NAME" \
        --t 1000
    [[ -f "$HOME/$NAME" && -d "$screenshot_folder" && -w "$screenshot_folder" ]] && mv "$HOME/$NAME" "$screenshot_folder/"
}

if [[ "$1" == "--instant" ]]; then
    take_instant_full
    exit 0
elif [[ "$1" == "--instant-area" ]]; then
    take_instant_area
    exit 0
fi

option_1="Immediate"
option_2="Delayed"

option_capture_1="Capture Everything"
option_capture_2="Capture Active Display"
option_capture_3="Capture Selection"

option_time_1="5s"
option_time_2="10s"
option_time_3="20s"
option_time_4="30s"
option_time_5="60s"

list_col='1'
list_row='2'

copy='Copy'
save='Save'
copy_save='Copy & Save'
edit='Edit'

rofi_cmd() {
    $HOME/.config/catastrophic/scripts/catastrophic-launcher dmenu -c ~/.config/rofi/config-screenshot.rasi -l 2 -p "Take screenshot" --rofi-args "-no-show-icons -width 30"
}

run_rofi() {
    echo -e "$option_1\n$option_2" | rofi_cmd
}

timer_cmd() {
    $HOME/.config/catastrophic/scripts/catastrophic-launcher dmenu -c ~/.config/rofi/config-screenshot.rasi -l 5 -p "Choose timer" --rofi-args "-no-show-icons -width 30"
}

timer_exit() {
    echo -e "$option_time_1\n$option_time_2\n$option_time_3\n$option_time_4\n$option_time_5" | timer_cmd
}

timer_run() {
    selected_timer="$(timer_exit)"
    if [[ "$selected_timer" == "$option_time_1" ]]; then
        countdown=5
        ${1}
    elif [[ "$selected_timer" == "$option_time_2" ]]; then
        countdown=10
        ${1}
    elif [[ "$selected_timer" == "$option_time_3" ]]; then
        countdown=20
        ${1}
    elif [[ "$selected_timer" == "$option_time_4" ]]; then
        countdown=30
        ${1}
    elif [[ "$selected_timer" == "$option_time_5" ]]; then
        countdown=60
        ${1}
    else
        exit
    fi
}

type_screenshot_cmd() {
    $HOME/.config/catastrophic/scripts/catastrophic-launcher dmenu -c ~/.config/rofi/config-screenshot.rasi -l 3 -p "Type of screenshot" --rofi-args "-no-show-icons -width 30"
}

type_screenshot_exit() {
    echo -e "$option_capture_1\n$option_capture_2\n$option_capture_3" | type_screenshot_cmd
}

type_screenshot_run() {
    selected_type_screenshot="$(type_screenshot_exit)"
    if [[ "$selected_type_screenshot" == "$option_capture_1" ]]; then
        option_type_screenshot=screen
        ${1}
    elif [[ "$selected_type_screenshot" == "$option_capture_2" ]]; then
        option_type_screenshot=output
        ${1}
    elif [[ "$selected_type_screenshot" == "$option_capture_3" ]]; then
        option_type_screenshot=area
        ${1}
    else
        exit
    fi
}

copy_save_editor_cmd() {
    $HOME/.config/catastrophic/scripts/catastrophic-launcher dmenu -c ~/.config/rofi/config-screenshot.rasi -l 4 -p "How to save" --rofi-args "-no-show-icons -width 30"
}

copy_save_editor_exit() {
    echo -e "$copy\n$save\n$copy_save\n$edit" | copy_save_editor_cmd
}

copy_save_editor_run() {
    selected_chosen="$(copy_save_editor_exit)"
    if [[ "$selected_chosen" == "$copy" ]]; then
        option_chosen=copy
        image_format=png
        ${1}
    elif [[ "$selected_chosen" == "$save" ]]; then
        option_chosen=save
        ${1}
    elif [[ "$selected_chosen" == "$copy_save" ]]; then
        option_chosen=copysave
        image_format=png
        ${1}
    elif [[ "$selected_chosen" == "$edit" ]]; then
        option_chosen=edit
        ${1}
    else
        exit
    fi
}

timer() {
    if [[ $countdown -gt 10 ]]; then
        notify_user \
            --a "${APP_NAME}" \
            --i "${NOTIFICATION_ICON}" \
            --s "Taking screenshot in ${countdown} seconds" \
            --m "" \
            --t 1000
        countdown_less_10=$((countdown - 10))
        sleep $countdown_less_10
        countdown=10
    fi
    while [[ $countdown -ne 0 ]]; do
        notify_user \
            --a "${APP_NAME}" \
            --i "${NOTIFICATION_ICON}" \
            --s "Taking screenshot in ${countdown} seconds" \
            --m "" \
            --t 1000
        countdown=$((countdown - 1))
        sleep 1
    done
}

takescreenshot() {
    sleep 1
    grimblast --notify "$option_chosen" --filetype "$image_format" "$option_type_screenshot" $NAME
    if [ -f $HOME/$NAME ]; then
        if [ -d $screenshot_folder ]; then
            mv $HOME/$NAME $screenshot_folder/
        fi
    fi
}

takescreenshot_timer() {
    sleep 1
    timer
    sleep 1
    grimblast --notify "$option_chosen" --filetype "$image_format" "$option_type_screenshot" $NAME
    if [ -f $HOME/$NAME ]; then
        if [ -d $screenshot_folder ]; then
            mv $HOME/$NAME $screenshot_folder/
        fi
    fi
}

run_cmd() {
    if [[ "$1" == '--opt1' ]]; then
        type_screenshot_run
        copy_save_editor_run "takescreenshot"
    elif [[ "$1" == '--opt2' ]]; then
        timer_run
        type_screenshot_run
        copy_save_editor_run "takescreenshot_timer"
    fi
}

chosen="$(run_rofi)"
case ${chosen} in
    $option_1)
        run_cmd --opt1
        ;;
    $option_2)
        run_cmd --opt2
        ;;
esac
