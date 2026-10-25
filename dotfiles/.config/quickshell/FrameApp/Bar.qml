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

// Vertical bar: launcher and workspaces at the top, status and clock at the bottom.
Item {
    id: bar

    // At least 5 dots, growing to reach the highest workspace in use (1-10 have keybinds)
    readonly property int workspaceCount: Math.max(5,
        Hyprland.focusedWorkspace?.id ?? 0,
        ...Hyprland.workspaces.values.map(w => w.id))

    // Hover popouts: which one is open and the bar-relative height of its icon.
    // Closing is delayed so the pointer can cross from the icon into the panel.
    property string popoutKind: ""
    property real popoutY: 0
    property bool popoutHovered: false

    function openPopout(kind: string, item: Item): void {
        popoutCloser.stop()
        popoutY = item.mapToItem(bar, 0, item.height / 2).y
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

    // Scrolling anywhere on the bar switches workspaces
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => bar.focusWorkspace(event.angleDelta.y > 0 ? "e-1" : "e+1")
    }

    // Icon button with a soft round highlight on hover
    component Icon: Item {
        id: icon
        property alias text: label.text
        property alias color: label.color
        property alias font: label.font
        readonly property bool hovered: mouse.containsMouse
        property string popout: ""
        signal clicked(var mouse)
        signal scrolled(int delta)

        Layout.alignment: Qt.AlignHCenter
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
            opacity: icon.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            id: label
            anchors.centerIn: parent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: icon.hovered ? Theme.primary : Theme.on_surface_variant
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

    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Icon {
            implicitWidth: 34
            implicitHeight: 34
            text: "󰣇"
            font.pixelSize: 20
            color: Theme.primary
            onClicked: bar.run("~/.config/catastrophic/scripts/catastrophic-launcher")
        }

        // Workspaces: the active one stretches into a pill
        BarGroup {
            Repeater {
                model: bar.workspaceCount

                Item {
                    id: ws
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool active: Hyprland.focusedWorkspace?.id === wsId
                    readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 22
                    implicitHeight: dot.height + 2

                    Rectangle {
                        id: dot
                        anchors.centerIn: parent
                        width: ws.active ? 22 : ws.occupied ? 8 : 6
                        height: ws.active ? 30 : width
                        radius: width / 2
                        color: ws.active ? Theme.primary
                            : ws.occupied ? Theme.on_surface_variant : Theme.outline_variant

                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: ws.wsId
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.on_primary
                            opacity: ws.active ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.focusWorkspace(String(ws.wsId))
                    }
                }
            }
        }
    }

    // Name of the setup, written upwards along the middle of the bar
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        rotation: -90
        text: "Catastrophic"
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.letterSpacing: 1.5
        color: Theme.on_surface_variant
        opacity: 0.7
    }

    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        BarGroup {
            // System tray
            Repeater {
                model: SystemTray.items

                MouseArea {
                    id: trayItem
                    required property var modelData
                    Layout.alignment: Qt.AlignHCenter
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
                        anchor.edges: Edges.Right
                        anchor.gravity: Edges.Right
                    }
                }
            }

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

            // Battery (hidden on machines without one)
            Icon {
                popout: "battery"
                readonly property var device: UPower.displayDevice
                readonly property int percent: device ? Math.round(device.percentage * 100) : 0
                visible: device?.isLaptopBattery ?? false
                text: !UPower.onBattery ? "󰂄"
                    : percent >= 95 ? "󰁹"
                    : percent < 5 ? "󰂎"
                    : String.fromCodePoint(0xF007A + Math.max(0, Math.min(8, Math.round(percent / 10) - 1)))
                color: UPower.onBattery && percent <= 15 ? Theme.error
                    : hovered ? Theme.primary : Theme.on_surface_variant
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

        // Clock, stacked hours over minutes; click for the calendar
        BarGroup {
            id: clockSection
            SystemClock { id: clock; precision: SystemClock.Minutes }

            Repeater {
                model: ["HH", "mm"]
                Text {
                    required property string modelData
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: modelData === "mm" ? -8 : 0
                    text: Qt.formatDateTime(clock.date, modelData)
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: modelData === "HH" ? Theme.primary : Theme.on_surface
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                implicitWidth: 10
                implicitHeight: 2
                radius: 1
                color: Theme.outline_variant
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: Theme.on_surface_variant
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: -6
                text: Qt.formatDateTime(clock.date, "d")
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Theme.on_surface
            }

            HoverHandler {
                parent: clockSection
                onPointChanged: if (hovered && bar.popoutKind !== "clock") bar.openPopout("clock", clockSection)
                onHoveredChanged: {
                    if (hovered) bar.openPopout("clock", clockSection)
                    else bar.closePopout()
                }
            }

            MouseArea {
                parent: clockSection
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.run("qs ipc call calendar toggle")
            }
        }

        Icon {
            implicitWidth: 34
            implicitHeight: 34
            text: "󰐥"
            color: hovered ? Theme.error : Theme.on_surface_variant
            onClicked: bar.run("qs ipc call session toggle")
        }
    }
}
