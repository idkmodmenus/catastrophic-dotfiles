import QtQuick

// Directional motion blur for a layer: `layer.effect: MotionBlur { ... }`.
// Smears the item along (dx, dy) pixels; give it the item's size so the
// length can be turned into texture coordinates.
ShaderEffect {
    property real dx: 0
    property real dy: 0
    property real itemWidth: width
    property real itemHeight: height
    readonly property vector2d dir: Qt.vector2d(dx / Math.max(1, itemWidth), dy / Math.max(1, itemHeight))
    fragmentShader: Qt.resolvedUrl("shaders/motionblur.frag.qsb")
}
