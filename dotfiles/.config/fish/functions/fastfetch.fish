# fastfetch sized to the terminal: logo beside the info when there is room,
# above it when narrow, and left out when the window is too short for both.
# With arguments it is plain fastfetch.
function fastfetch --description 'fastfetch that fits the terminal'
    if test (count $argv) -gt 0
        command fastfetch $argv
        return
    end

    # The Linux console has no Nerd Font glyphs
    if test "$TERM" = linux
        command fastfetch --config none --logo arch_small -s title:os:kernel:cpu:memory:uptime
        return
    end

    # Read the size from the tty itself: $COLUMNS can lag behind a resize
    set -l size (stty size </dev/tty 2>/dev/null | string split ' ')
    set -l rows $size[1]
    set -l cols $size[2]
    test -n "$rows"; or set rows $LINES
    test -n "$cols"; or set cols $COLUMNS

    test $cols -lt 26; and return

    set -l layout --logo-position left
    if test $cols -lt 68
        if test $rows -ge 20
            set layout --logo-position top
        else
            set layout --logo none
        end
        # Shorter memory line (smaller bar, one decimal) so it fits down to 40 columns
        set -a layout --bar-width 6 --size-ndigits 1
    end

    # A broken config falls back to fastfetch's built-in defaults
    command fastfetch $layout 2>/dev/null; or command fastfetch --config none $layout
end
