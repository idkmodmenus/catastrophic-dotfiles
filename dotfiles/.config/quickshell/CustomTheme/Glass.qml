pragma Singleton
import QtQuick

// Frosted glass for the bar islands and the cards that open from them. It
// matches the kitty terminal: the theme's surface colour (kitty's background)
// at kitty's background_opacity, with Hyprland's blur behind the shell layers
// (layer rule "catastrophic-glass" in hypr/conf/catastrophic.lua).
// Lower `opacity` for clearer glass, raise `tint` to mix in the accent colour.
QtObject {
    readonly property real opacity: 0.8
    readonly property real tint: 0

    readonly property color fill: Qt.alpha(Qt.tint(Theme.surface, Qt.alpha(Theme.primary, tint)), opacity)
}
