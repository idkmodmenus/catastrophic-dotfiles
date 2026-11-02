set -l omp ""
if type -q oh-my-posh
    set omp (type -p oh-my-posh)[1]
else if test -x $HOME/.local/bin/oh-my-posh
    set omp $HOME/.local/bin/oh-my-posh
end
if test -n "$omp"
    $omp init fish --config $HOME/.config/ohmyposh/zen.toml | source
end
