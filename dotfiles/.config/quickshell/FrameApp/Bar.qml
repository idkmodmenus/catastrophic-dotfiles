import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.CustomTheme
import qs.DrawersApp
import qs.Widgets

Item {
    id: bar

    readonly property alias leftIsland: left
    readonly property alias centerIsland: center
    readonly property alias rightIsland: right

    readonly property string mono: "JetBrainsMono Nerd Font"

    readonly property var hiddenTray: ["nm-applet", "blueman"]

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function fmtTime(sec: real): string {
        const s = Math.max(0, Math.floor(sec))
        return Math.floor(s / 60).toString().padStart(2, "0") + ":" + (s % 60).toString().padStart(2, "0")
    }

    readonly property int workspaceCount: Math.max(5,
        Hyprland.focusedWorkspace?.id ?? 0,
        ...Hyprland.workspaces.values.map(w => w.id))

    property string popoutKind: ""
    property real popoutX: 0
    property bool popoutHovered: false

    function openPopout(kind: string, item: Item): void {
        popoutCloser.stop()
        popoutX = item.mapToItem(bar, item.width / 2, 0).x
        popoutKind = kind
    }
    function closePopout(kind: string): void {
        if (kind === popoutKind) popoutCloser.restart()
    }

    Timer {
        id: popoutCloser
        interval: 350
        onTriggered: if (!bar.popoutHovered) bar.popoutKind = ""
    }
    onPopoutHoveredChanged: if (!popoutHovered) closePopout(popoutKind)

    function run(cmd: string): void {
        Quickshell.execDetached(["bash", "-c", cmd])
    }

    function focusWorkspace(target: string): void {
        if (Hyprland.usingLua)
            Hyprland.dispatch("hl.dsp.focus({workspace = '" + target + "'})")
        else
            Hyprland.dispatch("workspace " + target)
    }

    component Icon: Item {
        id: icon
        property alias text: label.text
        property alias color: label.color
        property alias font: label.font
        readonly property bool hovered: mouse.containsMouse
        property string popout: ""
        readonly property bool lit: hovered || (popout !== "" && bar.popoutKind === popout)
        signal clicked(var mouse)
        signal scrolled(int delta)

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 30
        implicitHeight: 30

        onHoveredChanged: {
            if (!popout) return
            if (hovered) bar.openPopout(popout, icon)
            else bar.closePopout(popout)
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
            font.family: bar.mono
            font.pixelSize: 17
            color: icon.lit ? Theme.primary : Theme.on_surface
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

    Island {
        id: left
        x: Geometry.edgeMargin
        y: Geometry.barMargin
        width: leftRow.implicitWidth + 20
        height: Geometry.barHeight

        Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => bar.focusWorkspace(event.angleDelta.y > 0 ? "e-1" : "e+1")
        }

        RowLayout {
            id: leftRow
            anchors.verticalCenter: parent.verticalCenter
            x: 10
            spacing: 6

            Item {
                id: logo
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 30
                implicitHeight: 30

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Theme.surface_container_highest
                    opacity: logoMouse.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: Qt.resolvedUrl("logo.svg")
                    sourceSize: Qt.size(48, 48)
                    smooth: true
                    scale: logoMouse.pressed ? 0.88 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: Theme.primary
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

            Item {
                id: wsTrack
                readonly property int cell: 22

                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4
                Layout.rightMargin: 2
                implicitWidth: bar.workspaceCount * cell
                implicitHeight: 30

                readonly property int activeIndex: Math.max(0, (Hyprland.focusedWorkspace?.id ?? 1) - 1)
                property real leftEdge: activeIndex * cell
                property real rightEdge: (activeIndex + 1) * cell
                property bool goingRight: true
                onActiveIndexChanged: {
                    goingRight = activeIndex * cell > leftEdge
                    leftEdge = activeIndex * cell
                    rightEdge = (activeIndex + 1) * cell
                }
                Behavior on leftEdge { NumberAnimation { duration: wsTrack.goingRight ? 380 : 260; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
                Behavior on rightEdge { NumberAnimation { duration: wsTrack.goingRight ? 260 : 380; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: wsTrack.leftEdge + 1
                    width: wsTrack.rightEdge - wsTrack.leftEdge - 2
                    height: 26
                    radius: 13
                    color: Qt.alpha(Theme.primary, 0.18)
                    visible: Hyprland.focusedWorkspace?.id <= bar.workspaceCount
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: bar.workspaceCount

                        Item {
                            id: ws
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                            readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

                            width: wsTrack.cell
                            height: 26

                            Rectangle {
                                anchors.centerIn: parent
                                visible: !ws.active && !ws.occupied
                                width: wsMouse.containsMouse ? 8 : 5
                                height: width
                                radius: width / 2
                                color: wsMouse.containsMouse ? Theme.primary : Theme.on_surface
                                opacity: wsMouse.containsMouse ? 1 : 0.45
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: ws.active || ws.occupied
                                text: ws.active ? "\u{F011B}" : "\u{F03E9}"
                                font.family: bar.mono
                                font.pixelSize: 20
                                scale: ws.active ? 1 : 0.75
                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2 } }
                                color: ws.active || wsMouse.containsMouse ? Theme.primary : Theme.on_surface
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

            BarDivider {}

            Icon {
                text: "󰆍"
                onClicked: bar.run("~/.config/catastrophic/scripts/catastrophic-dropdown")
            }

            BarPill {
                id: nowPlaying
                bar: bar
                visible: bar.player !== null
                popout: "media"
                padding: 4
                spacing: 7
                onClicked: if (bar.player) bar.player.togglePlaying()

                Timer {
                    running: nowPlaying.visible && (bar.player?.isPlaying ?? false)
                    interval: 1000
                    repeat: true
                    onTriggered: bar.player?.positionChanged()
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 6
                    color: Theme.surface_container_highest
                    clip: true

                    Image {
                        id: cover
                        anchors.fill: parent
                        source: bar.player?.trackArtUrl ?? ""
                        sourceSize: Qt.size(48, 48)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: cover.status !== Image.Ready
                        text: "󰝚"
                        font.family: bar.mono
                        font.pixelSize: 12
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -2

                    Text {
                        Layout.maximumWidth: 180
                        text: bar.player?.trackTitle || "Unknown"
                        elide: Text.ElideRight
                        font.family: bar.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: nowPlaying.lit ? Theme.primary : Theme.on_surface
                    }
                    Text {
                        Layout.maximumWidth: 180
                        text: bar.player && bar.player.lengthSupported && bar.player.length > 0
                            ? bar.fmtTime(bar.player.position) + " / " + bar.fmtTime(bar.player.length)
                            : (bar.player?.trackArtist ?? "")
                        elide: Text.ElideRight
                        font.family: bar.mono
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }
                }
            }
        }
    }

    Island {
        id: center
        x: (bar.width - width) / 2
        y: Geometry.barMargin
        width: centerContent.implicitWidth + 16
        height: Geometry.barHeight

        Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }

        SystemClock { id: clock; precision: SystemClock.Seconds }

        RowLayout {
            id: centerContent
            anchors.centerIn: parent
            spacing: 6

            Item {
                id: clockArea
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: clockRow.implicitWidth + 24
                implicitHeight: Geometry.barHeight - 10

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surface_container_high
                    opacity: clockHover.hovered ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                RowLayout {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                        font.family: bar.mono
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 6
                        visible: Weather.ready
                        text: Weather.glyph
                        font.family: bar.mono
                        font.pixelSize: 17
                        color: Theme.on_surface
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        visible: Weather.ready
                        text: Weather.temperature
                        font.family: bar.mono
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: Theme.on_surface
                    }
                }

                HoverHandler {
                    id: clockHover
                    onHoveredChanged: {
                        DrawerState.topEdgeInside = hovered
                        if (hovered) clockDwell.restart()
                        else clockDwell.stop()
                    }
                }
                Timer {
                    id: clockDwell
                    interval: 250
                    onTriggered: if (clockHover.hovered) DrawerState.topEdgeActivity()
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: m => bar.run(m.button === Qt.RightButton
                        ? "qs ipc call calendar toggle" : "qs ipc call dashboard toggle")
                }
            }

            BarDivider { visible: barApps.visible }

            BarApps {
                id: barApps
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 2
            }
        }
    }

    Island {
        id: right
        x: bar.width - width - Geometry.edgeMargin
        y: Geometry.barMargin
        width: rightRow.implicitWidth + 20
        height: Geometry.barHeight

        Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }

        RowLayout {
            id: rightRow
            anchors.verticalCenter: parent.verticalCenter
            x: 10
            spacing: 6

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
                        font.family: bar.mono
                        font.pixelSize: 14
                    }
                }

                HoverHandler {
                    id: privacyHover
                    onPointChanged: if (hovered && bar.popoutKind !== "privacy") bar.openPopout("privacy", privacy)
                    onHoveredChanged: {
                        if (hovered) bar.openPopout("privacy", privacy)
                        else bar.closePopout("privacy")
                    }
                }
            }

            RowLayout {
                spacing: 2

                Repeater {
                    model: SystemTray.items

                    MouseArea {
                        id: trayItem
                        required property var modelData
                        visible: !bar.hiddenTray.includes(modelData.id)
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 28
                        implicitHeight: 28
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.surface_container_highest
                            opacity: trayItem.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: trayItem.modelData.icon
                            sourceSize: Qt.size(36, 36)
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: trayItem.containsMouse ? Theme.primary : Theme.on_surface
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

            BarDivider { visible: SystemTray.items.values.some(i => !bar.hiddenTray.includes(i.id)) }

            Icon {
                id: updateWarning
                property bool outdated: false
                visible: outdated
                text: "󰀦"
                color: "#ffb74d"
                onClicked: bar.run("~/.config/catastrophic/scripts/catastrophic-update-check --prompt")

                FileView {
                    path: Quickshell.env("HOME") + "/.local/state/catastrophic/update-status"
                    watchChanges: true
                    printErrors: false
                    onFileChanged: reload()
                    onLoaded: updateWarning.outdated = text().startsWith("outdated")
                    onLoadFailed: updateWarning.outdated = false
                }
            }

            Icon {
                id: rec
                visible: Recorder.active
                text: "󰑊"
                color: Theme.error
                onClicked: Recorder.stop()
                SequentialAnimation on opacity {
                    running: Recorder.active
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                }
            }

            RowLayout {
                spacing: 4

                BarPill {
                    id: layoutPill
                    bar: bar
                    padding: 6
                    property string layout: ""
                    property bool several: false
                    function abbrev(name: string): string {
                        return name.replace(/[^A-Za-z]/g, "").slice(0, 2).toUpperCase()
                    }
                    visible: layout !== "" && several
                    color: lit ? Theme.surface_container_highest : Theme.surface_container
                    onClicked: bar.run("hyprctl switchxkblayout main next")

                    Text {
                        text: layoutPill.layout
                        font.family: bar.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: layoutPill.lit ? Theme.primary : Theme.on_surface
                    }

                    Process {
                        running: true
                        command: ["hyprctl", "devices", "-j"]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                try {
                                    const kb = JSON.parse(text).keyboards.find(k => k.main)
                                    if (!kb) return
                                    layoutPill.several = `${kb.layout}`.includes(",")
                                    layoutPill.layout = layoutPill.abbrev(kb.active_keymap)
                                } catch (e) {}
                            }
                        }
                    }
                    Connections {
                        target: Hyprland
                        function onRawEvent(event) {
                            if (event.name === "activelayout")
                                layoutPill.layout = layoutPill.abbrev(event.data.split(",").pop())
                        }
                    }
                }

                BarPill {
                    id: wifiPill
                    bar: bar
                    popout: "network"
                    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
                    readonly property var network: wifi ? wifi.networks.values.find(n => n.connected) ?? null : null
                    readonly property real strength: network?.signalStrength ?? 0
                    visible: wifi !== null
                    filled: network !== null
                    onClicked: bar.run("nm-connection-editor")

                    Text {
                        text: !Networking.wifiEnabled ? "󰤮"
                            : !wifiPill.network ? "󰤯"
                            : wifiPill.strength > 0.75 ? "󰤨" : wifiPill.strength > 0.5 ? "󰤥"
                            : wifiPill.strength > 0.25 ? "󰤢" : "󰤟"
                        font.family: bar.mono
                        font.pixelSize: 15
                        color: wifiPill.ink
                    }
                    Text {
                        Layout.maximumWidth: 120
                        text: !Networking.wifiEnabled ? "Off" : wifiPill.network?.name || "Offline"
                        elide: Text.ElideRight
                        font.family: bar.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: wifiPill.ink
                    }
                }

                BarPill {
                    id: btPill
                    bar: bar
                    popout: "bluetooth"
                    readonly property var adapter: Bluetooth.defaultAdapter
                    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
                    visible: adapter !== null
                    spacing: 4
                    onClicked: if (adapter) adapter.enabled = !adapter.enabled

                    Text {
                        text: !btPill.adapter?.enabled ? "󰂲" : btPill.connected.length > 0 ? "󰂱" : "󰂯"
                        font.family: bar.mono
                        font.pixelSize: 15
                        color: btPill.ink
                    }
                    Text {
                        Layout.maximumWidth: 100
                        text: !btPill.adapter?.enabled ? "Off"
                            : btPill.connected.length > 0 ? btPill.connected[0].name : "On"
                        elide: Text.ElideRight
                        font.family: bar.mono
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: btPill.ink
                    }
                }

                BarPill {
                    id: volume
                    bar: bar
                    popout: "volume"
                    filled: !muted
                    padding: 6
                    readonly property PwNode sink: Pipewire.defaultAudioSink
                    readonly property bool ready: !!(sink?.ready && sink?.audio)
                    readonly property real level: ready ? sink.audio.volume : 0
                    readonly property bool muted: ready ? sink.audio.muted : false

                    PwObjectTracker { objects: [volume.sink] }

                    Text {
                        Layout.preferredWidth: 18
                        horizontalAlignment: Text.AlignHCenter
                        text: volume.muted || volume.level === 0 ? "󰝟"
                            : volume.level < 0.34 ? "󰕿" : volume.level < 0.67 ? "󰖀" : "󰕾"
                        font.family: bar.mono
                        font.pixelSize: 15
                        color: volume.ink
                    }
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

                Icon {
                    id: bell
                    text: Notifs.dnd ? "󰂛" : Notifs.count > 0 ? "󰂚" : "󰂜"
                    color: hovered || (Notifs.count > 0 && !Notifs.dnd) ? Theme.primary : Theme.on_surface
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) Notifs.dnd = !Notifs.dnd
                        else Notifs.centerRequested()
                    }
                }
            }

            BarPill {
                id: battery
                bar: bar
                popout: "battery"
                readonly property var device: UPower.displayDevice
                readonly property int percent: device ? Math.round(device.percentage * 100) : 0
                readonly property bool low: UPower.onBattery && percent <= 15
                readonly property color fg: low ? Theme.on_error : Theme.surface
                visible: device?.isLaptopBattery ?? false
                filled: true
                fill: low ? Theme.error : Theme.on_surface
                spacing: 3

                Text {
                    visible: !UPower.onBattery
                    text: "󰚥"
                    font.family: bar.mono
                    font.pixelSize: 15
                    color: battery.fg
                }
                Text {
                    text: battery.percent + "%"
                    font.family: bar.mono
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: battery.fg
                }
            }

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
                    font.family: bar.mono
                    font.pixelSize: 15
                    color: powerMouse.containsMouse ? Theme.on_error : Theme.on_surface
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
