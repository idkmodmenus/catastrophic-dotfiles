import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Rounded container that groups a section of the bar
Rectangle {
    default property alias content: column.data

    Layout.alignment: Qt.AlignHCenter
    implicitWidth: 34
    implicitHeight: column.implicitHeight + 16
    radius: width / 2
    color: Theme.surface_container

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 6
    }
}
