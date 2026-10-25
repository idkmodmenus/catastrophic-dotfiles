# -----------------------------------------------------
# AUTOSTART
# -----------------------------------------------------

# -----------------------------------------------------
# Fastfetch
# -----------------------------------------------------
if status is-interactive
    # Tiling resizes a new terminal right after it opens, which would reflow
    # the logo, so redraw on resize until the first command is run. Set up
    # before the first draw so a resize during startup is not missed.
    function __fastfetch_redraw --on-signal WINCH
        clear
        fastfetch
        # repaint starts the prompt one line up per extra prompt line, so
        # leave those lines blank instead of letting it cover the output
        set -l extra (math (count (fish_prompt)) - 1)
        test $extra -gt 0; and printf '\n%.0s' (seq $extra)
        commandline -f repaint
    end

    function __fastfetch_stop --on-event fish_preexec
        functions -e __fastfetch_redraw __fastfetch_stop
    end

    fastfetch
end
