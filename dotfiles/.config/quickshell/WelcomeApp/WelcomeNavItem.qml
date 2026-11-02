import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: item

    property string icon: ""
    property string label: ""
    property string sub: ""
    property bool current: false
    property bool first: false
    property bool last: false

    signal clicked()

    readonly property real radiusNow: mouse.pressed ? 12
        : current ? height / 2 : 0
    readonly property real outer: 22
    readonly property real inner: 5

    Layout.fillWidth: true
    implicitHeight: 60
    color: current ? Theme.secondary_container : Theme.surface_container_high
    Behavior on color { ColorAnimation { duration: 200 } }

    topLeftRadius: (mouse.pressed || current) ? radiusNow : first ? outer : inner
    topRightRadius: topLeftRadius
    bottomLeftRadius: (mouse.pressed || current) ? radiusNow : last ? outer : inner
    bottomRightRadius: bottomLeftRadius
    Behavior on topLeftRadius { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on bottomLeftRadius { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: parent.bottomLeftRadius
        bottomRightRadius: parent.bottomRightRadius
        color: Theme.on_surface
        opacity: mouse.pressed ? 0.1 : mouse.containsMouse ? 0.05 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            radius: 19
            color: item.current ? Theme.primary : Theme.secondary_container
            Behavior on color { ColorAnimation { duration: 200 } }
            Text {
                anchors.centerIn: parent
                text: item.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 19
                color: item.current ? Theme.on_primary : Theme.on_secondary_container
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: item.label
                font.family: Theme.fontFamily
                font.pixelSize: 14
                color: item.current ? Theme.on_secondary_container : Theme.on_surface
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: item.sub
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 11
                color: Theme.on_surface_variant
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }
}
