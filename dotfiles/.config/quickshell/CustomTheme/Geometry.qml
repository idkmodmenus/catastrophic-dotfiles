pragma Singleton
import QtQuick

// Measurements of the floating island bar and the cards that open from it
QtObject {
    // Border around the screen on the left, right and bottom
    readonly property int thickness: 10
    readonly property int frameRadius: 24
    // The islands sit centred in the frame's wider top edge
    readonly property int barMargin: 6
    readonly property int barHeight: 36
    // Height of the top edge, where the reserved space ends
    readonly property int barBottom: barMargin * 2 + barHeight
    // Space kept free at the bottom for the dock's dots, which rise out of the frame
    readonly property int bottomReserve: 20
    // Distance from the screen edge of a card floating beside the windows
    readonly property int sideInset: thickness + gap
    // Gap between an island and a card that drops from it, and between a card
    // and the screen edge it floats beside
    readonly property int gap: 10
    readonly property int edgeMargin: 12
    readonly property int cardRadius: 22
}
