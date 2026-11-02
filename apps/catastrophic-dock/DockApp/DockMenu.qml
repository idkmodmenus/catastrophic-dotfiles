import QtQuick
import qs.DockApp

Item {
    id: menu

    property var actions: []
    property int menuWidth: 200

    signal closeRequested()

    implicitWidth: menu.menuWidth
    implicitHeight: menuColumn.implicitHeight + 16
    width: implicitWidth
    height: implicitHeight
    visible: false

    Rectangle {
        id: menuBg
        anchors.fill: parent
        radius: 8
        color: DockTheme.background
        border.width: 1
        border.color: DockTheme.primary

        Column {
            id: menuColumn
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 2

            Repeater {
                model: menu.actions

                delegate: Rectangle {
                    id: row
                    required property var modelData

                    width: menuColumn.width
                    height: 36
                    radius: 4
                    color: rowMouse.containsMouse ? DockTheme.primary : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        text: row.modelData.label
                        color: rowMouse.containsMouse ? DockTheme.background : DockTheme.primary
                        font.family: DockTheme.fontFamily
                        font.pixelSize: 14
                        elide: Text.ElideRight
                        width: parent.width - 20

                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const run = row.modelData.callback
                            menu.closeRequested()
                            Qt.callLater(run)
                        }
                    }
                }
            }
        }
    }
}
