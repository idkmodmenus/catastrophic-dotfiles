#!/usr/bin/env bash
#
# Catastrophic OS installer (Arch Linux / CachyOS)
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/idkmodmenus/catastrophic-dotfiles/main/install.sh)
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

say()  { printf '\033[1;32m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m:: WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m:: ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

cleanup() { if [ -n "$WORK_DIR" ]; then rm -rf "$WORK_DIR"; fi; }
trap cleanup EXIT

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
[ "$EUID" -ne 0 ] || die "Run this as your normal user, not root. sudo is requested when needed."
command -v pacman >/dev/null 2>&1 || die "This installer supports Arch Linux and CachyOS (pacman) only."
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*|*" cachyos "*) ;;
    *) die "Unsupported distribution: ${PRETTY_NAME:-unknown}. Arch Linux and CachyOS are supported." ;;
esac
curl -fsI --max-time 15 https://archlinux.org >/dev/null 2>&1 || die "No internet connection."

# --- 2. Locate the source (a local checkout, or clone the repository) ---
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/catastrophic.dotinst" ] && [ -d "$SELF_DIR/setup" ]; then
    SRC="$SELF_DIR"
else
    command -v git >/dev/null 2>&1 || { say "git is required. Installing it (sudo)."; sudo pacman -S --needed --noconfirm git; }
    WORK_DIR="$(mktemp -d -t catastrophic-install-XXXXXX)"
    say "Downloading Catastrophic OS ($BRANCH)..."
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$WORK_DIR/src" >/dev/null 2>&1 || die "Could not clone $REPO_URL"
    SRC="$WORK_DIR/src"
fi

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
# When started through a pipe, take prompts from the terminal
if [ ! -t 0 ]; then
    exec < /dev/tty 2> /dev/null || die "No terminal available for prompts. Download install.sh and run it directly."
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
sudo pacman -S --needed --noconfirm base-devel git curl jq gum || die "Could not install the installer's prerequisites."

# --- 5. Install the dotfiles installer and run it ---
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
