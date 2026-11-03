#!/usr/bin/env bash

ensure_sudo || return 1
APPS_SRC="$repo_path/apps"
BRAND_SRC="$repo_path/branding"
SHARE_DIR="$HOME/.local/share"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$SHARE_DIR" "$BIN_DIR"
POST_NOTES=()

DEFAULT_APPS_FILE="$HOME/.cache/catastrophic-default-apps"
DEFAULT_APPS_STAMP="$HOME/.cache/catastrophic-applied/default-apps"
mkdir -p "$(dirname "$DEFAULT_APPS_FILE")" "$(dirname "$DEFAULT_APPS_STAMP")"
pick_default_app() {
    local category="$1" candidates="$2" fallback_pkg="$3" fallback_cmd="$4" cmd="" c
    for c in $candidates; do
        if command -v "$c" &> /dev/null; then cmd="$c"; break; fi
    done
    if [ -z "$cmd" ]; then
        info "No $category found, installing $fallback_pkg..."
        if run_logged --title "Installing $fallback_pkg..." sudo pacman -S --needed --noconfirm "$fallback_pkg"; then
            cmd="${fallback_cmd:-$fallback_pkg}"
        else
            POST_NOTES+=("No $category installed: $fallback_pkg failed to install")
            return 0
        fi
    else
        info "  ✓ $category: using $cmd (already installed)"
    fi
    echo "$category=$cmd" >> "$DEFAULT_APPS_FILE"
}
if [ -e "$DEFAULT_APPS_STAMP" ]; then
    info "  - Default apps were chosen on the first install. Keeping them."
    rm -f "$DEFAULT_APPS_FILE"
else
    : > "$DEFAULT_APPS_FILE"
    pick_default_app terminal     "kitty konsole alacritty foot wezterm gnome-terminal xfce4-terminal xterm" kitty kitty
    pick_default_app browser      "firefox librewolf zen-browser brave chromium google-chrome-stable vivaldi-stable qutebrowser" firefox firefox
    pick_default_app filemanager  "nautilus dolphin thunar nemo pcmanfm" nautilus nautilus
    pick_default_app editor       "gnome-text-editor kate kwrite gedit mousepad" gnome-text-editor gnome-text-editor
    echo "done" > "$DEFAULT_APPS_STAMP"
fi

for app in catastrophic-dock catastrophic-statusbar; do
    cfg="$HOME/.config/$app/config.json"
    shipped="$repo_path/setup/defaults/$app/config.json"
    [ -f "$shipped" ] || continue
    stamp="$HOME/.cache/catastrophic-applied/$app"
    sum="$(sha256sum "$shipped" | cut -d' ' -f1)"
    [ "$(cat "$stamp" 2> /dev/null)" = "$sum" ] && continue
    mkdir -p "$(dirname "$cfg")" "$(dirname "$stamp")"
    if [ -s "$cfg" ] && jq empty "$cfg" &> /dev/null; then
        cp -a "$cfg" "$cfg.bak" 2> /dev/null
        tmp="$(mktemp)"
        if jq -s '.[0] * .[1]' "$cfg" "$shipped" > "$tmp"; then mv "$tmp" "$cfg"; else rm -f "$tmp"; continue; fi
    else
        cp "$shipped" "$cfg"
    fi
    echo "$sum" > "$stamp"
    info "  ✓ $app: look updated"
done

if [ -f "$repo_path/setup/obsolete-packages" ]; then
    obsolete_installed=()
    while IFS= read -r pkg; do
        [ -n "$pkg" ] && pacman -Qq "$pkg" &> /dev/null && obsolete_installed+=("$pkg")
    done < <(sed 's/#.*//' "$repo_path/setup/obsolete-packages" | xargs -n1)
    if [ ${#obsolete_installed[@]} -gt 0 ] && gum confirm "Remove packages the desktop no longer uses: ${obsolete_installed[*]} (sudo)?"; then
        run_logged --title "Removing ${obsolete_installed[*]}..." sudo pacman -Rs --noconfirm "${obsolete_installed[@]}" \
            || POST_NOTES+=("Could not remove: ${obsolete_installed[*]}")
    fi
fi

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

step 2 7 "Firefox theme bridge"
if command -v pipx &> /dev/null && ! command -v pywalfox &> /dev/null; then
    run_logged --title "Installing pywalfox..." pipx install pywalfox \
        || POST_NOTES+=("pywalfox was not installed (pipx install pywalfox)")
fi

step 3 7 "Desktop apps (dock, power menu, launcher)"

install_app() {
    local name=$1 dest="$SHARE_DIR/$1"
    APP_CHANGED=0
    [ -d "$APPS_SRC/$name" ] || { warn "App source missing: $name"; return 1; }
    if [ -d "$dest" ] && diff -rq --exclude=.git "$APPS_SRC/$name" "$dest" &> /dev/null; then
        return 0
    fi
    mkdir -p "$dest"
    local del=(--delete --exclude=.git); [ "$name" = catastrophic-walker ] && del=()
    local keep="$HOME/.mydotfiles/backups/apps/$name/$(date +%Y%m%d_%H%M%S)"
    rsync -a --backup --backup-dir="$keep" "${del[@]}" "$APPS_SRC/$name/" "$dest/" || return 1
    rmdir "$keep" 2> /dev/null; rmdir "$HOME/.mydotfiles/backups/apps/$name" "$HOME/.mydotfiles/backups/apps" 2> /dev/null
    APP_CHANGED=1
}
report_app() {
    if [ "$APP_CHANGED" -eq 1 ]; then info "  ✓ $1 installed."; else info "  - $1 is already installed and up to date. Skipping."; fi
}

for app in catastrophic-dock catastrophic-powermenu; do
    if install_app "$app"; then
        ln -sf "$SHARE_DIR/$app/bin/$app" "$BIN_DIR/$app"
        report_app "$app"
    fi
done

if install_app quickshell-overview; then report_app quickshell-overview; fi

if install_app catastrophic-dotfiles-settings; then
    if ! cmp -s "$APPS_SRC/catastrophic-dotfiles-settings-launcher" "$BIN_DIR/catastrophic-dotfiles-settings"; then
        install -m755 "$APPS_SRC/catastrophic-dotfiles-settings-launcher" "$BIN_DIR/catastrophic-dotfiles-settings"
        APP_CHANGED=1
    fi
    report_app catastrophic-dotfiles-settings
fi

if install_app catastrophic-walker; then
    walker_changed=$APP_CHANGED
    [ -d "$SHARE_DIR/catastrophic-walker/.git" ] || git -C "$SHARE_DIR/catastrophic-walker" init -q
    if [ "$walker_changed" -eq 0 ] && { command -v walker && command -v elephant; } &> /dev/null; then
        info "  - walker and elephant are already installed. Skipping."
    elif run_logged --title "Installing walker and elephant..." \
        env CATASTROPHIC_WALKER_MANAGED=1 bash "$SHARE_DIR/catastrophic-walker/install.sh" --no-deps; then
        info "  ✓ walker and elephant installed."
    else
        error "  ✗ walker/elephant install failed. See $LOG_FILE"
        POST_NOTES+=("walker/elephant failed: run CATASTROPHIC_WALKER_MANAGED=1 bash ~/.local/share/catastrophic-walker/install.sh --no-deps")
    fi
fi

xdg-user-dirs-update 2> /dev/null || true

step 4 7 "System services"
svc_todo=()
for svc in NetworkManager bluetooth power-profiles-daemon; do
    systemctl list-unit-files "$svc.service" 2> /dev/null | grep -q "^$svc.service" || continue
    if systemctl is-enabled --quiet "$svc.service" 2> /dev/null; then
        info "  - $svc is already enabled. Skipping."
    else
        svc_todo+=("$svc")
    fi
done
net_old=()
if [[ " ${svc_todo[*]} " == *" NetworkManager "* ]]; then
    for svc in systemd-networkd iwd; do
        systemctl is-enabled --quiet "$svc.service" 2> /dev/null && net_old+=("$svc")
    done
fi
svc_question="Enable ${svc_todo[*]} (sudo)?"
[ ${#net_old[@]} -gt 0 ] && svc_question="Enable ${svc_todo[*]} (sudo)? NetworkManager replaces ${net_old[*]}, which will be switched off from the next boot"
if [ ${#svc_todo[@]} -gt 0 ] && gum confirm "$svc_question"; then
    for svc in "${svc_todo[@]}"; do
        sudo systemctl enable "$svc.service" &>> "$LOG_FILE" && info "  ✓ $svc enabled." \
            || warn "  Could not enable $svc."
    done
    for svc in "${net_old[@]}"; do
        sudo systemctl disable "$svc.service" &>> "$LOG_FILE" && info "  ✓ $svc switched off (NetworkManager replaces it)." \
            || warn "  Could not switch off $svc."
    done
    [ ${#net_old[@]} -gt 0 ] && POST_NOTES+=("Wi-Fi: after rebooting, connect again from the Wi-Fi icon in the bar (NetworkManager does not know your old networks)")
fi

step 5 7 "Graphics driver"
if lspci 2> /dev/null | grep -iE 'vga|3d' | grep -qi nvidia; then
    if pacman -Qq nvidia-utils &> /dev/null; then
        info "  - An NVIDIA driver is already installed. Skipping."
    else
        warn "An NVIDIA GPU was detected."
        if command -v chwd &> /dev/null; then
            if gum confirm "Install the matching NVIDIA driver with CachyOS chwd (sudo chwd -a)?"; then
                run_logged --title "Installing GPU drivers..." sudo chwd -a \
                    && info "  ✓ GPU drivers installed." \
                    || POST_NOTES+=("GPU driver install failed: run sudo chwd -a")
            fi
        else
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
else
    info "  - No NVIDIA GPU detected. Skipping."
fi

step 6 7 "Login manager"
if systemctl is-enabled --quiet sddm 2> /dev/null; then
    info "  - SDDM is already your login manager. Skipping."
elif gum confirm "Use SDDM as your login manager (disables the current one, sudo)?"; then
    sudo systemctl enable --force sddm.service &>> "$LOG_FILE" && info "  ✓ SDDM enabled." \
        || POST_NOTES+=("Could not enable SDDM")
fi
if ! systemctl is-enabled --quiet display-manager.service 2> /dev/null; then
    POST_NOTES+=("No login screen is enabled. After rebooting, log in on the console and run: uwsm start hyprland.desktop")
fi

step 7 7 "Branding"
if [ -d "$BRAND_SRC" ]; then
    icon_todo=0
    cmp -s "$BRAND_SRC/mark.svg" /usr/share/icons/hicolor/scalable/apps/catastrophic.svg 2> /dev/null || icon_todo=1
    cmp -s "$BRAND_SRC/mark.png" /usr/share/pixmaps/catastrophic.png 2> /dev/null || icon_todo=1

    splash_possible=0; splash_todo=0
    if grep -rqs 'plymouth' /etc/mkinitcpio.conf /etc/mkinitcpio.conf.d 2> /dev/null; then
        splash_possible=1
        [ "$(plymouth-set-default-theme 2> /dev/null)" = "catastrophic" ] || splash_todo=1
    fi

    if [ "$icon_todo" -eq 0 ] && [ "$splash_todo" -eq 0 ]; then
        info "  - The icon and boot splash are already installed. Skipping."
    elif gum confirm "Install the Catastrophic Shell icon and boot splash (sudo)?"; then
        if [ "$icon_todo" -eq 1 ]; then
            sudo install -Dm644 "$BRAND_SRC/mark.svg" /usr/share/icons/hicolor/scalable/apps/catastrophic.svg
            sudo install -Dm644 "$BRAND_SRC/mark.png" /usr/share/pixmaps/catastrophic.png
            sudo gtk-update-icon-cache -q /usr/share/icons/hicolor 2> /dev/null || true
            info "  ✓ Icon installed."
        fi
        if [ "$splash_todo" -eq 1 ]; then
            sudo install -d /usr/share/plymouth/themes/catastrophic
            sudo install -m644 "$BRAND_SRC"/plymouth/catastrophic/* /usr/share/plymouth/themes/catastrophic/
            if gum confirm "Rebuild the initramfs to apply the boot splash? (takes a minute)"; then
                run_logged --title "Applying boot splash..." sudo plymouth-set-default-theme -R catastrophic \
                    && info "  ✓ Boot splash installed." \
                    || POST_NOTES+=("Boot splash failed. See $LOG_FILE")
            fi
        elif [ "$splash_possible" -eq 0 ]; then
            warn "The plymouth hook is not enabled in mkinitcpio. Skipping the boot splash."
            POST_NOTES+=("Boot splash skipped: add 'plymouth' to HOOKS in /etc/mkinitcpio.conf and add 'splash' to your kernel parameters to enable it")
        fi
    fi
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/catastrophic"
mkdir -p "$state_dir"
if installed_sha="$(git -C "$repo_path" rev-parse HEAD 2> /dev/null)" && [ -n "$installed_sha" ]; then
    echo "$installed_sha" > "$state_dir/installed-commit"
    rm -f "$state_dir/skipped-commit"
    echo ok > "$state_dir/update-status"
fi

if [ ${#POST_NOTES[@]} -gt 0 ]; then
    echo
    warn "Things that need your attention:"
    for n in "${POST_NOTES[@]}"; do warn "  - $n"; done
fi
