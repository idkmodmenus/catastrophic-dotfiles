import QtQuick
import qs.CustomTheme

// Tonal rounded surface that groups related content
Rectangle {
    default property alias content: inner.data
    property real padding: 14

    implicitWidth: inner.childrenRect.width + padding * 2
    implicitHeight: inner.childrenRect.height + padding * 2
    radius: 18
    color: Theme.surface_container

    Item {
        id: inner
        x: parent.padding
        y: parent.padding
        width: parent.width - parent.padding * 2
        height: parent.height - parent.padding * 2
    }
}
