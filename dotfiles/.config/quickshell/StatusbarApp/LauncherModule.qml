import Quickshell
import QtQuick

// Opens the application launcher.
BarButton {
    iconSrc: "../shared/icons/launcher.svg"
    onClicked: {
        Quickshell.execDetached(["bash", "-c",
            Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-launcher"])
    }
}
