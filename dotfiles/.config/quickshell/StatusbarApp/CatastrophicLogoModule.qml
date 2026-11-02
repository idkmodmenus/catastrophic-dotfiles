import Quickshell
import QtQuick

BarButton {
    iconSrc: Quickshell.env("HOME") + "/.config/catastrophic/assets/catastrophic.svg"
    colorize: false
    onClicked: {
        Quickshell.execDetached(["qs", "ipc", "call", "sidebar", "toggle"])
    }
}
