function fastfetch --description 'fastfetch that fits the terminal'
    if test (count $argv) -gt 0
        command fastfetch $argv
        return
    end

    if test "$TERM" = linux
        command fastfetch --config none --logo arch_small -s title:os:kernel:cpu:memory:uptime
        return
    end

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
        set -a layout --bar-width 6 --size-ndigits 1
    end

    command fastfetch $layout 2>/dev/null; or command fastfetch --config none $layout
end
