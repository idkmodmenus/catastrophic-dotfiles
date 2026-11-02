import QtQuick

ShaderEffect {
    property real dx: 0
    property real dy: 0
    property real itemWidth: width
    property real itemHeight: height
    readonly property vector2d dir: Qt.vector2d(dx / Math.max(1, itemWidth), dy / Math.max(1, itemHeight))
    fragmentShader: Qt.resolvedUrl("shaders/motionblur.frag.qsb")
}
