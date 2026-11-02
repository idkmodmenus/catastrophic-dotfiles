import Quickshell
import QtQuick
import qs.DockApp

Item {
    id: button

    property int iconSize: 32
    property string command: ""
    property var dockWindow: null

    signal reloadRequested()
    signal settingsRequested()
    signal editConfigRequested()

    readonly property bool menuOpen: button.dockWindow
        && button.dockWindow.menuItem === button

    readonly property bool highlighted: buttonMouse.containsMouse || button.menuOpen

    implicitWidth: button.iconSize + 16
    implicitHeight: button.iconSize + 18

    function launch(): void {
        if (button.command.trim() !== "")
            Quickshell.execDetached(["bash", "-c", button.command])
    }

    function menuActions(): var {
        return [
            { "label": "Reload Dock", "callback": () => button.reloadRequested() },
            { "label": "Settings", "callback": () => button.settingsRequested() },
            { "label": "Edit configuration",
              "callback": () => button.editConfigRequested() }
        ]
    }

    Rectangle {
        anchors.centerIn: grid
        width: button.iconSize + 14
        height: button.iconSize + 14
        radius: width / 2
        color: DockTheme.primary
        opacity: button.highlighted ? 0.25 : 0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
    }

    Grid {
        id: grid
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -2
        columns: 3
        spacing: Math.max(3, Math.round(button.iconSize / 8))
        scale: button.highlighted ? 1.12 : 1

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }

        Repeater {
            model: 9
            delegate: Rectangle {
                width: Math.max(4, Math.round(button.iconSize / 7))
                height: width
                radius: width / 2
                color: DockTheme.primary
            }
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (button.menuOpen)
                    button.dockWindow.closeMenu()
                button.launch()
                return
            }
            if (!button.dockWindow)
                return
            if (button.menuOpen) {
                button.dockWindow.closeMenu()
                return
            }
            button.dockWindow.openMenuFor(button, button.menuActions())
        }
    }
}
