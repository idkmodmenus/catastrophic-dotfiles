# -----------------------------------------------------
# CUSTOMIZATION
# -----------------------------------------------------

# -----------------------------------------------------
# Prompt
# -----------------------------------------------------
# oh-my-posh is a package (/usr/bin) on a fresh install, or a user install in
# ~/.local/bin. Use whichever exists and skip quietly when neither does.
set -l omp ""
if type -q oh-my-posh
    set omp (type -p oh-my-posh)[1]
else if test -x $HOME/.local/bin/oh-my-posh
    set omp $HOME/.local/bin/oh-my-posh
end
if test -n "$omp"
    $omp init fish --config $HOME/.config/ohmyposh/zen.toml | source
end
# eval "$($HOME/.local/bin/oh-my-posh init fish --config $HOME/.config/ohmyposh/EDM115-newline.omp.json)"
