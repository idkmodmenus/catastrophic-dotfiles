import Quickshell
import QtQuick

// Catastrophic logo -> toggles the Sidebar app via IPC.
BarButton {
    iconSrc: Quickshell.env("HOME") + "/.config/catastrophic/assets/catastrophic.svg"
    colorize: false
    onClicked: {
        Quickshell.execDetached(["qs", "ipc", "call", "sidebar", "toggle"])
    }
}
