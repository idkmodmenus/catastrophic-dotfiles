#!/usr/bin/env bash

SETTINGS_FILE="$HOME/.config/gtk-3.0/settings.ini"
SETTINGS_DIR="$HOME/.config/gtk-3.0"
SETTINGS_BASENAME=$(basename "$SETTINGS_FILE")

if ! command -v inotifywait &> /dev/null
then
    echo "Error: inotifywait is not installed."
    echo "Please install inotify-tools (e.g., sudo apt install inotify-tools on Debian/Ubuntu)"
    exit 1
fi

echo "Monitoring $SETTINGS_FILE for changes..."
echo "Press Ctrl+C to stop."

apply_theme() {
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo "Error: $SETTINGS_FILE not found. Please ensure the file exists."
        return 1
    fi

    if [ -f $HOME/.cargo/bin/matugen ]; then
        MATUGEN_BIN="$HOME/.cargo/bin/matugen"
    elif [ -f $HOME/.local/bin/matugen ]; then
        MATUGEN_BIN="$HOME/.local/bin/matugen"
    else
        MATUGEN_BIN="matugen"
    fi

    THEME_PREF=$(grep -E '^gtk-application-prefer-dark-theme=' "$SETTINGS_FILE" | awk -F'=' '{print $2}')

    if [ -z "$THEME_PREF" ]; then
        echo "Warning: 'gtk-application-prefer-dark-theme' setting not found in $SETTINGS_FILE. Skipping theme application."
        return 0
    fi

    if [[ "$THEME_PREF" == "1" || "$THEME_PREF" == "true" ]]; then
        echo "Detected dark theme preference (gtk-application-prefer-dark-theme=1/true). Applying dark matugen theme..."
        $MATUGEN_BIN image "$(cat ~/.cache/catastrophic/hyprland-dotfiles/current_wallpaper)" --source-color-index 0 -m "dark"

        qs ipc call theme-manager reload
        echo "Quickshell Theme updated"

        qs -p $HOME/.local/share/catastrophic-dotfiles-settings/quickshell ipc call theme-manager reload
        echo "Catastrophic Dotfiles Settings Theme updated"

        $HOME/.config/hypr/scripts/gtk.sh &

        pgrep -x swaync >/dev/null && swaync-client -rs || true
    elif [[ "$THEME_PREF" == "0" || "$THEME_PREF" == "false" ]]; then
        echo "Detected light theme preference (gtk-application-prefer-dark-theme=0/false). Applying light matugen theme..."
        $MATUGEN_BIN image "$(cat ~/.cache/catastrophic/hyprland-dotfiles/current_wallpaper)" --source-color-index 0 -m "light"

        qs ipc call theme-manager reload
        echo "Quickshell Theme updated"

        $HOME/.config/hypr/scripts/gtk.sh &

        pgrep -x swaync >/dev/null && swaync-client -rs || true
    else
        echo "Warning: Unexpected value for gtk-application-prefer-dark-theme: $THEME_PREF. Expected 0/1/true/false. Skipping theme application."
    fi
}

inotifywait -m -q -e close_write,moved_to "$SETTINGS_DIR" | while read -r dir events filename; do
    if [[ "$filename" == "$SETTINGS_BASENAME" ]]; then
        echo "Change detected in $SETTINGS_FILE. Re-applying theme..."
        apply_theme
    fi
done