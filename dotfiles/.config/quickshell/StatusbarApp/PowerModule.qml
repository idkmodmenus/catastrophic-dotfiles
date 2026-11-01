import Quickshell
import QtQuick

// Power menu -> opens the session menu (lock, log out, sleep, restart, shut down).
BarButton {
    iconSrc: "../shared/icons/power.svg"
    onClicked: {
        Quickshell.execDetached(["qs", "ipc", "call", "session", "toggle"])
    }
}
