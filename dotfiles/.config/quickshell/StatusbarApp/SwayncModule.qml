import Quickshell
import QtQuick
import qs.DrawersApp

BarButton {
    id: swaync

    property bool hasNotifications: Notifs.count > 0

    iconSrc: hasNotifications
        ? "../shared/icons/bell-filled.svg"
        : "../shared/icons/bell.svg"

    onClicked: Notifs.centerRequested()
}
