import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: volume

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.ready && sink.audio !== null
    readonly property real level: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property int percent: muted ? 0 : Math.round(level * 100)

    readonly property real stepSize: 0.05

    property bool focused: false

    PwObjectTracker { objects: sink !== null ? [sink] : [] }

    function setVolume(v: real): void {
        if (!ready)
            return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function step(dir: int): void {
        setVolume(level + dir * stepSize)
    }

    function toggleMute(): void {
        if (ready)
            sink.audio.muted = !sink.audio.muted
    }

    function activate(): void {
        Quickshell.execDetached(["pavucontrol"])
    }

    readonly property bool active: mouseArea.containsMouse || volume.focused

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 30
    radius: 15

    color: active ? Theme.primary : "transparent"

    Behavior on color {
        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Image {
            Layout.alignment: Qt.AlignVCenter
            source: volume.percent <= 0
                ? "../shared/icons/volume-muted.svg"
                : "../shared/icons/volume.svg"
            sourceSize.width: 18
            sourceSize.height: 18
            width: 18
            height: 18
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: volume.active ? Theme.background : Theme.primary
                Behavior on colorizationColor {
                    ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: volume.percent + "%"
            color: volume.active ? Theme.background : Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
            Behavior on color {
                ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                volume.toggleMute()
            else
                volume.activate()
        }
        onWheel: wheel => volume.step(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
