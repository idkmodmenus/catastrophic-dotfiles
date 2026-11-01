import QtQuick
import QtQuick.Effects
import qs.CustomTheme

// Floating surface used by the bar's islands, popouts and drawers: the frame
// colour with a hairline border and a soft shadow underneath
Rectangle {
    // false: no fill, border or shadow, for groups that sit directly on the frame
    property bool raised: true

    radius: height / 2
    color: raised ? Theme.surface : "transparent"
    border.width: raised ? 1 : 0
    border.color: Qt.alpha(Theme.outline_variant, 0.7)

    RectangularShadow {
        visible: parent.raised
        z: -1
        anchors.fill: parent
        radius: parent.radius
        blur: 18
        offset.y: 4
        color: Qt.alpha(Theme.shadow, 0.35)
    }
}
