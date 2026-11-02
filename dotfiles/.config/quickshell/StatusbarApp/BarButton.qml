import QtQuick
import QtQuick.Effects
import qs.CustomTheme

Rectangle {
    id: btn
    property string iconSrc: ""
    property bool colorize: true
    property bool focused: false
    signal clicked()

    function activate(): void { btn.clicked() }

    readonly property bool active: mouseArea.containsMouse || btn.focused

    implicitWidth: 30
    implicitHeight: 30
    radius: 15

    color: btn.active ? Theme.primary : "transparent"

    Behavior on color {
        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
    }

    Image {
        anchors.centerIn: parent
        source: btn.iconSrc
        width: 18
        height: 18
        sourceSize.width: 18
        sourceSize.height: 18
        fillMode: Image.PreserveAspectFit
        layer.enabled: btn.colorize
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: btn.active ? Theme.background : Theme.primary

            Behavior on colorizationColor {
                ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
