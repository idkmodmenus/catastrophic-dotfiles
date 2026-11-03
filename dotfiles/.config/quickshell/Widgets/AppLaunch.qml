pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string wrapper: "d=$1; shift; [ -n \"$d\" ] && cd \"$d\" 2>/dev/null; if command -v systemd-run >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then exec systemd-run --user --scope --collect --quiet --slice=app-graphical.slice --unit=\"$0\" \"$@\"; else exec \"$@\"; fi"

    function command(entry): var {
        const cmd = entry.command
        if (!cmd || cmd.length === 0)
            return null
        const id = String(entry.id || "app").replace(/[^A-Za-z0-9_.-]/g, "_")
        const unit = "app-catastrophic-" + id + "-" + Date.now().toString(36)
        return ["sh", "-c", wrapper, unit, entry.workingDirectory || ""].concat(cmd)
    }

    function run(entry): void {
        if (!entry)
            return
        const cmd = entry.runInTerminal ? null : command(entry)
        if (!cmd) {
            entry.execute()
            return
        }
        Quickshell.execDetached(cmd)
    }
}
