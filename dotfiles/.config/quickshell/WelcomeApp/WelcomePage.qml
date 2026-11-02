import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Flickable {
    id: page

    property int index: 0
    property int current: 0
    property string title: ""
    readonly property bool active: index === current
    default property alias content: column.data

    anchors.fill: parent
    contentWidth: width
    contentHeight: column.implicitHeight + 64
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height

    opacity: active ? 1 : 0
    visible: opacity > 0
    enabled: active
    property real shift: active ? 0 : 28
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on shift { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    onActiveChanged: if (active) contentY = 0

    ColumnLayout {
        id: column
        y: 32 + page.shift
        x: Math.round((page.width - width) / 2)
        width: Math.min(page.width - 56, 600)
        spacing: 3

        Text {
            visible: page.title !== ""
            Layout.bottomMargin: 14
            text: page.title
            font.family: Theme.fontFamily
            font.pixelSize: 26
            color: Theme.on_surface
        }
    }
}
