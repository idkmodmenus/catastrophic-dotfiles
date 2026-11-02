import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: pill

    required property var bar
    default property alias content: row.data
    property alias spacing: row.spacing
    property string popout: ""
    property bool filled: false
    property color fill: Theme.primary
    property int padding: 8
    readonly property bool hovered: mouse.containsMouse
    readonly property bool lit: hovered || (popout !== "" && bar.popoutKind === popout)
    readonly property color ink: filled ? Theme.on_primary : (lit ? Theme.primary : Theme.on_surface)

    signal clicked(var mouse)
    signal scrolled(int delta)

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 28
    radius: 8
    color: filled ? (lit ? Qt.lighter(fill, 1.1) : fill)
        : lit ? Theme.surface_container_highest : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    onHoveredChanged: {
        if (!popout) return
        if (hovered) bar.openPopout(popout, pill)
        else bar.closePopout(popout)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: if (pill.popout && pill.bar.popoutKind !== pill.popout) pill.bar.openPopout(pill.popout, pill)
        onClicked: m => pill.clicked(m)
        onWheel: w => pill.scrolled(w.angleDelta.y)
    }
}
