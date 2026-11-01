import QtQuick
import qs.CustomTheme

// Glass surface used by the bar islands, popouts and drawer cards: the shared
// glass fill (see CustomTheme/Glass.qml) with a hairline edge. Rounded into a
// pill by default; cards set their own radius.
Rectangle {
    radius: height / 2
    color: Glass.fill
    border.width: 1
    border.color: Qt.alpha(Theme.outline_variant, 0.6)
}
