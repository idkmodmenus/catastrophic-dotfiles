import Quickshell
import QtQuick
import qs.DrawersApp

// Opens the notification centre. Shows a filled bell while any notifications
// are waiting. Notifications are served by the shell itself (DrawersApp/Notifs.qml).
BarButton {
    id: swaync

    property bool hasNotifications: Notifs.count > 0

    iconSrc: hasNotifications
        ? "../shared/icons/bell-filled.svg"
        : "../shared/icons/bell.svg"

    onClicked: Notifs.centerRequested()
}
