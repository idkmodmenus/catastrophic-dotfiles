import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    default property alias content: row.data
    property alias spacing: row.spacing

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: row.implicitWidth + 12
    implicitHeight: 26
    radius: height / 2
    color: Theme.surface_container

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
    }
}
