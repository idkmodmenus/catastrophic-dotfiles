import Quickshell
import QtQuick

BarButton {
    iconSrc: "../shared/icons/terminal.svg"
    onClicked: {
        Quickshell.execDetached(["bash", "-c",
            Quickshell.env("HOME") + "/.config/catastrophic/settings/terminal.sh"])
    }
}
