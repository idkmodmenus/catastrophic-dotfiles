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

    signal centerRequested()

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
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            const critical = n.urgency === NotificationUrgency.Critical
            if (!root.dnd || critical)
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
        function dnd(): bool { return root.dnd }
        function count(): int { return root.count }
    }
}
