import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.CustomTheme
import qs.Widgets

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

    property double closedAt: 0
    Connections {
        target: DrawerState
        function onTopEdgeActivity() {
            if (win.open || Date.now() - root.closedAt < 700) return
            root.hoverOpened = true
            win.open = true
        }
    }

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
        modal: !root.hoverOpened

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

            Card {
                id: about
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 250
                implicitWidth: 250
                implicitHeight: 168 + 12 + 44

                property string version: ""
                property bool outdated: false
                property string updateSummary: ""
                property var changes: []

                FileView {
                    path: root.home + "/.config/catastrophic/version.json"
                    watchChanges: true
                    printErrors: false
                    onFileChanged: reload()
                    onLoaded: { try { about.version = JSON.parse(text()).Version ?? "" } catch (e) {} }
                }
                FileView {
                    path: root.home + "/.local/state/catastrophic/update-status"
                    watchChanges: true
                    printErrors: false
                    onFileChanged: reload()
                    onLoaded: {
                        const lines = text().split("\n")
                        about.outdated = lines[0] === "outdated"
                        about.updateSummary = lines[2] ?? ""
                    }
                    onLoadFailed: about.outdated = false
                }
                FileView {
                    path: root.home + "/.config/catastrophic/changelog.json"
                    watchChanges: true
                    printErrors: false
                    onFileChanged: reload()
                    onLoaded: { try { about.changes = JSON.parse(text()) } catch (e) { about.changes = [] } }
                }

                ColumnLayout {
                    width: about.width - about.padding * 2
                    height: about.height - about.padding * 2
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Image {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            source: Qt.resolvedUrl("../FrameApp/logo.svg")
                            sourceSize: Qt.size(92, 92)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: Theme.primary
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: "Catastrophic Shell"
                                font.family: Theme.fontFamily
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                                color: Theme.on_surface
                            }
                            Text {
                                text: about.version ? "Version " + about.version : "Version unknown"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: Theme.on_surface_variant
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 10
                        color: about.outdated
                            ? (updateMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
                            : Theme.surface_container_high
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8
                            Text {
                                text: about.outdated ? "󰚰" : "󰄬"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: about.outdated ? Theme.on_primary : Theme.primary
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: about.outdated ? "Update available" : "Up to date"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: about.outdated ? Theme.on_primary : Theme.on_surface
                            }
                        }
                        MouseArea {
                            id: updateMouse
                            anchors.fill: parent
                            enabled: about.outdated
                            hoverEnabled: true
                            cursorShape: about.outdated ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: Quickshell.execDetached([root.home + "/.config/catastrophic/scripts/catastrophic-update-check", "--prompt"])
                        }
                    }

                    Text {
                        text: "What's new"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                        color: Theme.on_surface_variant
                    }
                    Flickable {
                        id: notes
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: notesCol.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Connections {
                            target: win
                            function onOpenChanged() { if (win.open) notes.contentY = 0 }
                        }

                        ColumnLayout {
                            id: notesCol
                            width: notes.width
                            spacing: 10

                            Repeater {
                                model: about.changes

                                ColumnLayout {
                                    id: release
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 3

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Text {
                                            text: release.modelData.version
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                            color: Theme.primary
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: release.modelData.title ?? ""
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            color: Theme.on_surface
                                        }
                                    }
                                    Repeater {
                                        model: release.modelData.notes ?? []
                                        Text {
                                            required property string modelData
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            text: "•  " + modelData
                                            font.family: Theme.fontFamilyRegular
                                            font.pixelSize: 12
                                            lineHeight: 1.1
                                            color: Theme.on_surface_variant
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            parent: notes
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 22
                            visible: notes.contentY + notes.height < notes.contentHeight - 1
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.alpha(Theme.surface_container, 0) }
                                GradientStop { position: 1.0; color: Theme.surface_container }
                            }
                        }
                    }
                }
            }

            Card {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 7 * 34 + 28
                implicitHeight: Math.max(168 + 12 + 44, calGrid.implicitHeight + padding * 2)

                CalendarGrid { id: calGrid; cell: 34 }
            }

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
}
