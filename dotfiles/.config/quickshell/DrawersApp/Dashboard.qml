import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme
import qs.Widgets

// Top drawer: clock and weather, calendar, media and system load. Opens on
// the keybinding or by resting the pointer on the top edge.
Scope {
    id: root

    property alias open: win.open
    readonly property string home: Quickshell.env("HOME")

    IpcHandler {
        target: "dashboard"
        function toggle(): void { root.hoverOpened = false; win.open = !win.open }
        function open(): void { root.hoverOpened = false; win.open = true }
        function close(): void { win.open = false }
    }

    // Touching the frame's top border opens the dashboard. A short cooldown after
    // it closes stops it reopening while the pointer is still on the border.
    property double closedAt: 0
    Connections {
        target: DrawerState
        function onTopEdgeActivity() {
            if (win.open || Date.now() - root.closedAt < 700) return
            root.hoverOpened = true
            win.open = true
        }
    }

    // A pointer that stops moving sends no events, so while the panel is open
    // from a hover its real position is read from Hyprland and compared with
    // the panel's area.
    property bool polledInside: false
    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/(-?\d+),\s*(-?\d+)/)
                if (!m || !win.screen) return
                const px = parseInt(m[1]) - win.screen.x
                const py = parseInt(m[2]) - win.screen.y
                const r = win.panel.hit
                const l = win.panel.x + r.x
                const t = win.panel.y + r.y
                root.polledInside = px >= l && px <= l + r.width && py >= t && py <= t + r.height
            }
        }
    }
    Timer {
        interval: 300
        repeat: true
        running: win.open && root.hoverOpened
        onTriggered: cursorProc.running = true
    }
    Connections {
        target: win
        function onOpenChanged() { root.polledInside = false }
    }

    DrawerWindow {
        id: win
        edge: "top"
        padding: 18
        // Opened by hover it just stays while the pointer is on it; opened from
        // the keybinding it behaves like a menu (Escape or a click away closes it)
        modal: !root.hoverOpened

        // A hover-opened panel closes once the pointer has left both it and the
        // frame's top border, or if the pointer never reaches it
        property bool entered: false
        readonly property bool pointerHere: panelHovered || DrawerState.topEdgeInside || root.polledInside
        onPanelHoveredChanged: if (panelHovered) entered = true
        onOpenChanged: if (open) entered = false
        Timer {
            interval: win.entered ? 600 : 3000
            running: win.open && root.hoverOpened && !win.pointerHere
            onTriggered: win.open = false
        }

        RowLayout {
            spacing: 14

            // --- Clock, weather, quick actions ---
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 230
                spacing: 12

                SystemClock { id: clock; precision: SystemClock.Minutes }

                Card {
                    Layout.fillWidth: true
                    implicitHeight: 168

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        Text {
                            text: Qt.formatDateTime(clock.date, "HH:mm")
                            font.family: Theme.fontFamily
                            font.pixelSize: 54
                            font.weight: Font.DemiBold
                            color: Theme.primary
                        }
                        Text {
                            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_surface
                        }
                        Item { Layout.fillHeight: true }
                        Text {
                            id: weatherText
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: weather.line
                            font.family: Theme.fontFamilyRegular
                            font.pixelSize: 13
                            color: Theme.on_surface_variant
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    component Action: Rectangle {
                        id: act
                        property string glyph
                        property string label
                        signal clicked()
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: 16
                        color: area.containsMouse ? Theme.secondary_container : Theme.surface_container
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: act.glyph
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 17
                                color: Theme.primary
                            }
                            Text {
                                text: act.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Theme.on_surface
                            }
                        }
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: act.clicked()
                        }
                    }

                    Action {
                        glyph: "󰸉"
                        label: "Wallpaper"
                        onClicked: Quickshell.execDetached([root.home + "/.config/catastrophic/scripts/catastrophic-wallpaper-app", "--random"])
                    }
                    Action {
                        glyph: "󰔎"
                        label: "Theme"
                        onClicked: Quickshell.execDetached([root.home + "/.config/catastrophic/scripts/catastrophic-toggle-theme"])
                    }
                }
            }

            // --- Calendar ---
            Card {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 7 * 34 + 28
                implicitHeight: 168 + 12 + 44

                CalendarGrid { cell: 34 }
            }

            // --- Media and system load ---
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 300
                spacing: 12

                MediaCard { Layout.fillWidth: true }

                Card {
                    Layout.fillWidth: true
                    implicitHeight: 100

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 9

                        component Meter: RowLayout {
                            property string label
                            property real value
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                Layout.preferredWidth: 34
                                text: parent.label
                                font.family: Theme.fontFamilyRegular
                                font.pixelSize: 12
                                                                color: Theme.on_surface_variant
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 8
                                radius: 4
                                color: Theme.surface_container_highest
                                Rectangle {
                                    width: Math.max(8, parent.width * parent.parent.value)
                                    height: parent.height
                                    radius: 4
                                    color: parent.parent.value > 0.85 ? Theme.error : Theme.primary
                                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                }
                            }
                            Text {
                                Layout.preferredWidth: 36
                                horizontalAlignment: Text.AlignRight
                                text: Math.round(parent.value * 100) + "%"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.on_surface
                            }
                        }

                        Meter { label: "CPU"; value: perf.cpu }
                        Meter { label: "RAM"; value: perf.mem }
                        Meter { label: "Disk"; value: perf.disk }
                    }
                }
            }
        }
    }

    // Whether the last opening came from hovering (those close on leave)
    property bool hoverOpened: false
    Connections {
        target: win
        function onOpenChanged() {
            if (!win.open) {
                root.hoverOpened = false
                root.closedAt = Date.now()
            }
        }
    }

    // --- Data sources ---
    QtObject {
        id: perf
        property real cpu: 0
        property real mem: 0
        property real disk: 0
        property var last: null
    }

    FileView { id: statFile; path: "/proc/stat"; blockLoading: true }
    FileView { id: memFile; path: "/proc/meminfo"; blockLoading: true }

    Process {
        id: diskProc
        command: ["bash", "-c", "df --output=pcent / | tail -1 | tr -dc 0-9"]
        stdout: StdioCollector {
            onStreamFinished: perf.disk = (parseInt(text) || 0) / 100
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: win.open
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
            const c = statFile.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const idle = c[3] + c[4]
            const total = c.reduce((a, b) => a + b, 0)
            if (perf.last) {
                const dt = total - perf.last.total
                if (dt > 0) perf.cpu = 1 - (idle - perf.last.idle) / dt
            }
            perf.last = { idle: idle, total: total }

            const m = memFile.text()
            const get = k => parseInt(m.match(new RegExp(k + ":\\s+(\\d+)"))[1])
            perf.mem = 1 - get("MemAvailable") / get("MemTotal")
            diskProc.running = true
        }
    }

    // Weather from wttr.in: icon, temperature and conditions
    QtObject {
        id: weather
        property string line: "Weather unavailable"
        property double fetched: 0
    }

    Process {
        id: weatherProc
        command: ["curl", "-sf", "--max-time", "6", "wttr.in/?format=%c+%t+%C"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t) weather.line = t
            }
        }
    }

    Connections {
        target: win
        function onOpenChanged() {
            if (win.open && Date.now() - weather.fetched > 30 * 60 * 1000) {
                weather.fetched = Date.now()
                weatherProc.running = true
            }
        }
    }
}
