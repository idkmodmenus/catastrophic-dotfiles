#!/usr/bin/env bash
# Sourced by catastrophic-dotfiles-installer after the packages are installed.
# Variables from the installer: repo_path, profile_id, LOG_FILE, AUR_HELPER
# Every system-level change below asks first. --yes does not skip these.

ensure_sudo || return 1
APPS_SRC="$repo_path/apps"
BRAND_SRC="$repo_path/branding"
SHARE_DIR="$HOME/.local/share"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$SHARE_DIR" "$BIN_DIR"
POST_NOTES=()

# --- 1. AUR packages ---
step 1 7 "AUR packages"
if [ -n "$AUR_HELPER" ] && [ -f "$repo_path/setup/dependencies/packages-aur" ]; then
    mapfile -t aur_pkgs < <(sed 's/#.*//' "$repo_path/setup/dependencies/packages-aur" | xargs -n1)
    aur_total=0; for pkg in "${aur_pkgs[@]}"; do [ -n "$pkg" ] && aur_total=$((aur_total + 1)); done
    aur_done=0; aur_added=0; aur_present=0; aur_failed=0
    for pkg in "${aur_pkgs[@]}"; do
        [ -z "$pkg" ] && continue
        aur_done=$((aur_done + 1))
        if pacman -Qi "$pkg" &> /dev/null; then
            aur_present=$((aur_present + 1))
            progress_line "$aur_done" "$aur_total" "$pkg (already installed)"
        else
            progress_line "$aur_done" "$aur_total" "building $pkg"
            if run_logged "$AUR_HELPER" -S --needed --noconfirm "$pkg"; then
                aur_added=$((aur_added + 1))
            else
                aur_failed=$((aur_failed + 1))
                progress_done
                error "  ✗ Failed to install $pkg. See $LOG_FILE"
                POST_NOTES+=("AUR package not installed: $pkg")
            fi
        fi
    done
    progress_done
    info "  ✓ $aur_total AUR packages: $aur_added installed, $aur_present already present, $aur_failed failed"
fi

# --- 2. pywalfox (Firefox colour theme bridge) ---
step 2 7 "Firefox theme bridge"
if command -v pipx &> /dev/null && ! command -v pywalfox &> /dev/null; then
    run_logged --title "Installing pywalfox..." pipx install pywalfox \
        || POST_NOTES+=("pywalfox was not installed (pipx install pywalfox)")
fi

# --- 3. Companion apps: dock, power menu, quickshell overview, walker + elephant ---
step 3 7 "Desktop apps (dock, power menu, launcher)"
install_app() {
    local name=$1 dest="$SHARE_DIR/$1"
    [ -d "$APPS_SRC/$name" ] || { warn "App source missing: $name"; return 1; }
    mkdir -p "$dest"
    rsync -a "$APPS_SRC/$name/" "$dest/"
}

for app in catastrophic-dock catastrophic-powermenu; do
    if install_app "$app"; then
        ln -sf "$SHARE_DIR/$app/bin/$app" "$BIN_DIR/$app"
        info "  ✓ $app installed."
    fi
done

if install_app quickshell-overview; then
    info "  ✓ quickshell-overview installed."
fi

# Settings app: the shared files plus its launcher script
if install_app catastrophic-dotfiles-settings; then
    install -m755 "$APPS_SRC/catastrophic-dotfiles-settings-launcher" "$BIN_DIR/catastrophic-dotfiles-settings"
    info "  ✓ catastrophic-dotfiles-settings installed."
fi

# walker downloads the upstream walker and elephant binaries; it has its own installer
if install_app catastrophic-walker; then
    # walker's installer only accepts an install folder that is a git repository
    [ -d "$SHARE_DIR/catastrophic-walker/.git" ] || git -C "$SHARE_DIR/catastrophic-walker" init -q
    if run_logged --title "Installing walker and elephant..." \
        env CATASTROPHIC_WALKER_MANAGED=1 bash "$SHARE_DIR/catastrophic-walker/install.sh" --no-deps; then
        info "  ✓ walker and elephant installed."
    else
        error "  ✗ walker/elephant install failed. See $LOG_FILE"
        POST_NOTES+=("walker/elephant failed: run bash ~/.local/share/catastrophic-walker/install.sh --no-deps")
    fi
fi

# --- 4. User directories ---
xdg-user-dirs-update 2> /dev/null || true

# --- 5. System services ---
step 4 7 "System services"
if gum confirm "Enable NetworkManager, Bluetooth and power-profiles services (sudo)?"; then
    for svc in NetworkManager bluetooth power-profiles-daemon; do
        if systemctl list-unit-files "$svc.service" &> /dev/null; then
            sudo systemctl enable "$svc.service" &>> "$LOG_FILE" && info "  ✓ $svc enabled." \
                || warn "  Could not enable $svc."
        fi
    done
fi

# --- 6. NVIDIA driver ---
step 5 7 "Graphics driver"
if lspci 2> /dev/null | grep -iE 'vga|3d' | grep -qi nvidia; then
    warn "An NVIDIA GPU was detected."
    if command -v chwd &> /dev/null; then
        if gum confirm "Install the matching NVIDIA driver with CachyOS chwd (sudo chwd -a)?"; then
            run_logged --title "Installing GPU drivers..." sudo chwd -a \
                && info "  ✓ GPU drivers installed." \
                || POST_NOTES+=("GPU driver install failed: run sudo chwd -a")
        fi
    else
        # DKMS needs the headers of the kernel that is running (linux, linux-lts, linux-zen, ...)
        kbase="$(cat "/usr/lib/modules/$(uname -r)/pkgbase" 2> /dev/null || echo linux)"
        if gum confirm "Install nvidia-open-dkms, ${kbase}-headers, nvidia-utils and egl-wayland (sudo)?"; then
            run_logged --title "Installing NVIDIA driver..." \
                sudo pacman -S --needed --noconfirm "${kbase}-headers" nvidia-open-dkms nvidia-utils nvidia-settings egl-wayland \
                && info "  ✓ NVIDIA driver installed." \
                || POST_NOTES+=("NVIDIA driver install failed. See $LOG_FILE")
            POST_NOTES+=("NVIDIA: add nvidia_drm.modeset=1 to your kernel parameters if Hyprland does not start")
        fi
    fi
fi

# --- 7. Login manager (SDDM) ---
step 6 7 "Login manager"
if ! systemctl is-enabled --quiet sddm 2> /dev/null; then
    if gum confirm "Use SDDM as your login manager (disables the current one, sudo)?"; then
        # --force replaces whichever display manager is currently enabled
        sudo systemctl enable --force sddm.service &>> "$LOG_FILE" && info "  ✓ SDDM enabled." \
            || POST_NOTES+=("Could not enable SDDM")
    fi
fi

# --- 8. Branding: system icon and boot splash ---
step 7 7 "Branding"
if [ -d "$BRAND_SRC" ] && gum confirm "Install the Catastrophic OS icon and boot splash (sudo)?"; then
    sudo install -Dm644 "$BRAND_SRC/mark.svg" /usr/share/icons/hicolor/scalable/apps/catastrophic.svg
    sudo install -Dm644 "$BRAND_SRC/mark.png" /usr/share/pixmaps/catastrophic.png
    sudo gtk-update-icon-cache -q /usr/share/icons/hicolor 2> /dev/null || true

    # The boot splash needs the plymouth hook in mkinitcpio; skip it otherwise
    if grep -rqs 'plymouth' /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d 2> /dev/null; then
        sudo install -d /usr/share/plymouth/themes/catastrophic
        sudo install -m644 "$BRAND_SRC"/plymouth/catastrophic/* /usr/share/plymouth/themes/catastrophic/
        if gum confirm "Rebuild the initramfs to apply the boot splash? (takes a minute)"; then
            run_logged --title "Applying boot splash..." sudo plymouth-set-default-theme -R catastrophic \
                && info "  ✓ Boot splash installed." \
                || POST_NOTES+=("Boot splash failed. See $LOG_FILE")
        fi
    else
        warn "The plymouth hook is not enabled in mkinitcpio. Skipping the boot splash."
        POST_NOTES+=("Boot splash skipped: add 'plymouth' to HOOKS in /etc/mkinitcpio.conf and add 'splash' to your kernel parameters to enable it")
    fi
fi

# --- Summary ---
if [ ${#POST_NOTES[@]} -gt 0 ]; then
    echo
    warn "Things that need your attention:"
    for n in "${POST_NOTES[@]}"; do warn "  - $n"; done
fi
