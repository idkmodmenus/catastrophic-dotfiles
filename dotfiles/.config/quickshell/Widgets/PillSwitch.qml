import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// On/off pill switch
Rectangle {
    id: tog
    property bool checked
    signal toggled()
    implicitWidth: 44
    implicitHeight: 24
    radius: 12
    color: checked ? Theme.primary : Theme.surface_container_highest
    Behavior on color { ColorAnimation { duration: 150 } }
    Rectangle {
        width: tog.checked ? 18 : 12
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: tog.checked ? parent.width - width - 3 : 6
        color: tog.checked ? Theme.on_primary : Theme.outline
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tog.toggled()
    }
}
