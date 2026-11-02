pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property bool dnd: false
    property bool centerOpen: false
    property var popups: []
    readonly property var all: server.trackedNotifications.values
    readonly property int count: all.length

    property var muted: []
    readonly property string mutedPath: Quickshell.env("HOME") + "/.config/catastrophic/settings/notif-muted"

    signal centerRequested()

    function isMuted(app: string): bool {
        return app !== "" && muted.indexOf(app) >= 0
    }
    function setMuted(app: string, on: bool): void {
        if (app === "") return
        const rest = muted.filter(a => a !== app)
        muted = on ? [...rest, app].sort() : rest
        mutedFile.setText(muted.join("\n") + (muted.length ? "\n" : ""))
        if (on)
            popups = popups.filter(p => p.appName !== app)
    }
    function clearApp(app: string): void {
        for (const n of all.slice())
            if (n.appName === app) n.dismiss()
    }

    FileView {
        id: mutedFile
        path: root.mutedPath
        printErrors: false
        onLoaded: root.muted = text().split("\n").map(l => l.trim()).filter(l => l !== "")
        onLoadFailed: root.muted = []
    }

    function showPopup(n): void {
        if (popups.indexOf(n) < 0)
            popups = [n, ...popups].slice(0, 4)
    }
    function hidePopup(n): void {
        popups = popups.filter(p => p !== n)
    }
    function clearAll(): void {
        for (const n of all.slice())
            n.dismiss()
        popups = []
    }

    Process {
        command: ["bash", "-c", "pgrep -x swaync >/dev/null && pkill -x swaync; true"]
        running: true
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            const critical = n.urgency === NotificationUrgency.Critical
            if (critical || (!root.dnd && !root.isMuted(n.appName)))
                root.showPopup(n)
        }
    }

    Connections {
        target: server.trackedNotifications
        function onValuesChanged() {
            root.popups = root.popups.filter(p => server.trackedNotifications.values.indexOf(p) >= 0)
        }
    }

    IpcHandler {
        target: "notifications"
        function center(): void { root.centerRequested() }
        function clear(): void { root.clearAll() }
        function toggleDnd(): void { root.dnd = !root.dnd }
        function mute(app: string): void { root.setMuted(app, true) }
        function unmute(app: string): void { root.setMuted(app, false) }
        function muted(): string { return root.muted.join(",") }
        function dnd(): bool { return root.dnd }
        function count(): int { return root.count }
    }
}
