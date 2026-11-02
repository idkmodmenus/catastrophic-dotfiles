pragma Singleton
import QtQuick

QtObject {
    readonly property real opacity: 0.8
    readonly property real tint: 0

    readonly property color fill: Qt.alpha(Qt.tint(Theme.surface, Qt.alpha(Theme.primary, tint)), opacity)
}
