pragma Singleton
import QtQuick

QtObject {
    readonly property int barMargin: 8
    readonly property int edgeMargin: 8
    readonly property int barHeight: 40
    readonly property int barBottom: barMargin + barHeight
    readonly property int gap: 10
    readonly property int sideInset: gap
    readonly property int cardRadius: 22
}
