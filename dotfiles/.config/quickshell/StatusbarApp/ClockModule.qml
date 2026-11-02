import Quickshell
import QtQuick
import qs.CustomTheme

Item {
    id: clockRoot

    property bool expanded: false
    property string timeFormat: "HH:mm"
    property string dateFormat: "ddd, dd MMM"
    property string calendarCommand: ""
    property bool focused: false

    signal calendarToggleRequested()

    function activate(): void {
        clockRoot.calendarToggleRequested()
    }

    function openExternalCalendar(): void {
        if (clockRoot.calendarCommand === "")
            return
        Quickshell.execDetached(["bash", "-c", clockRoot.calendarCommand])
    }

    implicitWidth: Math.max(timeText.implicitWidth, dateText.implicitWidth)
    implicitHeight: timeText.implicitHeight

    transform: Translate { y: clockRoot.expanded ? -2 : 0 }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        anchors.top: timeText.top
        anchors.topMargin: -4
        anchors.bottom: clockRoot.expanded ? dateText.bottom : timeText.bottom
        anchors.bottomMargin: -4
        radius: 8
        color: "transparent"
        border.color: Theme.primary
        border.width: 1
        opacity: clockRoot.focused ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: dateText.bottom
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                clockRoot.openExternalCalendar()
            else
                clockRoot.activate()
        }
    }

    Text {
        id: timeText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: clockRoot.expanded ? -6 : 0
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
        }
        text: Qt.formatDateTime(clock.date, clockRoot.timeFormat)
        color: Theme.primary
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
    }

    Text {
        id: dateText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: timeText.bottom
        anchors.topMargin: 1
        text: Qt.formatDateTime(clock.date, clockRoot.dateFormat)
        color: Theme.primary
        font.family: Theme.fontFamily
        font.pixelSize: 11

        opacity: clockRoot.expanded ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
        }
    }
}
