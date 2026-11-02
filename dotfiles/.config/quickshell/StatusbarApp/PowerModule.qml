import Quickshell
import QtQuick

BarButton {
    iconSrc: "../shared/icons/power.svg"
    onClicked: {
        Quickshell.execDetached(["qs", "ipc", "call", "session", "toggle"])
    }
}
