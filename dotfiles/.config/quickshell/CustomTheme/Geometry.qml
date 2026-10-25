pragma Singleton
import QtQuick

// Measurements of the screen frame that drawers attach to
QtObject {
    readonly property int thickness: 10
    readonly property int barWidth: 44
    readonly property int panelRadius: 22
    readonly property int fillet: 18
    // How far a panel's body reaches back under the frame so no seam shows
    readonly property int overshoot: 40
}
