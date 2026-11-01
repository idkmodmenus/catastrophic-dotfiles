pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

// Notification server and state shared by the popups, the centre and the bar
Singleton {
    id: root

    property bool dnd: false
    // The centre lists everything, so toasts stay out of its way while it is open
    property bool centerOpen: false
    // Notifications currently shown as toasts
    property var popups: []
    readonly property var all: server.trackedNotifications.values
    readonly property int count: all.length

    // Apps whose toasts are suppressed; their notifications still reach the
    // centre. Saved one name per line.
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
        // A missing file just means nothing is muted yet
        printErrors: false
        onLoaded: root.muted = text().split("\n").map(l => l.trim()).filter(l => l !== "")
        // First run: no file yet, nothing is muted
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

    // swaync can be D-Bus activated before the shell has registered, and would
    // then keep the notification service. Stop it so this server can take over
    // (the server retries registration once the name is released).
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

    // Drop popups whose notification went away (closed by the app or by us)
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
