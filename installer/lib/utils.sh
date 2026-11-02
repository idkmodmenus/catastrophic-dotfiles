#!/usr/bin/env bash

backup_existing_profile() {
    local profile_dir=$1
    local id=$2
    local backup_root=$3
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_root/backups/profile-updates/$id/$timestamp"

    info "Backing up current profile state to $backup_path..."
    mkdir -p "$(dirname "$backup_path")"
    
    if cp -a "$profile_dir" "$backup_path"; then
        info "  - Backup completed successfully."
    else
        rm -rf "$backup_path"
        error "  - The backup failed (is the disk full?). Nothing has been changed."
        return 1
    fi
}

handle_restore_logic() {
    local json=$1
    local existing_dir=$2
    local temp_dir=$3
    local subfolder=$4

    local restore_data=$(echo "$json" | jq -r '.restore[] | "\(.title) [\(.source)]"' 2>/dev/null)
    
    if [ -z "$restore_data" ]; then
        return 0
    fi

    local selected_default=$(echo "$restore_data" | paste -sd "," -)
    
    info "Existing configuration found. Select items to keep (Restore):"
    info "Uncheck items to overwrite with default versions from the update."
    
    local user_selections
    if [ "${CATASTROPHIC_YES:-0}" = "1" ]; then
        user_selections="$restore_data"
    else
        user_selections=$(echo "$restore_data" | gum choose --no-limit --height 25 --selected="$selected_default")
    fi

    if [ -z "$user_selections" ]; then
        warn "No items selected for restoration. Overwriting with all defaults."
        return 0
    fi

    info "Merging custom configurations..."
    while IFS= read -r selection; do
        local title=$(echo "$selection" | sed 's/ \[.*\]$//')
        local rel_src=$(echo "$json" | jq -r ".restore[] | select(.title==\"$title\") | .source")
        
        local src_path="$existing_dir/$rel_src"
        
        local dest_path
        if [ -n "$subfolder" ] && [ "$subfolder" != "null" ]; then
            dest_path="$temp_dir/$subfolder/$rel_src"
        else
            dest_path="$temp_dir/$rel_src"
        fi

        if [ -e "$src_path" ]; then
            info "  - Restoring: $title ($rel_src)"
            mkdir -p "$(dirname "$dest_path")"
            cp -aT "$src_path" "$dest_path"
        else
            warn "  - Restore source not found: $rel_src"
        fi
    done <<< "$user_selections"
}

is_blacklisted() {
    local rel_path=$1
    local blacklist=$2
    [ -f "$blacklist" ] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | xargs)
        line="${line%/}"
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        [[ "$rel_path" == "$line" || "$rel_path" == "$line"/* || "$line" == "$rel_path"/* ]] && return 0
    done < "$blacklist"
    return 1
}

copy_with_blacklist() {
    local source=$1
    local target=$2
    local blacklist=$3
    local manifest=${4:-}

    local -A old_sum=()
    local mline
    if [ -n "$manifest" ] && [ -f "$manifest" ]; then
        while IFS= read -r mline; do
            [[ "$mline" =~ ^([0-9a-f]{64})\ \ (.*)$ ]] && old_sum["${BASH_REMATCH[2]}"]="${BASH_REMATCH[1]}"
        done < "$manifest"
    fi

    mkdir -p "$target"
    info "Staging files to $target..."

    local blacklisted=()
    if [ -f "$blacklist" ]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line=$(echo "$line" | xargs)
            line="${line%/}"
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            blacklisted+=("$line")
        done < "$blacklist"
        info "  - Active blacklist found with ${#blacklisted[@]} items."
    fi

    cd "$source" || return 1
    find . -mindepth 1 | while read -r item; do
        local rel_path="${item#./}"
        local target_path="$target/$rel_path"
        
        local skip=false
        for b in "${blacklisted[@]}"; do
            if [[ "$rel_path" == "$b" ]] || [[ "$rel_path" == "$b"/* ]]; then
                skip=true
                break
            fi
        done

        if [ "$skip" = true ]; then
            if [[ "$rel_path" == "$b" ]]; then
                warn "  - Skipping blacklisted entry: $rel_path"
            fi
            continue
        fi

        if [ -d "$item" ]; then
            mkdir -p "$target_path"
        elif [ -f "$item" ]; then
            mkdir -p "$(dirname "$target_path")"
            if [ -n "${old_sum[$rel_path]:-}" ] && [ ! -L "$item" ] && { [ -e "$target_path" ] || [ -L "$target_path" ]; } \
                && [ "${old_sum[$rel_path]}" = "$(sha256sum -- "$item" | cut -d' ' -f1)" ]; then
                continue
            fi
            cp -a "$item" "$target_path"
        fi
    done
}

remove_obsolete_paths() {
    local dir=$1 list=$2 rel p
    [ -f "$list" ] || return 0
    { [ -n "$dir" ] && [ -d "$dir" ] && [ "$dir" != "/" ] && [ "$dir" != "$HOME" ]; } || return 0
    while IFS= read -r rel || [ -n "$rel" ]; do
        rel=$(echo "$rel" | xargs)
        [[ -z "$rel" || "$rel" == \#* || "$rel" == /* || "$rel" == *..* ]] && continue
        for p in "$dir"/$rel; do
            if [ -e "$p" ] || [ -L "$p" ]; then
                rm -rf -- "$p"
                info "  - Removed obsolete: ${p#$dir/}"
            fi
        done
    done < "$list"
}

prune_obsolete() {
    local src_dir=$1 final_target=$2 clone_path=$3 manifest=$4
    { [ -n "$final_target" ] && [ -d "$final_target" ] && [ "$final_target" != "/" ] && [ "$final_target" != "$HOME" ]; } || return 0
    local removed=0 rel line d
    local touched=()

    remove_obsolete_paths "$final_target" "$clone_path/setup/obsolete-paths"

    if [ -f "$manifest" ]; then
        while IFS= read -r line; do
            rel=$(manifest_path "$line")
            [[ -z "$rel" || "$rel" == /* || "$rel" == *..* ]] && continue
            if [ ! -e "$src_dir/$rel" ] && [ ! -L "$src_dir/$rel" ] && { [ -e "$final_target/$rel" ] || [ -L "$final_target/$rel" ]; }; then
                rm -f -- "$final_target/$rel"; removed=$((removed + 1))
                touched+=("$(dirname "$final_target/$rel")")
                info "  - Removed (no longer in the repo): $rel"
            fi
        done < "$manifest"
    fi

    if [ "${#touched[@]}" -gt 0 ]; then
        while IFS= read -r d; do
            while [ "$d" != "$final_target" ] && [ "${d#"$final_target"/}" != "$d" ] && rmdir -- "$d" 2> /dev/null; do
                d=$(dirname "$d")
            done
        done < <(printf '%s\n' "${touched[@]}" | sort -u | awk '{print length($0) "\t" $0}' | sort -rn | cut -f2-)
    fi
    info "Obsolete file check done."
    return 0
}

write_manifest() {
    local src_dir=$1 manifest=$2 rel
    mkdir -p "$(dirname "$manifest")"
    ( cd "$src_dir" && find . \( -type f -o -type l \) | sed 's|^\./||' | sort | while IFS= read -r rel; do
        if [ -L "$rel" ]; then printf -- '-  %s\n' "$rel"; else printf '%s  %s\n' "$(sha256sum -- "$rel" | cut -d' ' -f1)" "$rel"; fi
    done ) > "$manifest"
}

manifest_path() {
    local line=$1
    if [[ "$line" =~ ^([0-9a-f]{64}|-)\ \ (.*)$ ]]; then echo "${BASH_REMATCH[2]}"; else echo "$line"; fi
}

remove_dangling_links() {
    local profile_dir=$1 link
    for link in "$HOME"/.[!.]* "$HOME"/* "$HOME"/.config/* "$HOME"/.config/.[!.]*; do
        [ -L "$link" ] && [ ! -e "$link" ] || continue
        case "$(readlink -m "$link")" in
            "$profile_dir"/*) rm -f -- "$link"; info "  - Removed dangling link: ${link#$HOME/}" ;;
        esac
    done
    return 0
}

create_symlink() {
    local source=$1; local target=$2; local backup_dir=$3
    local abs_source=$(realpath -m "$source")

    if [ -L "$target" ]; then
        local current_link_target=$(realpath -m "$target")
        if [ "$current_link_target" == "$abs_source" ]; then
            info "  - Link already correct for $(basename "$target"). Skipping."
            return 0
        else
            warn "  - Link $(basename "$target") points elsewhere ($(readlink "$target")). Recreating..."
            mkdir -p "$backup_dir"
            cp -a "$target" "$backup_dir/" || { error "  - Could not back up the link $target. Leaving it as it is."; return 1; }
            rm "$target"
        fi
    fi

    if [ -e "$target" ]; then
        warn "  - Existing file/folder found at $target. Creating backup..."
        mkdir -p "$backup_dir"
        if cp -a "$target" "$backup_dir/"; then
            rm -rf "$target"
        else
            error "  - Could not back up $target. Leaving it as it is."
            return 1
        fi
    fi

    info "  - Linking $target -> $source"
    ln -s --relative "$source" "$target"
}

deploy_symlinks() {
    local source_dir=$1; local backup_root=$2; local id=$3; local blacklist=$4
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$backup_root/backups/$id/$timestamp"

    info "Starting symlink deployment..."
    for item in "$source_dir"/* "$source_dir"/.*; do
        local name=$(basename "$item")
        [[ "$name" == "." || "$name" == ".." || "$name" == ".config" ]] && continue
        [ -e "$item" ] || continue

        if is_blacklisted "$name" "$blacklist"; then
            warn "  - Skipping blacklisted entry: $name"
            continue
        fi

        create_symlink "$item" "$HOME/$name" "$backup_dir"
    done

    if [ -d "$source_dir/.config" ]; then
        mkdir -p "$HOME/.config"
        for item in "$source_dir/.config"/* "$source_dir/.config"/.*; do
            local name=$(basename "$item")
            [[ "$name" == "." || "$name" == ".." ]] && continue
            [ -e "$item" ] || continue

            if is_blacklisted ".config/$name" "$blacklist"; then
                warn "  - Skipping blacklisted entry: .config/$name"
                continue
            fi

            create_symlink "$item" "$HOME/.config/$name" "$backup_dir"
        done
    fi
    info "Symlink deployment complete."
    info "Backups are in $backup_dir"
}

process_package_file() {
    local file=$1; [ ! -f "$file" ] && return 0
    local distro=$(get_distro_by_bin)
    info "Installing packages from $(basename "$file")"

    local raw lines=() pkg
    mapfile -t raw < "$file"
    for pkg in "${raw[@]}"; do
        pkg=$(echo "$pkg" | sed 's/#.*//' | xargs); [[ -n "$pkg" ]] && lines+=("$pkg")
    done
    local total=${#lines[@]} n=0 added=0 present=0 failed=0

    QUIET_PKG=1
    for pkg in "${lines[@]}"; do
        n=$((n + 1))

        local installed=false
        case "$distro" in
            arch)
                if pacman -Qi "$pkg" &> /dev/null || pacman -T "$pkg" &> /dev/null; then installed=true; fi
                ;;
            fedora|opensuse)
                if rpm -q "$pkg" &> /dev/null; then installed=true; fi
                ;;
            ubuntu)
                if dpkg-query -W -f='${Status}' "$pkg" 2> /dev/null | grep -q "install ok installed"; then installed=true; fi
                ;;
        esac

        if [ "$installed" = false ] && command -v "$pkg" &> /dev/null; then
            installed=true
        fi

        if [ "$installed" = true ]; then
            present=$((present + 1))
            progress_line "$n" "$total" "$pkg (already installed)"
        else
            progress_line "$n" "$total" "installing $pkg"
            if install_package "$pkg"; then
                added=$((added + 1))
            else
                failed=$((failed + 1))
                FAILED_PACKAGES+=("$pkg")
                progress_done
                error "  ✗ Failed to install $pkg"
            fi
        fi
    done
    QUIET_PKG=""
    progress_line "$total" "$total" "done"
    progress_done

    local retry=() still=() p
    for p in "${FAILED_PACKAGES[@]}"; do [[ " ${lines[*]} " == *" $p "* ]] && retry+=("$p") || still+=("$p"); done
    if [ ${#retry[@]} -gt 0 ]; then
        info "Trying ${#retry[@]} failed package(s) once more: ${retry[*]}"
        sleep 5
        for p in "${retry[@]}"; do
            if install_package "$p"; then
                info "  ✓ $p installed on the second try."
                added=$((added + 1)); failed=$((failed - 1))
            else
                still+=("$p")
            fi
        done
        FAILED_PACKAGES=("${still[@]}")
    fi
    info "  ✓ $total packages: $added installed, $present already present, $failed failed"
}

run_setup_logic() {
    local repo_path=$1; local profile_id=$2
    local distro=$(get_distro_by_bin)
    local dep_dir="$repo_path/setup/dependencies"
    local user_config_dir="$HOME/.config/catastrophic-dotfiles-installer/$profile_id"
    
    local preflight="$repo_path/setup/preflight.sh"
    if [ -f "$preflight" ]; then
        info "Running preflight script $preflight..."
        source "$preflight"
    fi
    local distro_preflight="$repo_path/setup/preflight-$distro.sh"
    if [ -f "$distro_preflight" ]; then 
        info "Running preflight script $distro_preflight for $distro..."
        source "$distro_preflight"
    fi
    
    if [ ! -d "$dep_dir" ]; then 
        warn "Dependency folder not found at: $dep_dir — skipping dependency install (post-install hooks will still run)."
    else
        FAILED_PACKAGES=()
        [ -f "$dep_dir/packages" ] && process_package_file "$dep_dir/packages"
        local distro_pkgs="$dep_dir/packages-$distro"
        [ -f "$distro_pkgs" ] && process_package_file "$distro_pkgs"
        if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
            warn "${#FAILED_PACKAGES[@]} package(s) could not be installed: ${FAILED_PACKAGES[*]}"
            warn "See the logfile for details: $LOG_FILE"
        fi
    fi

    local postflight="$repo_path/setup/post.sh"
    if [ -f "$postflight" ]; then
        info "Running post-installation script $postflight..."
        source "$postflight"
    fi
    local distro_postflight="$repo_path/setup/post-$distro.sh"
    if [ -f "$distro_postflight" ]; then 
        info "Running post-installation script $distro_postflight for $distro..."
        source "$distro_postflight"
    fi

    local user_post="$user_config_dir/post.sh"
    if [ -f "$user_post" ]; then
        info "Running user-specific post-installation script for $profile_id..."
        source "$user_post"
    fi
}

run_migration() {
    local repo_path=$1
    local profile_id=$2
    local migration="$repo_path/setup/migration.sh"
    if [ -f $migration ]; then
        info "Running migration script $migration for $profile_id..."
        source "$migration"
    fi
}

check_dependencies() {
    info "Checking system dependencies..."
    local failed=false
    check_and_install "make" "make" || failed=true
    check_and_install "git" "git" || failed=true
    check_and_install "curl" "curl" || failed=true
    check_and_install "jq" "jq" || failed=true
    check_and_install "gum" "gum" || failed=true
    if [ "$failed" = true ]; then
        error "Required tools for the installer are missing. Exiting."
        exit 1
    fi
}

set_active_profile() {
    local id=$1
    local active_file="$INSTALLER_CONFIG/active.json"

    echo "{\"active\":\"$id\"}" > "$active_file"
    
    info "Profile '$id' marked as active in $active_file"
}

read_dotinst() {
    local source=$1; local target_base_dir=$2; local test_mode=$3
    local content=$(get_json_content "$source")
    
    if [ $? -ne 0 ] || [ -z "$content" ]; then 
        error "Failed to read configuration from: $source"
        return 1 
    fi

    local name=$(echo "$content" | jq -r '.name // "Unknown Profile"')
    local id=$(echo "$content" | jq -r '.id // "N/A"')
    local author=$(echo "$content" | jq -r '.author // "N/A"')
    local homepage=$(echo "$content" | jq -r '.homepage // "N/A"')
    local description=$(echo "$content" | jq -r '.description // "No description provided."')
    local version=$(echo "$content" | jq -r '.version // "N/A"')
    local tag=$(echo "$content" | jq -r '.tag // empty')
    local git_url_raw=$(echo "$content" | jq -r '.source // empty')
    local subfolder=$(echo "$content" | jq -r '.subfolder // empty')

    local git_url="${git_url_raw/\$HOME/$HOME}"; git_url="${git_url/\~/$HOME}"
    local user_post="$HOME/.config/catastrophic-dotfiles-installer/$id/post.sh"

    local install_type_text="${GREEN}New Installation${NC}"
    [ -d "$target_base_dir/$id" ] && install_type_text="${YELLOW}Update of existing configuration${NC}"
    echo -e "${GREEN}--------------------------------------------------${NC}" >&2
    echo -e "${YELLOW}PROFILE INFORMATION${NC}" >&2
    [ "$test_mode" = true ] && echo -e "Mode:        ${RED}TEST MODE (Setup only)${NC}" >&2
    echo -e "Status:      $install_type_text" >&2
    echo -e "Name:        $name" >&2
    echo -e "ID:          $id" >&2
    echo -e "Version:     $version" >&2
    [ -n "$tag" ] && [ "$tag" != "null" ] && echo -e "Tag:         $tag" >&2
    echo -e "Author:      $author" >&2
    echo -e "Homepage:    $homepage" >&2
    echo -e "Source:      $git_url" >&2
    [ -n "$subfolder" ] && [ "$subfolder" != "null" ] && echo -e "Subfolder:   $subfolder" >&2
    if [ -f "$user_post" ]; then
        echo -e "User Script: ${GREEN}Detected${NC}" >&2
    else
        echo -e "User Script: None" >&2
    fi
    echo -e "Description: $description" >&2
    echo -e "${GREEN}--------------------------------------------------${NC}" >&2

    if [ "${CATASTROPHIC_YES:-0}" != "1" ] && [ "${CATASTROPHIC_CONFIRMED:-0}" != "1" ] \
        && ! gum confirm "Do you want to proceed with the installation?"; then info "Installation cancelled by user."; exit 0; fi

    local working_dir=$(mktemp -d -t catastrophic-dots-XXXXXX)
    if [ -d "$git_url" ]; then
        info "Local repository detected. Copying source..."
        cp -a "$git_url/." "$working_dir/"
    else
        info "Remote repository detected. Cloning source..."
        local clone_cmd="git clone --depth=1"
        [ -n "$tag" ] && [ "$tag" != "null" ] && clone_cmd="git clone --depth=1 --branch $tag"
        if ! $clone_cmd "$git_url" "$working_dir"; then 
            error "Failed to clone repository."; rm -rf "$working_dir"; return 1
        fi
    fi
    printf "%s %s %s" "$working_dir" "$id" "$subfolder"
}
