#!/usr/bin/env bash
#
# Catastrophic OS installer (Arch Linux / CachyOS)
#
#   curl -fsSL https://raw.githubusercontent.com/idkmodmenus/catastrophic-dotfiles/main/install.sh | bash
#
# Options:
#   --yes        Skip the "Continue?" prompts. System-level changes are still asked
#   --dry-run    Show what would be installed, change nothing
#   --verbose    Show package installation output (always logged)
#   --help       Show this help
#
# Environment:
#   CATASTROPHIC_REPO     Git URL to install from (default below)
#   CATASTROPHIC_BRANCH   Branch or tag to install (default: main)

set -euo pipefail

REPO_URL="${CATASTROPHIC_REPO:-https://github.com/idkmodmenus/catastrophic-dotfiles}"
BRANCH="${CATASTROPHIC_BRANCH:-main}"
LIB_DIR="$HOME/.local/share/catastrophic-dotfiles-installer"
BIN_DIR="$HOME/.local/bin"

YES=0; DRY_RUN=0; VERBOSE=0
WORK_DIR=""

bar() {
    local c=$1 t=$2 w=12 u f r i b=""; local part=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
    u=$(( c * w * 8 / t )); f=$(( u / 8 )); r=$(( u % 8 ))
    for (( i = 0; i < f; i++ )); do b+="█"; done
    if (( f < w )); then b+="${part[r]}"; (( r == 0 )) && b+="░"; for (( i = f + 1; i < w; i++ )); do b+="░"; done; fi
    printf '%s %d/%d' "$b" "$c" "$t"
}
stage() { printf '\n\033[1;36m━━ %s\033[0m  %s\n' "$(bar "$1" 5)" "$2"; }
say()  { printf '\033[1;32m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m:: WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m:: ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

PROFILE=""
INSTALL_STARTED=0
cleanup() {
    local rc=$?
    if [ -n "$WORK_DIR" ]; then rm -rf "$WORK_DIR"; fi
    if [ -n "$PROFILE" ]; then rm -f "$PROFILE"; fi
    if [ "$rc" -ne 0 ] && [ "$INSTALL_STARTED" -eq 1 ]; then
        printf '\n\033[1;33m:: The install stopped before it finished.\033[0m\n' >&2
        printf '   It is safe to run the same command again: steps that are done are skipped.\n' >&2
        printf '   If you had a setup before, it was backed up in ~/.mydotfiles/backups/.\n' >&2
        printf '   The log is in ~/.local/state/catastrophic-dotfiles-installer/logs/.\n' >&2
    fi
}
trap cleanup EXIT

# Everything below lives in main() so bash has read the whole script before it runs
# anything. When started through a pipe (curl | bash) the script arrives on stdin,
# and switching stdin to the terminal for prompts would otherwise make bash read
# the rest of the script from the keyboard.
main() {
while [ $# -gt 0 ]; do
    case "$1" in
        --yes|-y)   YES=1 ;;
        --dry-run)  DRY_RUN=1 ;;
        --verbose)  VERBOSE=1 ;;
        --help|-h)  sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "Unknown option: $1 (try --help)" ;;
    esac
    shift
done

# --- 1. Checks ---
stage 1 "Checking your system"
[ "$EUID" -ne 0 ] || die "Run this as your normal user, not root. sudo is requested when needed."
command -v pacman >/dev/null 2>&1 || die "This installer supports Arch Linux and CachyOS (pacman) only."
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*|*" cachyos "*) ;;
    *) die "Unsupported distribution: ${PRETTY_NAME:-unknown}. Arch Linux and CachyOS are supported." ;;
esac
curl -fsI --max-time 15 https://archlinux.org >/dev/null 2>&1 || curl -fsI --max-time 15 https://github.com >/dev/null 2>&1 || die "No internet connection."

# --- 2. Locate the source (a local checkout, or clone the repository) ---
stage 2 "Downloading Catastrophic OS"
# A local checkout is used only when this file is run from disk. Through a pipe there is
# no file, and the current folder must not be mistaken for the source.
SELF_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
fi
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/catastrophic.dotinst" ] && [ -d "$SELF_DIR/setup" ]; then
    # Work on a copy: the installer merges your kept settings into its source, and that must
    # never end up inside a git checkout.
    WORK_DIR="$(mktemp -d -t catastrophic-install-XXXXXX)"
    say "Using the local checkout in $SELF_DIR (copied, so it stays untouched)."
    cp -a "$SELF_DIR" "$WORK_DIR/src"
    SRC="$WORK_DIR/src"
else
    command -v git >/dev/null 2>&1 || { say "git is required. Installing it (sudo)."; sudo pacman -S --needed --noconfirm git; }
    WORK_DIR="$(mktemp -d -t catastrophic-install-XXXXXX)"
    say "Downloading Catastrophic OS ($BRANCH)..."
    say "This is a one-time download of about 50 MB and can take a few minutes on a slow connection."
    git clone --depth=1 --progress --branch "$BRANCH" "$REPO_URL" "$WORK_DIR/src" || die "Could not clone $REPO_URL"
    SRC="$WORK_DIR/src"
fi

# A cut-off download or a wrong branch must stop here, not halfway through the install
for f in catastrophic.dotinst setup/post-arch.sh setup/preflight-arch.sh setup/dependencies/packages-arch setup/dependencies/packages-aur \
         installer/catastrophic-dotfiles-installer installer/lib/utils.sh installer/lib/helpers.sh installer/lib/colors.sh dotfiles/.config/hypr/hyprland.lua; do
    [ -f "$SRC/$f" ] || die "The download is incomplete ($f is missing). Run the command again."
done
jq empty "$SRC/catastrophic.dotinst" 2>/dev/null || die "The download is damaged (catastrophic.dotinst is not valid). Run the command again."

# --- 3. Dry run ---
if [ "$DRY_RUN" -eq 1 ]; then
    say "Dry run. Nothing will be changed. Installing would:"
    echo "  1. Update the system (pacman -Syu, after asking)"
    echo "  2. Install these packages:"
    grep -vE '^\s*(#|$)' "$SRC/setup/dependencies/packages-arch" | sed 's/#.*//' | xargs -n8 echo "       "
    echo "  3. Install these AUR/extra packages with an AUR helper:"
    grep -vE '^\s*(#|$)' "$SRC/setup/dependencies/packages-aur" | sed 's/#.*//' | xargs -n8 echo "       "
    echo "  4. Install the dock, power menu, launcher and window overview"
    echo "  5. Copy the dotfiles to ~/.mydotfiles and symlink them into ~/.config"
    echo "     (existing files are backed up first)"
    echo "  6. Ask before each system change: services, login manager, NVIDIA driver, boot splash"
    exit 0
fi

# --- 4. Confirm, then ask for sudo once ---
stage 3 "Preparing"

# Free disk space: the packages need a few GB, and building AUR packages needs room too
free_kb() { df --output=avail -k "$1" 2>/dev/null | tail -n 1 | tr -d ' '; }
root_free="$(free_kb /)"
if [ -n "$root_free" ] && [ "$root_free" -lt 2097152 ]; then
    die "Not enough free disk space: $(( root_free / 1048576 )) GB free on /, and at least 6 GB are needed."
elif [ -n "$root_free" ] && [ "$root_free" -lt 6291456 ]; then
    warn "Only $(( root_free / 1048576 )) GB free on /. About 6 GB are recommended, so the install may run out of space."
fi
home_free="$(free_kb "$HOME")"
if [ -n "$home_free" ] && [ "$home_free" -lt 1048576 ]; then
    die "Not enough free disk space in your home folder: less than 1 GB free."
fi

# pacman refuses to run while another package manager holds its lock
if [ -e /var/lib/pacman/db.lck ]; then
    if pgrep -x pacman > /dev/null 2>&1 || pgrep -x yay > /dev/null 2>&1 || pgrep -x paru > /dev/null 2>&1; then
        die "Another package manager is running. Wait for it to finish, then run this again."
    fi
    die "pacman is locked (/var/lib/pacman/db.lck) but nothing is using it. If no update is running, remove the lock with: sudo rm /var/lib/pacman/db.lck"
fi
# When started through a pipe, take prompts from the terminal
if [ ! -t 0 ]; then
    # The braces keep 2>/dev/null temporary; on a bare exec it would silence every prompt and error
    { exec < /dev/tty; } 2> /dev/null || die "No terminal available for prompts. Download install.sh and run it directly."
fi

cat <<EOF

  Catastrophic OS  -  Hyprland desktop for ${PRETTY_NAME:-Arch}

  This will install Hyprland and everything the desktop needs, set up the
  dotfiles in ~/.mydotfiles, and back up any config it replaces.
  You are asked before each system-level change.

EOF
if [ "$YES" -ne 1 ]; then
    read -r -p "Continue? [Y/n] " ans
    case "${ans:-Y}" in [Yy]*) ;; *) echo "Cancelled."; exit 0 ;; esac
fi
INSTALL_STARTED=1
say "Administrator access is needed to install packages."
sudo -v || die "sudo authentication failed."

# Arch does not support partial upgrades, and installing into an outdated system
# can fail on packages that have moved on. Offer a full update before installing.
UPDATE=1
if [ "$YES" -ne 1 ]; then
    read -r -p "Update the system first (sudo pacman -Syu)? Recommended [Y/n] " ans
    case "${ans:-Y}" in [Nn]*) UPDATE=0 ;; esac
fi
if [ "$UPDATE" -eq 1 ]; then
    say "Updating the system..."
    sudo pacman -Syu --noconfirm || die "System update failed. Fix that first, then run this installer again."
else
    warn "Skipping the system update. Installs can fail on an outdated system."
fi
missing="$(pacman -T base-devel git curl jq gum || true)"
if [ -n "$missing" ]; then
    say "Installing prerequisites: $(echo $missing)"
    sudo pacman -S --needed --noconfirm $missing || die "Could not install the installer's prerequisites."
else
    say "Prerequisites are already installed."
fi

# --- 5. Install the dotfiles installer and run it ---
stage 4 "Installing Hyprland, apps and dotfiles"
mkdir -p "$LIB_DIR" "$BIN_DIR"
cp "$SRC"/installer/lib/*.sh "$LIB_DIR/"
install -m755 "$SRC/installer/catastrophic-dotfiles-installer" "$BIN_DIR/catastrophic-dotfiles-installer"
case ":$PATH:" in *":$BIN_DIR:"*) ;; *) export PATH="$BIN_DIR:$PATH" ;; esac

# Point the profile at the source we just fetched
PROFILE="$(mktemp -t catastrophic-dotinst-XXXXXX.json)"
jq --arg src "$SRC" '.source = $src' "$SRC/catastrophic.dotinst" > "$PROFILE"

ARGS=(--install "$PROFILE")
[ "$VERBOSE" -eq 1 ] && ARGS+=(--verbose)
CATASTROPHIC_YES="$YES" CATASTROPHIC_SRC="$SRC" catastrophic-dotfiles-installer "${ARGS[@]}"
rm -f "$PROFILE"
stage 5 "Done. Reboot, then choose the Hyprland session at the login screen."
}

main "$@"; exit $?
