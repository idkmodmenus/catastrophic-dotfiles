import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Icon, label and optional trailing text, highlighted on hover
Rectangle {
    id: row
    property string glyph
    property string label
    property string trailing
    property bool accent: false
    signal clicked()
    Layout.fillWidth: true
    implicitHeight: 38
    radius: 12
    color: area.containsMouse ? Theme.surface_container_high : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10
        Text {
            text: row.glyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: row.accent ? Theme.primary : Theme.on_surface_variant
        }
        Text {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: row.accent ? Font.DemiBold : Font.Normal
            color: Theme.on_surface
        }
        Text {
            visible: row.trailing !== ""
            text: row.trailing
            font.family: Theme.fontFamilyRegular
            font.pixelSize: 12
            color: Theme.on_surface_variant
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
