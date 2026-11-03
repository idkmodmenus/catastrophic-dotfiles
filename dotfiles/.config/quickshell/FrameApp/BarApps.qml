import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme
import qs.Widgets

RowLayout {
    id: apps

    property int iconSize: 20
    spacing: 2

    property var pinned: ["firefox", "kitty"]
    property bool dockEnabled: false
    visible: !dockEnabled

    FileView {
        path: Quickshell.env("HOME") + "/.config/catastrophic-dock/config.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const cfg = JSON.parse(text())
                if (Array.isArray(cfg?.apps?.pinned)) apps.pinned = cfg.apps.pinned
                apps.dockEnabled = cfg?.dock?.enabled === true
            } catch (e) {}
        }
        onLoadFailed: apps.dockEnabled = false
    }

    function lookupEntry(appId: string): var {
        if (!appId) return null
        const direct = DesktopEntries.heuristicLookup(appId)
        if (direct) return direct
        const wanted = appId.toLowerCase()
        const all = DesktopEntries.applications.values
        for (let i = 0; i < all.length; i++) {
            const cmd = all[i].command
            if (cmd && cmd.length > 0 && `${cmd[0]}`.split("/").pop().toLowerCase() === wanted)
                return all[i]
        }
        return null
    }

    function keyFor(appId: string): string {
        const e = lookupEntry(appId)
        return e ? e.id : (appId ?? "").toLowerCase()
    }

    function iconFor(entry: var, appId: string): string {
        const raw = `${entry?.icon ?? ""}`.trim().replace(/^image:\/\/icon\//, "").split("?")[0].trim()
        const name = raw.length > 0 ? raw : appId
        return Quickshell.iconPath(name || "application-x-executable", "application-x-executable")
    }

    readonly property var entries: {
        DesktopEntries.applications.values
        const toplevels = ToplevelManager.toplevels.values
        let byKey = ({}), order = []
        const make = (key, appId, isPinned) => {
            const e = apps.lookupEntry(appId)
            return { key: key, appId: appId, entry: e, name: e?.name || appId,
                     icon: apps.iconFor(e, appId), windows: [], pinned: isPinned }
        }
        for (const id of apps.pinned) {
            const key = apps.keyFor(id)
            if (key && byKey[key] === undefined) { byKey[key] = make(key, id, true); order.push(key) }
        }
        for (const t of toplevels) {
            const key = apps.keyFor(t.appId)
            if (!key) continue
            if (byKey[key] === undefined) { byKey[key] = make(key, t.appId, false); order.push(key) }
            byKey[key].windows.push(t)
        }
        return order.map(k => byKey[k])
    }

    Repeater {
        model: apps.entries

        Item {
            id: app
            required property var modelData
            readonly property bool running: modelData.windows.length > 0
            readonly property bool focused: modelData.windows.includes(ToplevelManager.activeToplevel)

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: apps.iconSize + 12
            implicitHeight: apps.iconSize + 12

            function launch(): void {
                if (modelData.entry) AppLaunch.run(modelData.entry)
                else Quickshell.execDetached(["bash", "-c", modelData.appId])
            }
            function activate(): void {
                const w = modelData.windows
                if (w.length === 0) { launch(); return }
                const i = w.indexOf(ToplevelManager.activeToplevel)
                w[(i + 1) % w.length].activate()
            }

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: Theme.surface_container_highest
                opacity: mouse.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Image {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                width: apps.iconSize
                height: apps.iconSize
                sourceSize: Qt.size(apps.iconSize * 2, apps.iconSize * 2)
                source: app.modelData.icon
                smooth: true
                scale: mouse.pressed ? 0.88 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                visible: app.running
                width: app.focused ? 12 : 4
                height: 3
                radius: 1.5
                color: app.focused ? Theme.primary : Theme.on_surface
                opacity: app.focused ? 1 : 0.6
                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: m => m.button === Qt.MiddleButton ? app.launch() : app.activate()
            }
        }
    }

    Item {
        id: grid
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: apps.iconSize + 12
        implicitHeight: apps.iconSize + 12

        Rectangle {
            anchors.fill: parent
            radius: 9
            color: Theme.primary
            opacity: gridMouse.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Grid {
            anchors.centerIn: parent
            columns: 3
            spacing: 3
            scale: gridMouse.pressed ? 0.88 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }

            Repeater {
                model: 9
                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: gridMouse.containsMouse ? Theme.on_primary : Theme.on_surface
                }
            }
        }

        MouseArea {
            id: gridMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/catastrophic/scripts/catastrophic-launcher"])
        }
    }
}
