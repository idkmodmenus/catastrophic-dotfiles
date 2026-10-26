import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme
import qs.Widgets

// Right drawer with every notification still held, plus Do Not Disturb
Scope {
    id: root

    property string query: ""

    // Newest first, with each app's notifications together (apps ordered by
    // their newest notification) so the list can show one header per app
    readonly property var rows: {
        const q = query.trim().toLowerCase()
        const order = []
        const byApp = {}
        for (const n of Notifs.all.slice().reverse()) {
            if (q !== "" && !((n.summary ?? "") + " " + (n.body ?? "") + " " + (n.appName ?? "")).toLowerCase().includes(q))
                continue
            const app = n.appName ?? ""
            if (!byApp[app]) { byApp[app] = []; order.push(app) }
            byApp[app].push({ app: app, n: n })
        }
        return order.reduce((acc, a) => acc.concat(byApp[a]), [])
    }

    Connections {
        target: Notifs
        function onCenterRequested() { win.open = !win.open }
    }

    DrawerWindow {
        id: win
        edge: "right"
        padding: 16
        onOpenChanged: {
            Notifs.centerOpen = open
            if (!open) search.text = ""
        }

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

            // Search box, shown once there is enough to search through
            Rectangle {
                Layout.preferredWidth: 340
                visible: Notifs.count > 3 || root.query !== ""
                implicitHeight: 36
                radius: 18
                color: Theme.surface_container

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8
                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: Theme.primary
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.on_surface
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.on_primary
                        clip: true
                        onTextChanged: root.query = text
                        Text {
                            visible: search.text === ""
                            text: "Search notifications"
                            font: search.font
                            color: Theme.on_surface_variant
                        }
                    }
                }
            }

            // Apps muted from toasts; click one to let it through again
            Flow {
                Layout.preferredWidth: 340
                visible: Notifs.muted.length > 0
                spacing: 6
                Repeater {
                    model: Notifs.muted
                    Rectangle {
                        id: mchip
                        required property string modelData
                        implicitWidth: mlabel.implicitWidth + 24
                        implicitHeight: 28
                        radius: 14
                        color: marea.containsMouse ? Theme.error_container : Theme.surface_container
                        Text {
                            id: mlabel
                            anchors.centerIn: parent
                            text: "󰂛 " + mchip.modelData
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: marea.containsMouse ? Theme.on_error_container : Theme.on_surface_variant
                        }
                        MouseArea {
                            id: marea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.setMuted(mchip.modelData, false)
                        }
                    }
                }
            }

            Item {
                Layout.preferredWidth: 340
                Layout.preferredHeight: Math.min(list.contentHeight, 520)
                visible: root.rows.length > 0
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuint } }

                ListView {
                    id: list
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.rows

                    // One header per app, with its count and quick actions
                    section.property: "app"
                    section.criteria: ViewSection.FullString
                    section.delegate: RowLayout {
                        id: head
                        required property string section
                        width: list.width
                        height: 30
                        spacing: 6
                        Text {
                            Layout.fillWidth: true
                            text: head.section || "Unknown"
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.primary
                        }
                        Text {
                            text: Notifs.isMuted(head.section) ? "󰂛" : "󰂚"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: Notifs.isMuted(head.section) ? Theme.error : Theme.on_surface_variant
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.setMuted(head.section, !Notifs.isMuted(head.section))
                            }
                        }
                        Text {
                            text: "󰆴"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            color: Theme.on_surface_variant
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.clearApp(head.section)
                            }
                        }
                    }

                    delegate: NotificationCard {
                        required property var modelData
                        notif: modelData.n
                        canType: true
                        width: list.width
                    }
                }
            }

            Text {
                Layout.preferredWidth: 340
                visible: Notifs.count > 0 && root.rows.length === 0
                horizontalAlignment: Text.AlignHCenter
                text: "No matches"
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 13
                color: Theme.on_surface_variant
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
