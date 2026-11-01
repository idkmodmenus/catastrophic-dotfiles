#!/usr/bin/env bash

# --- Helper to identify the Linux distro ---
get_distro_by_bin() {
    if command -v pacman &> /dev/null; then echo "arch";
    elif command -v dnf &> /dev/null; then echo "fedora";
    elif command -v zypper &> /dev/null; then echo "opensuse";
    elif command -v apt &> /dev/null; then echo "ubuntu";
    else echo "unknown"; fi
}

# --- Logging ---
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/catastrophic-dotfiles-installer/logs"
LOG_KEEP=10

# Create a new logfile for this run and remove all but the newest $LOG_KEEP
init_log() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d_%H%M%S).log"
    {
        echo "Catastrophic Dotfiles Installer $SCRIPT_VERSION"
        echo "Date:      $(date '+%F %T')"
        echo "Distro:    $(get_distro_by_bin)"
        echo "Source:    $INSTALL_URL"
        echo "Test Mode: $TEST_MODE"
        echo
    } > "$LOG_FILE"
    ls -1 "$LOG_DIR"/install-*.log 2> /dev/null | sort -r | tail -n +$((LOG_KEEP + 1)) | xargs -r rm -f
}

# --- Run a command with its output written to the logfile ---
# Usage: run_logged [--title "Spinner text"] command [args...]
# Output is hidden (or shown with --verbose); the exit code is passed through.
run_logged() {
    local title=""
    if [ "$1" = "--title" ]; then title=$2; shift 2; fi
    [ -z "$LOG_FILE" ] && LOG_FILE=/dev/null

    echo "----- $(date '+%F %T') \$ $*" >> "$LOG_FILE"
    local rc
    if [ "$VERBOSE" = true ]; then
        "$@" < /dev/null 2>&1 | tee -a "$LOG_FILE" >&2
        rc=${PIPESTATUS[0]}
    elif [ -n "$title" ] && [ -t 2 ] && command -v gum &> /dev/null; then
        gum spin --spinner dot --title "$title" -- \
            bash -c 'log=$1; shift; "$@" < /dev/null >> "$log" 2>&1' _ "$LOG_FILE" "$@"
        rc=$?
    else
        "$@" < /dev/null >> "$LOG_FILE" 2>&1
        rc=$?
    fi
    echo "----- exit code: $rc" >> "$LOG_FILE"
    return $rc
}

# --- Ask for the sudo password once and keep the session alive ---
# Package installs run with hidden output, so a sudo prompt must not appear
# in the middle of a spinner. The keepalive is stopped in the cleanup trap.
ensure_sudo() {
    [ "$EUID" -eq 0 ] && return 0
    [ -n "$SUDO_KEEPALIVE_PID" ] && return 0
    info "Administrator privileges are required to install packages."
    sudo -v || return 1
    ( while kill -0 "$$" 2> /dev/null; do sudo -n true; sleep 50; done ) 2> /dev/null &
    SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
    [ -n "$SUDO_KEEPALIVE_PID" ] && kill "$SUDO_KEEPALIVE_PID" 2> /dev/null
    SUDO_KEEPALIVE_PID=""
}

# --- Progress bar ---
# progress_bar CURRENT TOTAL [WIDTH]  ->  ████████▌░░░░░░░░ 52%
# Partial blocks give eight steps per cell, so the bar moves on every package.
progress_bar() {
    local cur=$1 total=$2 width=${3:-24} units full rem i bar=""
    local partial=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
    (( total > 0 )) || total=1
    (( cur > total )) && cur=$total
    units=$(( cur * width * 8 / total ))
    full=$(( units / 8 )); rem=$(( units % 8 ))
    for (( i = 0; i < full; i++ )); do bar+="█"; done
    if (( full < width )); then
        bar+="${partial[rem]}"
        (( rem == 0 )) && bar+="░"
        for (( i = full + 1; i < width; i++ )); do bar+="░"; done
    fi
    printf '%s %3d%%' "$bar" $(( cur * 100 / total ))
}

# progress_line CURRENT TOTAL LABEL  - redraws one line in place (plain lines when not a terminal)
progress_line() {
    local cur=$1 total=$2 label=$3 cols=${COLUMNS:-$(tput cols 2> /dev/null || echo 80)}
    label="${label:0:$(( cols > 50 ? cols - 42 : 8 ))}"
    if [ -t 2 ]; then
        printf '\r\033[K  %s  %d/%d  %s' "$(progress_bar "$cur" "$total" 24)" "$cur" "$total" "$label" >&2
    elif (( cur == total || cur % 10 == 0 )); then
        echo "  [$cur/$total] $label" >&2
    fi
}

# progress_done - clear the in-place line
progress_done() { [ -t 2 ] && printf '\r\033[K' >&2; return 0; }

# --- Overall step header: step N TOTAL "Message" ---
step() {
    echo >&2
    printf '\033[1;36m━━ %s\033[0m  %s\n' "$(progress_bar "$1" "$2" 12)" "$3" >&2
    log_msg "[STEP $1/$2] $3"
}

# --- Helper to install a package disto agnostic ---
install_package() {
    local pkg=$1; local distro=$(get_distro_by_bin)
    ensure_sudo || return 1
    case "$distro" in
        arch)
            # QUIET_PKG: the caller draws its own progress line, so no spinner here
            if [ -n "$QUIET_PKG" ]; then
                run_logged sudo pacman -S --needed --noconfirm "$pkg"
            else
                run_logged --title "Installing $pkg..." sudo pacman -S --needed --noconfirm "$pkg"
            fi ;;
        fedora) run_logged --title "Installing $pkg..." sudo dnf install -y "$pkg" ;;
        opensuse) run_logged --title "Installing $pkg..." sudo zypper --non-interactive install "$pkg" ;;
        ubuntu)
            if [ "$APT_UPDATED" != true ]; then
                run_logged --title "Updating package lists..." sudo apt-get update && APT_UPDATED=true
            fi
            run_logged --title "Installing $pkg..." sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg" ;;
        *) error "Unsupported distro."; return 1 ;;
    esac
}

# --- Helper to check command and install if not available ---
check_and_install() {
    local cmd=$1; local pkg=$2
    if command -v "$cmd" &> /dev/null; then return 0; fi

    warn "✗ $cmd is not installed. Installing now..."
    if install_package "$pkg" && command -v "$cmd" &> /dev/null; then
        info "  ✓ $pkg installed."
    else
        error "  ✗ Failed to install $pkg. See $LOG_FILE"
        return 1
    fi
}

# --- Helper to get content from URL or Local File ---
get_json_content() {
    local source=$1
    if [[ "$source" =~ ^https?:// ]]; then
        curl -sL "$source"
    elif [ -f "$source" ]; then
        cat "$source"
    else
        return 1
    fi
}
