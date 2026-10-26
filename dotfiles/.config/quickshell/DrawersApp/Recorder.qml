pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen recording state for the bar. The work is done by catastrophic-record;
// this only watches its state file, so it costs nothing while idle.
Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-record"
    readonly property string statePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/catastrophic-record"

    property bool active: false
    // Seconds since the recording began
    property int elapsed: 0
    property real began: 0

    readonly property string clock: {
        const m = Math.floor(elapsed / 60), s = elapsed % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function run(args): void {
        Quickshell.execDetached([script].concat(args))
    }
    function toggle(): void { run(["toggle"]) }
    function stop(): void { run(["stop"]) }

    FileView {
        path: root.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const f = text().trim().split(/\s+/)
            root.began = Number(f[1]) || 0
            root.active = root.began > 0
            root.elapsed = root.active ? Math.max(0, Math.floor(Date.now() / 1000 - root.began)) : 0
        }
        onLoadFailed: { root.active = false; root.elapsed = 0 }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: root.elapsed = Math.max(0, Math.floor(Date.now() / 1000 - root.began))
    }

    IpcHandler {
        target: "record"
        function toggle(): void { root.run(["toggle", "screen"]) }
        function area(): void { root.run(["toggle", "area"]) }
        function areaAudio(): void { root.run(["toggle", "area", "audio"]) }
        function screen(): void { root.run(["toggle", "screen"]) }
        function stop(): void { root.stop() }
        function openLast(): void { root.run(["open-last"]) }
        function active(): bool { return root.active }
    }
}
