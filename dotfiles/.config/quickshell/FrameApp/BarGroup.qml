import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Rounded container that groups a section of the bar
Rectangle {
    default property alias content: column.data
    // Only the workspace pill is filled; other groups sit directly on the frame
    property bool filled: true

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 34
    implicitHeight: column.implicitHeight + 14
    radius: width / 2
    color: filled ? Theme.surface_container : "transparent"

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 4
    }
}
