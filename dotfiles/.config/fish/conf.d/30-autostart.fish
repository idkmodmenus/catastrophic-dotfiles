if status is-interactive
    function __fastfetch_redraw --on-signal WINCH
        clear
        fastfetch
        set -l extra (math (count (fish_prompt)) - 1)
        test $extra -gt 0; and printf '\n%.0s' (seq $extra)
        commandline -f repaint
    end

    function __fastfetch_stop --on-event fish_preexec
        functions -e __fastfetch_redraw __fastfetch_stop
    end

    fastfetch
end
