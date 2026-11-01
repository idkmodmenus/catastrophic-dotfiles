pragma Singleton

import QtQuick

// State the frame shares with the drawers
QtObject {
    // Fired whenever the pointer moves over the frame's top border. Motion is
    // used rather than enter/leave, which are missed while a drawer holds a
    // focus grab and left the old hover state stuck.
    signal topEdgeActivity()
    // Pointer currently on that border
    property bool topEdgeInside: false
    // A bar popout is showing; toasts step aside so they don't cover it
    property bool popoutOpen: false
}
