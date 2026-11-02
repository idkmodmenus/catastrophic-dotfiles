import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: tray

    property bool chip: true

    readonly property real padH: chip ? 8 : 0
    readonly property real padV: chip ? 3 : 0

    readonly property bool collapsed: SystemTray.items.values.length === 0

    property int openMenuCount: 0
    readonly property bool menuOpen: openMenuCount > 0

    implicitWidth: items.implicitWidth + 2 * padH
    implicitHeight: items.implicitHeight + 2 * padV
    radius: height / 2

    color: (chip && Theme.isLight) ? Theme.primary : "transparent"

    Behavior on color {
        ColorAnimation { duration: 200 }
    }

    RowLayout {
        id: items
        anchors.centerIn: parent
        spacing: 8

        Repeater {
            model: SystemTray.items

            delegate: MouseArea {
                id: trayItem
                required property var modelData

                implicitWidth: 20
                implicitHeight: 20
                Layout.alignment: Qt.AlignVCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                Image {
                    anchors.centerIn: parent
                    source: trayItem.modelData.icon
                    width: 18
                    height: 18
                    sourceSize.width: 18
                    sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                }

                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                        modelData.activate()
                    } else if (modelData.hasMenu) {
                        trayMenu.open()
                    }
                }

                QsMenuAnchor {
                    id: trayMenu
                    menu: trayItem.modelData.menu
                    anchor.item: trayItem
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom

                    onOpened: tray.openMenuCount++
                    onClosed: tray.openMenuCount--
                }
            }
        }
    }
}
