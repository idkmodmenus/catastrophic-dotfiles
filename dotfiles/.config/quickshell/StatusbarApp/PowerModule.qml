import Quickshell
import QtQuick

// Power menu -> toggles the Catastrophic Power Menu (github.com/catastrophic-os/catastrophic-powermenu).
BarButton {
    iconSrc: "../shared/icons/power.svg"
    onClicked: {
        Quickshell.execDetached(["bash", "-c", "catastrophic-powermenu toggle"])
    }
}
