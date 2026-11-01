import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.CustomTheme
import qs.DrawersApp
import qs.Widgets

// Top band of the frame: launcher, name and workspaces on the left, the clock
// in the middle (it opens the dashboard), status and power on the right. The
// groups sit directly on the frame; only the workspace track and the battery
// chip are filled.
Item {
    id: bar

    readonly property alias leftIsland: left
    readonly property alias centerIsland: center
    readonly property alias rightIsland: right

    // At least 5 workspaces, growing to reach the highest one in use (1-10 have keybinds)
    readonly property int workspaceCount: Math.max(5,
        Hyprland.focusedWorkspace?.id ?? 0,
        ...Hyprland.workspaces.values.map(w => w.id))

    // Hover popouts: which one is open and the bar-relative centre of its icon.
    // Closing is delayed so the pointer can cross from the icon into the card.
    property string popoutKind: ""
    property real popoutX: 0
    property bool popoutHovered: false

    function openPopout(kind: string, item: Item): void {
        popoutCloser.stop()
        popoutX = item.mapToItem(bar, item.width / 2, 0).x
        popoutKind = kind
    }
    function closePopout(): void { popoutCloser.restart() }

    Timer {
        id: popoutCloser
        interval: 350
        onTriggered: if (!bar.popoutHovered) bar.popoutKind = ""
    }
    onPopoutHoveredChanged: if (!popoutHovered) closePopout()

    function run(cmd: string): void {
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    // Hyprland's Lua config rejects the plain "workspace N" dispatch string
    function focusWorkspace(target: string): void {
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({workspace = '" + target + "'})")
        else
            Hyprland.dispatch("workspace " + target)
    }

    // Icon button with a soft round highlight on hover
    component Icon: Item {
        id: icon
        property alias text: label.text
        property alias color: label.color
        property alias font: label.font
        readonly property bool hovered: mouse.containsMouse
        property string popout: ""
        // Stays lit while its popout is open, tying the two together
        readonly property bool lit: hovered || (popout !== "" && bar.popoutKind === popout)
        signal clicked(var mouse)
        signal scrolled(int delta)

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 28
        implicitHeight: 28

        onHoveredChanged: {
            if (!popout) return
            if (hovered) bar.openPopout(popout, icon)
            else bar.closePopout()
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.surface_container_highest
            opacity: icon.lit ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            id: label
            anchors.centerIn: parent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: icon.lit ? Theme.primary : Theme.on_surface_variant
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPositionChanged: if (icon.popout && bar.popoutKind !== icon.popout) bar.openPopout(icon.popout, icon)
            onClicked: m => icon.clicked(m)
            onWheel: w => icon.scrolled(w.angleDelta.y)
        }
    }

    // --- Left: launcher, name, workspaces ---
    Island {
        id: left
        raised: false
        x: Geometry.edgeMargin
        y: Geometry.barMargin
        width: leftRow.implicitWidth + 10
        height: Geometry.barHeight

        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

        // Scrolling over the island switches workspaces
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => bar.focusWorkspace(event.angleDelta.y > 0 ? "e-1" : "e+1")
        }

        RowLayout {
            id: leftRow
            anchors.verticalCenter: parent.verticalCenter
            x: 5
            spacing: 6

            // Wordmark: the logo glyph in the accent colour beside the name
            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: brand.implicitWidth + 12
                implicitHeight: 28

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surface_container_highest
                    opacity: logoMouse.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                RowLayout {
                    id: brand
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        text: "󰣇"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                        color: Theme.primary
                    }
                    Text {
                        text: "Catastrophic"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.letterSpacing: 0.4
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.run("~/.config/catastrophic/scripts/catastrophic-launcher")
                }
            }

            // Workspaces in a recessed track; one accent highlight glides to the
            // active one. Numbers are bright where windows are open, dim where not.
            Rectangle {
                id: wsTrack
                readonly property int cell: 24
                readonly property int pad: 2
                readonly property int activeIndex: (Hyprland.focusedWorkspace?.id ?? 1) - 1

                Layout.alignment: Qt.AlignVCenter
                implicitWidth: wsRow.implicitWidth + pad * 2
                implicitHeight: cell + pad * 2
                radius: height / 2
                color: Theme.surface_container

                // Glides to the active workspace: quick, no bounce and no blur,
                // so it lands with the switch rather than trailing behind it
                Rectangle {
                    x: wsTrack.pad + wsTrack.activeIndex * wsTrack.cell
                    y: wsTrack.pad
                    width: wsTrack.cell
                    height: wsTrack.cell
                    radius: width / 2
                    color: Theme.primary
                    visible: wsTrack.activeIndex >= 0 && wsTrack.activeIndex < bar.workspaceCount
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                Row {
                    id: wsRow
                    x: wsTrack.pad
                    y: wsTrack.pad

                    Repeater {
                        model: bar.workspaceCount

                        Item {
                            id: ws
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                            readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

                            width: wsTrack.cell
                            height: wsTrack.cell

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Theme.surface_container_highest
                                opacity: wsMouse.containsMouse && !ws.active ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: ws.wsId
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: ws.active || ws.occupied ? Font.Bold : Font.Normal
                                color: ws.active ? Theme.on_primary
                                    : ws.occupied ? Theme.on_surface : Theme.outline
                                opacity: ws.active || ws.occupied ? 1 : 0.6
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bar.focusWorkspace(String(ws.wsId))
                            }
                        }
                    }
                }
            }

            // Drop-down terminal (also Super+`)
            Icon {
                text: "󰆍"
                onClicked: bar.run("~/.config/catastrophic/scripts/catastrophic-dropdown")
            }
        }
    }

    // --- Centre: clock; hover or click opens the dashboard below it ---
    Island {
        id: center
        raised: false
        x: (bar.width - width) / 2
        y: Geometry.barMargin
        width: centerRow.implicitWidth + 32
        height: Geometry.barHeight

        // Soft highlight on hover, the only sign it opens something
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 4
            height: 30
            radius: height / 2
            color: Theme.surface_container_high
            opacity: centerHover.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        RowLayout {
            id: centerRow
            anchors.centerIn: parent
            spacing: 10

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
                color: Theme.primary
            }
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 4
                implicitHeight: 4
                radius: 2
                color: Theme.outline
            }
            Text {
                Layout.alignment: Qt.AlignVCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM")
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 13
                color: Theme.on_surface_variant
            }
        }

        // Same hover behaviour the old top border had: the dashboard stays
        // while the pointer is on the clock or on the dashboard itself
        HoverHandler {
            id: centerHover
            onPointChanged: if (hovered) DrawerState.topEdgeActivity()
            onHoveredChanged: {
                DrawerState.topEdgeInside = hovered
                if (hovered) DrawerState.topEdgeActivity()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => bar.run(m.button === Qt.RightButton
                ? "qs ipc call calendar toggle" : "qs ipc call dashboard toggle")
        }
    }

    // --- Right: tray and status, then power ---
    Island {
        id: right
        raised: false
        x: bar.width - width - Geometry.edgeMargin
        y: Geometry.barMargin
        width: rightRow.implicitWidth + 12
        height: Geometry.barHeight

        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

        RowLayout {
            id: rightRow
            anchors.verticalCenter: parent.verticalCenter
            x: 6
            spacing: 6

            // Privacy: a dot for each of mic, camera and screen sharing while in
            // use; hover for which apps. Hidden (and free) the rest of the time.
            BarGroup {
                id: privacy
                visible: Privacy.active
                spacing: 5
                color: privacyHover.hovered || bar.popoutKind === "privacy"
                    ? Theme.surface_container_highest : Theme.surface_container

                Repeater {
                    model: [
                        { on: Privacy.mic, glyph: "󰍬", tint: "#ffb74d" },
                        { on: Privacy.camera, glyph: "󰄀", tint: "#81c784" },
                        { on: Privacy.screen, glyph: "󰹑", tint: Theme.error }
                    ]
                    Text {
                        required property var modelData
                        visible: modelData.on
                        text: modelData.glyph
                        color: modelData.tint
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                }

                HoverHandler {
                    id: privacyHover
                    onPointChanged: if (hovered && bar.popoutKind !== "privacy") bar.openPopout("privacy", privacy)
                    onHoveredChanged: {
                        if (hovered) bar.openPopout("privacy", privacy)
                        else bar.closePopout()
                    }
                }
            }

            RowLayout {
                spacing: 2

                // System tray
                Repeater {
                    model: SystemTray.items

                    MouseArea {
                        id: trayItem
                        required property var modelData
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 28
                        implicitHeight: 28
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        // Hovering the network and Bluetooth applets opens their popouts
                        readonly property string popout: modelData.id === "nm-applet" ? "network"
                            : modelData.id === "blueman" ? "bluetooth" : ""
                        onPositionChanged: if (popout && bar.popoutKind !== popout) bar.openPopout(popout, trayItem)
                        onContainsMouseChanged: {
                            if (!popout) return
                            if (containsMouse) bar.openPopout(popout, trayItem)
                            else bar.closePopout()
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.surface_container_highest
                            opacity: trayItem.containsMouse || (trayItem.popout !== "" && bar.popoutKind === trayItem.popout) ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // nm-applet's symbolic icon renders blank, so draw a glyph
                        Text {
                            anchors.centerIn: parent
                            visible: trayItem.modelData.id === "nm-applet"
                            text: "󰤨"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: trayItem.containsMouse ? Theme.primary : Theme.on_surface_variant
                        }

                        Image {
                            visible: trayItem.modelData.id !== "nm-applet"
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: trayItem.modelData.icon
                            sourceSize: Qt.size(16, 16)
                            // One quiet colour for every tray icon
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: trayItem.containsMouse ? Theme.primary : Theme.on_surface_variant
                            }
                        }

                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !modelData.onlyMenu)
                                modelData.activate()
                            else if (modelData.hasMenu)
                                menu.open()
                        }

                        QsMenuAnchor {
                            id: menu
                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                        }
                    }
                }
            }

            BarDivider { visible: SystemTray.items.values.length > 0 }

            RowLayout {
                spacing: 2

                // Update warning: shown while the installed Catastrophic OS is behind GitHub, so
                // this system may be out of date. Click for the update notification.
                // catastrophic-update-check keeps ~/.local/state/catastrophic/update-status.
                Icon {
                    id: updateWarning
                    property bool outdated: false
                    visible: outdated
                    text: "󰀦"
                    color: "#ffb74d"
                    onClicked: bar.run("~/.config/catastrophic/scripts/catastrophic-update-check --prompt")

                    // The file changes only when the checker finds a new state, so this
                    // costs nothing while idle (no polling).
                    FileView {
                        path: Quickshell.env("HOME") + "/.local/state/catastrophic/update-status"
                        watchChanges: true
                        printErrors: false
                        onFileChanged: reload()
                        onLoaded: updateWarning.outdated = text().startsWith("outdated")
                        onLoadFailed: updateWarning.outdated = false
                    }
                }

                // Screen recording: red dot while recording, click to stop
                Icon {
                    id: rec
                    visible: Recorder.active
                    text: "󰑊"
                    color: Theme.error
                    onClicked: Recorder.stop()
                    // Slow pulse so it is noticed without being distracting
                    SequentialAnimation on opacity {
                        running: Recorder.active
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                    }
                }

                // Media: only while a player exists; hover for the player card
                Icon {
                    popout: "media"
                    visible: Mpris.players.values.length > 0
                    text: Mpris.players.values.some(p => p.isPlaying) ? "󰝚" : "󰝛"
                    onClicked: mouse => {
                        const p = Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0]
                        if (p) p.isPlaying = !p.isPlaying
                    }
                }

                // Volume: scroll to adjust, right click to mute, click for the mixer
                Icon {
                    id: volume
                    popout: "volume"
                    readonly property PwNode sink: Pipewire.defaultAudioSink
                    readonly property bool ready: !!(sink?.ready && sink?.audio)
                    readonly property real level: ready ? sink.audio.volume : 0
                    readonly property bool muted: ready ? sink.audio.muted : false

                    PwObjectTracker { objects: [volume.sink] }

                    text: muted || level === 0 ? "󰝟" : level < 0.34 ? "󰕿" : level < 0.67 ? "󰖀" : "󰕾"
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton && ready)
                            sink.audio.muted = !sink.audio.muted
                        else
                            bar.run("pavucontrol")
                    }
                    onScrolled: delta => {
                        if (ready)
                            sink.audio.volume = Math.max(0, Math.min(1, level + (delta > 0 ? 0.05 : -0.05)))
                    }
                }

                // Notifications: filled bell while any are held; right-click for Silent
                Icon {
                    id: bell
                    text: Notifs.dnd ? "󰂛" : Notifs.count > 0 ? "󰂚" : "󰂜"
                    color: Notifs.count > 0 && !Notifs.dnd ? Theme.primary
                        : hovered ? Theme.primary : Theme.on_surface_variant
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) Notifs.dnd = !Notifs.dnd
                        else Notifs.centerRequested()
                    }
                }
            }

            // Battery as a small chip with its percentage (hidden without one)
            BarGroup {
                id: battery
                readonly property var device: UPower.displayDevice
                readonly property int percent: device ? Math.round(device.percentage * 100) : 0
                readonly property bool low: UPower.onBattery && percent <= 15
                visible: device?.isLaptopBattery ?? false
                spacing: 3
                color: low ? Theme.error_container
                    : batteryHover.hovered || bar.popoutKind === "battery" ? Theme.surface_container_highest : Theme.surface_container

                Text {
                    text: !UPower.onBattery ? "󰂄"
                        : battery.percent >= 95 ? "󰁹"
                        : battery.percent < 5 ? "󰂎"
                        : String.fromCodePoint(0xF007A + Math.max(0, Math.min(8, Math.round(battery.percent / 10) - 1)))
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: battery.low ? Theme.on_error_container : Theme.primary
                }
                Text {
                    text: battery.percent + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: battery.low ? Theme.on_error_container : Theme.on_surface
                }

                HoverHandler {
                    id: batteryHover
                    onPointChanged: if (hovered && bar.popoutKind !== "battery") bar.openPopout("battery", battery)
                    onHoveredChanged: {
                        if (hovered) bar.openPopout("battery", battery)
                        else bar.closePopout()
                    }
                }
            }

            // Power: filled circle at the end of the island
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: powerMouse.containsMouse ? Theme.error : Theme.surface_container_highest
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: powerMouse.containsMouse ? Theme.on_error : Theme.on_surface_variant
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.run("qs ipc call session toggle")
                }
            }
        }
    }
}
