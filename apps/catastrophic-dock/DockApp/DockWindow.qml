import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import qs.DockApp

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "catastrophic-dock"
    exclusionMode: root.reservesSpace
        ? ExclusionMode.Normal
        : ExclusionMode.Ignore

    screen: {
        const screens = Quickshell.screens
        if (!screens || screens.length === 0)
            return null
        const monitors = Hyprland.monitors.values
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].id !== 0)
                continue
            for (let s = 0; s < screens.length; s++)
                if (screens[s].name === monitors[i].name)
                    return screens[s]
        }
        return screens[0]
    }

    readonly property var settings: DockSettings.settings

    readonly property var pinnedApps: settings.apps.pinned

    function isPinned(key: string): bool {
        const pinned = root.pinnedApps
        for (let i = 0; i < pinned.length; i++)
            if (root.entryKey(pinned[i]) === key)
                return true
        return false
    }

    function pinApp(key: string): void {
        if (!key || root.isPinned(key))
            return
        DockSettings.persistPinned(root.pinnedApps.concat([key]))
    }

    function unpinApp(key: string): void {
        if (!key)
            return
        DockSettings.persistPinned(
            root.pinnedApps.filter(id => root.entryKey(id) !== key))
    }

    function lookupEntry(appId: string): var {
        if (!appId)
            return null
        const direct = DesktopEntries.heuristicLookup(appId)
        if (direct)
            return direct
        const wanted = appId.toLowerCase()
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; i++) {
            const command = apps[i].command
            if (!command || command.length === 0)
                continue
            if (`${command[0]}`.split("/").pop().toLowerCase() === wanted)
                return apps[i]
        }
        return null
    }

    function entryKey(appId: string): string {
        if (!appId)
            return ""
        const entry = root.lookupEntry(appId)
        return entry ? entry.id : appId.toLowerCase()
    }

    function iconFor(entry: var, appId: string): string {
        const raw = `${entry?.icon ?? ""}`.trim()
            .replace(/^image:\/\/icon\//, "").split("?")[0].trim()
        const name = raw.length > 0 ? raw : (appId ? appId : "")
        return Quickshell.iconPath(
            name.length > 0 ? name : "application-x-executable",
            "application-x-executable")
    }

    readonly property var dockEntries: {
        DesktopEntries.applications.values
        const toplevels = ToplevelManager.toplevels.values
        let byKey = ({})
        let order = []

        function makeItem(key, appId, pinned) {
            const desktopEntry = root.lookupEntry(appId)
            const name = desktopEntry && desktopEntry.name.length > 0
                ? desktopEntry.name : appId
            return { "key": key, "appId": appId, "desktopEntry": desktopEntry,
                     "name": name, "iconSource": root.iconFor(desktopEntry, appId),
                     "windows": [], "pinned": pinned }
        }

        const pinned = root.pinnedApps
        for (let i = 0; i < pinned.length; i++) {
            const key = root.entryKey(pinned[i])
            if (key === "" || byKey[key] !== undefined)
                continue
            byKey[key] = makeItem(key, pinned[i], true)
            order.push(key)
        }

        for (let i = 0; i < toplevels.length; i++) {
            const toplevel = toplevels[i]
            const key = root.entryKey(toplevel.appId)
            if (key === "")
                continue
            if (byKey[key] === undefined) {
                byKey[key] = makeItem(key, toplevel.appId, false)
                order.push(key)
            }
            byKey[key].windows.push(toplevel)
        }

        return order.map(key => byKey[key])
    }

    property bool autohide: settings.dock.autohide

    readonly property bool reservesSpace: settings.dock.reserveSpace && !autohide
    exclusiveZone: reservesSpace
        ? (collapsible ? collapsedHeight : dockHeight) + settings.dock.marginBottom
        : -1

    readonly property bool collapsible: settings.dock.collapsible
    property bool dockOpen: false
    readonly property bool collapsed: collapsible && !dockOpen
    readonly property int collapsedHeight: 30

    Timer {
        id: collapseDelay
        interval: 1200
        onTriggered: root.dockOpen = false
    }

    property var menuItem: null
    readonly property bool menuOpen: contextMenu.visible

    function openMenuFor(item, actions): void {
        root.menuItem = item
        contextMenu.actions = actions
        contextMenu.visible = true
    }

    function closeMenu(): void {
        contextMenu.visible = false
        root.menuItem = null
        if (root.dockOpen && !dockHover.hovered)
            collapseDelay.restart()
    }

    HyprlandFocusGrab {
        windows: [root]
        active: contextMenu.visible
        onCleared: root.closeMenu()
    }

    readonly property bool revealed: !autohide || root.pointerHeld
        || root.menuOpen

    property bool pointerHeld: false

    Timer {
        id: hideDelay
        interval: root.settings.dock.hideDelay
        onTriggered: root.pointerHeld = false
    }

    color: "transparent"

    anchors {
        bottom: true
        left: true
        right: true
    }

    readonly property int dockHeight: settings.dock.iconSize
        + 2 * settings.pill.padding + 10
    readonly property int menuReserve: 3 * 32 + 2 * 2 + 16 + 8
    implicitHeight: dockHeight + settings.dock.marginBottom + 30 + menuReserve

    readonly property int hotZoneHeight: root.revealed
        ? settings.dock.marginBottom + 3
        : 3

    mask: Region {
        Region {
            x: 0
            y: 0
            width: root.menuOpen ? root.width : 0
            height: root.menuOpen ? root.height : 0
        }
        Region {
            x: Math.round(pill.x)
            y: Math.round(pill.y)
            width: root.menuOpen ? 0 : Math.round(pill.width)
            height: root.menuOpen ? 0 : Math.round(pill.height)
        }
        Region {
            x: 0
            y: root.height - root.hotZoneHeight
            width: (root.autohide && !root.menuOpen) ? root.width : 0
            height: (root.autohide && !root.menuOpen) ? root.hotZoneHeight : 0
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.menuOpen
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.closeMenu()
    }

    HoverHandler {
        id: dockHover
        onHoveredChanged: {
            if (dockHover.hovered) {
                hideDelay.stop()
                collapseDelay.stop()
                root.pointerHeld = true
            } else {
                hideDelay.restart()
                if (root.dockOpen && !root.menuOpen)
                    collapseDelay.restart()
            }
        }
    }

    Item {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        width: root.collapsed
            ? dotsToggle.implicitWidth + 8
            : dockRow.implicitWidth + 2 * root.settings.pill.padding
        height: root.collapsed ? root.collapsedHeight : root.dockHeight

        Behavior on height {
            NumberAnimation {
                duration: root.settings.pill.animationDuration
                easing.type: Easing.OutQuint
            }
        }

        property real revealOffset: root.revealed
            ? root.settings.dock.marginBottom
            : -(height - 3)

        Behavior on revealOffset {
            NumberAnimation {
                duration: root.settings.pill.animationDuration
                easing.type: Easing.OutQuint
            }
        }

        y: parent.height - height - revealOffset

        Behavior on width {
            NumberAnimation {
                duration: root.settings.pill.animationDuration
                easing.type: Easing.OutQuint
            }
        }

        readonly property int tabEdge: root.settings.pill.tabEdge
        readonly property bool asTab: root.collapsed && tabEdge > 0

        Shape {
            id: tab
            visible: opacity > 0
            opacity: pill.asTab ? 1 : 0
            preferredRendererType: Shape.CurveRenderer
            Behavior on opacity { NumberAnimation { duration: 150 } }

            readonly property real ear: 10
            readonly property real r: 12
            readonly property real w: pill.width
            readonly property real base: pill.height - pill.tabEdge

            ShapePath {
                fillColor: DockTheme.background
                strokeColor: "transparent"
                startX: -tab.ear; startY: tab.base
                PathQuad { x: 0; y: tab.base - tab.ear; controlX: 0; controlY: tab.base }
                PathLine { x: 0; y: tab.r }
                PathArc { x: tab.r; y: 0; radiusX: tab.r; radiusY: tab.r }
                PathLine { x: tab.w - tab.r; y: 0 }
                PathArc { x: tab.w; y: tab.r; radiusX: tab.r; radiusY: tab.r }
                PathLine { x: tab.w; y: tab.base - tab.ear }
                PathQuad { x: tab.w + tab.ear; y: tab.base; controlX: tab.w; controlY: tab.base }
                PathLine { x: tab.w + tab.ear; y: pill.height }
                PathLine { x: -tab.ear; y: pill.height }
            }
        }

        RectangularShadow {
            visible: !pill.asTab
            anchors.fill: pillBg
            radius: pillBg.radius
            blur: 15
            color: Qt.rgba(DockTheme.shadow.r, DockTheme.shadow.g, DockTheme.shadow.b, 0.4 * pillBg.opacity)
        }

        Rectangle {
            id: pillBg
            anchors.fill: parent
            radius: root.settings.pill.radius
            opacity: pill.asTab ? 0 : root.settings.opacity.normal

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: root.settings.border.colorTop !== ""
                        ? root.settings.border.colorTop
                        : DockTheme.primary
                }
                GradientStop {
                    position: 1.0
                    color: root.settings.border.colorBottom !== ""
                        ? root.settings.border.colorBottom
                        : DockTheme.on_primary
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: root.settings.border.width
                radius: parent.radius - anchors.margins
                color: DockTheme.background
            }
        }

        DockDotsButton {
            id: dotsToggle
            anchors.centerIn: parent
            anchors.verticalCenterOffset: pill.asTab ? -pill.tabEdge / 2 : 0
            visible: opacity > 0
            opacity: root.collapsed ? 1 : 0
            onToggled: root.dockOpen = true

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
            }
        }

        RowLayout {
            id: dockRow
            anchors.centerIn: parent
            spacing: root.settings.dock.spacing
            visible: opacity > 0
            opacity: root.collapsed ? 0 : 1
            enabled: !root.collapsed

            Behavior on opacity {
                NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
            }

            DockLauncherButton {
                visible: DockSettings.launcherButton
                command: root.settings.dock.launcherCommand
                iconSize: root.settings.dock.iconSize
                dockWindow: root
                Layout.alignment: Qt.AlignVCenter

                onReloadRequested: {
                    DockSettings.reloadSettings()
                    DockTheme.reload()
                }
                onSettingsRequested: DockSettings.dialogOpen = true
                onEditConfigRequested: DockSettings.editConfig()
            }

            Rectangle {
                visible: DockSettings.launcherButton
                Layout.alignment: Qt.AlignVCenter
                Layout.bottomMargin: 4
                implicitWidth: 1
                implicitHeight: Math.round(root.settings.dock.iconSize * 0.75)
                color: DockTheme.primary
            }

            Repeater {
                model: root.dockEntries

                delegate: DockItem {
                    id: dockItem
                    required property var modelData

                    entry: modelData
                    iconSize: root.settings.dock.iconSize
                    dockWindow: root
                    Layout.alignment: Qt.AlignVCenter

                    onPinRequested: key => root.pinApp(key)
                    onUnpinRequested: key => root.unpinApp(key)
                }
            }

            DockDotsButton {
                visible: root.collapsible
                Layout.alignment: Qt.AlignVCenter
                onToggled: root.dockOpen = false
            }
        }
    }

    DockMenu {
        id: contextMenu

        x: {
            if (!root.menuItem)
                return 0
            const center = pill.x + dockRow.x + root.menuItem.x
                + root.menuItem.width / 2
            return Math.max(8, Math.min(root.width - width - 8, center - width / 2))
        }
        y: pill.y - height - 8

        onCloseRequested: root.closeMenu()
    }
}
