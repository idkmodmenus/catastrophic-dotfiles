pragma Singleton

import QtQuick

QtObject {
    signal topEdgeActivity()
    property bool topEdgeInside: false
    property bool popoutOpen: false
}
