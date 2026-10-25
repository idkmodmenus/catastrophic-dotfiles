import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Vertical bar: launcher and workspaces at the top, status and clock at the bottom.
Item {
    id: bar

    // At least 5 dots, growing to reach the highest workspace in use (1-10 have keybinds)
    readonly property int workspaceCount: Math.max(5,
        Hyprland.focusedWorkspace?.id ?? 0,
        ...Hyprland.workspaces.values.map(w => w.id))

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
        signal clicked(var mouse)
        signal scrolled(int delta)

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 28
        implicitHeight: 28

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
                    implicitWidth: 18
                    implicitHeight: dot.height + 4

                    Rectangle {
                        id: dot
                        anchors.centerIn: parent
                        width: 8
                        height: ws.active ? 24 : 8
                        radius: 4
                        color: ws.active ? Theme.primary : Theme.on_surface_variant
                        opacity: ws.active ? 1 : ws.occupied ? 0.8 : 0.3

                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    Image {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: trayItem.modelData.icon
                        sourceSize: Qt.size(16, 16)
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

            // Volume: scroll to adjust, right click to mute, click for the mixer
            Icon {
                id: volume
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

            // Notifications: filled bell while any are pending
            Icon {
                id: bell
                property bool pending: false
                text: pending ? "󰂚" : "󰂜"
                onClicked: bar.run("swaync-client -t -sw")

                // Reconnects if swaync restarts, which ends the subscription
                Process {
                    id: bellWatch
                    command: ["swaync-client", "-swb"]
                    running: true
                    onExited: bellRetry.start()
                    stdout: SplitParser {
                        onRead: data => {
                            try { bell.pending = parseInt(JSON.parse(data).text) > 0 } catch (e) {}
                        }
                    }
                }

                Timer {
                    id: bellRetry
                    interval: 3000
                    onTriggered: bellWatch.running = true
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
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    color: modelData === "HH" ? Theme.primary : Theme.on_surface
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
            onClicked: bar.run("catastrophic-powermenu toggle")
        }
    }
}
