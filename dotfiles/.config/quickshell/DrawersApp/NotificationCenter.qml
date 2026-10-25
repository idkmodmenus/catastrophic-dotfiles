import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme
import qs.Widgets

// Right drawer with every notification still held, plus Do Not Disturb
Scope {
    id: root

    Connections {
        target: Notifs
        function onCenterRequested() { win.open = !win.open }
    }

    DrawerWindow {
        id: win
        edge: "right"
        padding: 16
        onOpenChanged: Notifs.centerOpen = open

        ColumnLayout {
            spacing: 12

            RowLayout {
                Layout.preferredWidth: 340
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    color: Theme.on_surface
                }

                component Chip: Rectangle {
                    id: chip
                    property string glyph
                    property string label
                    property bool on: false
                    signal clicked()
                    implicitWidth: row.implicitWidth + 22
                    implicitHeight: 32
                    radius: 16
                    color: on ? Theme.primary_container
                        : area.containsMouse ? Theme.surface_container_high : Theme.surface_container

                    RowLayout {
                        id: row
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: chip.glyph
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: chip.on ? Theme.on_primary_container : Theme.primary
                        }
                        Text {
                            text: chip.label
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: chip.on ? Theme.on_primary_container : Theme.on_surface
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chip.clicked()
                    }
                }

                Chip {
                    glyph: Notifs.dnd ? "󰂛" : "󰂚"
                    label: "Silent"
                    on: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
                Chip {
                    glyph: "󰎟"
                    label: "Clear"
                    onClicked: Notifs.clearAll()
                }
            }

            Item {
                Layout.preferredWidth: 340
                Layout.preferredHeight: Math.min(list.contentHeight, 520)
                visible: Notifs.count > 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: Notifs.all.slice().reverse()

                    delegate: NotificationCard {
                        required property var modelData
                        notif: modelData
                        width: list.width
                    }
                }
            }

            Text {
                Layout.preferredWidth: 340
                Layout.topMargin: 20
                Layout.bottomMargin: 20
                visible: Notifs.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: "You're all caught up"
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 13
                color: Theme.on_surface_variant
            }
        }
    }
}
