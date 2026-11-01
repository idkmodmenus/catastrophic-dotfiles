pragma Singleton
import QtQuick

// Measurements of the floating bar islands and the cards that open from them
QtObject {
    // The islands float this far from the top and side edges of the screen
    readonly property int barMargin: 8
    readonly property int edgeMargin: 8
    readonly property int barHeight: 40
    // Bottom of the islands; windows are kept below this
    readonly property int barBottom: barMargin + barHeight
    // Gap between an island and a card that drops from it, and between a card
    // and the screen edge it floats beside
    readonly property int gap: 10
    // Distance from the screen edge of a card floating beside the windows
    readonly property int sideInset: gap
    readonly property int cardRadius: 22
}
