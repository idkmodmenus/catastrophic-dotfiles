# -----------------------------------------------------
# INIT
# -----------------------------------------------------

set -U fish_greeting ""

# -----------------------------------------------------
# Exports
# -----------------------------------------------------
if type -q nvim; export EDITOR=nvim; end

set -U fish_user_paths /usr/lib/ccache/bin/
set -U fish_user_paths $fish_user_paths $HOME/.cargo/bin/
set -U fish_user_paths $fish_user_paths $HOME/.local/bin/