import QtQuick
import qs.DockApp

// Three dots in a row that open and close a collapsible dock (dock.collapsible).
// Collapsed, it is the whole dock; open, it sits at the right end of the row and
// a click folds the dock back into the dots.
Item {
    id: button

    property int dotSize: 6

    signal toggled()

    readonly property bool highlighted: dotsMouse.containsMouse

    implicitWidth: dots.implicitWidth + 24
    implicitHeight: dots.implicitHeight + 16

    // Accent pill behind the dots on hover, matching the app icons.
    Rectangle {
        anchors.centerIn: parent
        width: dots.implicitWidth + 16
        height: dots.implicitHeight + 10
        radius: height / 2
        color: DockTheme.primary
        opacity: button.highlighted ? 0.25 : 0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }
    }

    Row {
        id: dots
        anchors.centerIn: parent
        spacing: button.dotSize
        scale: button.highlighted ? 1.15 : 1

        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }

        Repeater {
            model: 3
            delegate: Rectangle {
                width: button.dotSize
                height: width
                radius: width / 2
                color: DockTheme.primary
            }
        }
    }

    MouseArea {
        id: dotsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.toggled()
    }
}
