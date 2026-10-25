#!/usr/bin/env bash
# Sourced by catastrophic-dotfiles-installer before packages are installed.
# Provides: info, warn, error, run_logged, ensure_sudo, gum

ensure_sudo || return 1

# --- PulseAudio -> PipeWire ---
# pipewire-pulse conflicts with pulseaudio. With --noconfirm pacman would refuse
# the swap and the install of the audio stack would fail.
if pacman -Qq pulseaudio &> /dev/null && ! pacman -Qq pipewire-pulse &> /dev/null; then
    if gum confirm "PulseAudio is installed. Replace it with PipeWire (needed by the desktop)?"; then
        run_logged --title "Switching to PipeWire..." sudo pacman -S --needed --noconfirm --ask 4 pipewire pipewire-pulse wireplumber \
            && info "PipeWire installed." \
            || warn "Could not switch to PipeWire. Audio controls may not work. See $LOG_FILE"
    else
        warn "Keeping PulseAudio. Volume controls in the shell expect PipeWire and may not work."
    fi
fi

# --- AUR helper ---
if command -v yay &> /dev/null; then
    AUR_HELPER=yay
elif command -v paru &> /dev/null; then
    AUR_HELPER=paru
else
    info "No AUR helper found. Building yay-bin from the AUR..."
    build_dir="$(mktemp -d -t yay-bin-XXXXXX)"
    if run_logged --title "Building yay..." bash -c "git clone --depth=1 https://aur.archlinux.org/yay-bin.git '$build_dir' && cd '$build_dir' && makepkg -si --noconfirm"; then
        AUR_HELPER=yay
        info "yay installed."
    else
        AUR_HELPER=""
        error "Could not install yay. AUR packages will be skipped. See $LOG_FILE"
    fi
    rm -rf "$build_dir"
fi
export AUR_HELPER
