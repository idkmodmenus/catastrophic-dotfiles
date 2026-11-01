import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Session menu on the right edge: lock, log out, sleep, restart, shut down.
// Arrow keys or letters select a tile and Enter confirms.
Scope {
    id: root

    property alias open: win.open

    readonly property var actions: [
        { glyph: "󰌾", label: "Lock",      key: "L", flag: "--lock",     danger: false },
        { glyph: "󰍃", label: "Log out",   key: "O", flag: "--logout",   danger: false },
        { glyph: "󰤄", label: "Sleep",     key: "S", flag: "--suspend",  danger: false },
        { glyph: "󰜉", label: "Restart",   key: "R", flag: "--reboot",   danger: true },
        { glyph: "󰐥", label: "Shut down", key: "P", flag: "--poweroff", danger: true }
    ]

    function run(i: int): void {
        win.open = false
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-power", actions[i].flag])
    }

    IpcHandler {
        target: "session"
        function toggle(): void { win.open = !win.open }
        function open(): void { win.open = true }
        function close(): void { win.open = false }
    }

    DrawerWindow {
        id: win
        edge: "right"
        padding: 16

        onOpenChanged: {
            if (open) {
                column.current = 0
                focusTimer.restart()
            }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: column.forceActiveFocus() }

        FocusScope {
            id: column
            property int current: 0

            implicitWidth: 92
            implicitHeight: col.implicitHeight
            width: implicitWidth
            height: implicitHeight

            Keys.onUpPressed: current = (current + root.actions.length - 1) % root.actions.length
            Keys.onDownPressed: current = (current + 1) % root.actions.length
            Keys.onReturnPressed: root.run(current)
            Keys.onEnterPressed: root.run(current)
            // Letters jump to a tile; Enter confirms, so a stray key never
            // restarts or powers off the machine
            Keys.onPressed: event => {
                const k = event.text.toUpperCase()
                const i = root.actions.findIndex(a => a.key === k)
                if (i >= 0) current = i
            }

            ColumnLayout {
                id: col
                spacing: 10

                Repeater {
                    model: root.actions

                    Rectangle {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool current: column.current === index
                        readonly property color tone: modelData.danger ? Theme.error : Theme.primary

                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 92
                        radius: current ? 28 : 22
                        color: current ? (modelData.danger ? Theme.error_container : Theme.primary_container)
                            : Theme.surface_container
                        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.glyph
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 28
                                color: tile.current
                                    ? (tile.modelData.danger ? Theme.on_error_container : Theme.on_primary_container)
                                    : tile.tone
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: tile.modelData.label
                                font.family: Theme.fontFamilyRegular
                                font.pixelSize: 11
                                                                color: tile.current
                                    ? (tile.modelData.danger ? Theme.on_error_container : Theme.on_primary_container)
                                    : Theme.on_surface_variant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: column.current = tile.index
                            onClicked: root.run(tile.index)
                        }
                    }
                }
            }
        }
    }
}
