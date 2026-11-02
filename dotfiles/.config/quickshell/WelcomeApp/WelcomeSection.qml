import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Text {
    property bool first: false
    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : 20
    Layout.bottomMargin: 6
    Layout.leftMargin: 6
    font.family: Theme.fontFamily
    font.pixelSize: 13
    color: Theme.on_surface_variant
    elide: Text.ElideRight
}
