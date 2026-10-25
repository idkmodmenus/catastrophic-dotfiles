# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

# -----------------------------------------------------
# General
# -----------------------------------------------------
alias ..='cd ..'
alias c='clear'
alias nf='fastfetch'
alias pf='fastfetch'
alias ff='fastfetch'
if type -q eza
    alias ls='eza -a --icons=always'
    alias ll='eza -al --icons=always'
    alias lt='eza -a --tree --level=1 --icons=always'
end
alias shutdown='~/.config/catastrophic/scripts/catastrophic-power -p'
alias v='$EDITOR'
alias vim='$EDITOR'
alias wifi='nmtui'
alias arch-cleanup='~/.config/catastrophic/scripts/arch/cleanup.sh'
alias apps='~/.config/catastrophic/bin/catastrophic-apps'
alias screenshot='~/.config/catastrophic/bin/catastrophic-screenshot'
alias updates='~/.config/catastrophic/scripts/catastrophic-install-system-updates'
alias filemanager='~/.config/catastrophic/settings/filemanager'
alias autostart='~/.config/catastrophic/scripts/catastrophic-autostart'
alias lock='hyprlock'
alias clock='tty-clock'
alias system='~/.config/catastrophic/settings/systemmonitor'
alias quick='~/.config/catastrophic/bin/catastrophic-quicklinks'
alias wallpaper='~/.config/catastrophic/bin/catastrophic-wallpaper'
alias settings='catastrophic-dotfiles-settings com.catastrophic.dotfiles'

# -----------------------------------------------------
# Catastrophic Apps
# -----------------------------------------------------
alias catastrophic='qs ipc call welcome toggle'
alias catastrophic-settings='qs -p ~/.local/share/catastrophic-dotfiles-settings/quickshell ipc call settings toggle'
alias catastrophic-calendar='qs ipc call calendar toggle'
alias catastrophic-hyprland='flatpak run com.catastrophic.hyprlandsettings'
alias catastrophic-sidebar='qs ipc call sidebar toggle'

# -----------------------------------------------------
# Git
# -----------------------------------------------------
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gfo="git fetch origin"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"

# -----------------------------------------------------
# Scripts
# -----------------------------------------------------
alias ascii='~/.config/catastrophic/scripts/figlet.sh'

# -----------------------------------------------------
# System
# -----------------------------------------------------
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
