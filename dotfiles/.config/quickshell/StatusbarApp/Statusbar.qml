import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property bool enabled: true
    property bool wanted: false
    property var pending: []

    FileView {
        path: Quickshell.env("HOME") + "/.config/catastrophic-statusbar/config.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const bar = JSON.parse(text()).bar
                root.enabled = !bar || bar.enabled !== false
            } catch (e) {
                root.enabled = true
            }
        }
        onLoadFailed: root.enabled = true
    }

    LazyLoader {
        id: loader
        active: root.enabled || root.wanted
        component: StatusbarWindow {}

        onItemChanged: {
            if (!item)
                return
            const ops = root.pending
            root.pending = []
            for (const op of ops)
                op(item)
            releaseTimer.restart()
        }
    }

    Connections {
        target: loader.item
        function onVisibleChanged() { releaseTimer.restart() }
    }

    Timer {
        id: releaseTimer
        interval: 1500
        onTriggered: {
            if (root.wanted && loader.item && !loader.item.visible && !root.enabled)
                root.wanted = false
        }
    }

    function withBar(op): void {
        if (loader.item) {
            op(loader.item)
            releaseTimer.restart()
        } else {
            root.pending = root.pending.concat([op])
            root.wanted = true
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.withBar(b => b.calendarOpen = !b.calendarOpen) }
        function open(): void { root.withBar(b => b.calendarOpen = true) }
        function close(): void { if (loader.item) loader.item.calendarOpen = false }
        function isOpen(): bool { return loader.item ? loader.item.calendarOpen : false }
    }

    IpcHandler {
        target: "statusbar"
        function toggle(): void { root.withBar(b => b.setEnabled(!b.settings.bar.enabled)) }
        function enable(): void { root.withBar(b => b.setEnabled(true)) }
        function disable(): void { if (loader.item) loader.item.setEnabled(false) }
        function alwaysExpand(): void { root.withBar(b => b.setAlwaysExpanded(true)) }
        function autoCollapse(): void { root.withBar(b => b.setAlwaysExpanded(false)) }
        function autohideOn(): void { root.withBar(b => b.setAutohide(true)) }
        function autohideOff(): void { root.withBar(b => b.setAutohide(false)) }
        function autohideToggle(): void { root.withBar(b => b.setAutohide(!b.settings.bar.autohide)) }
        function refresh(): void { if (loader.item) loader.item.reloadSettings() }
        function focus(): void { if (loader.item) loader.item.focusBar() }
        function expand(): void { if (loader.item) loader.item.barExpanded = !loader.item.barExpanded }
        function collapse(): void { if (loader.item) loader.item.barExpanded = false }
        function reload(): void { if (loader.item) loader.item.reloadSettings() }
    }
}
