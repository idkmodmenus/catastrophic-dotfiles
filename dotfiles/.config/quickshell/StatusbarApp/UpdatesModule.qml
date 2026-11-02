import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: updates

    property int count: 0
    readonly property bool collapsed: count <= 0
    property bool focused: false

    function activate(): void {
        Quickshell.execDetached(["bash", "-c",
            Quickshell.env("HOME") + "/.config/catastrophic/settings/installupdates.sh"])
    }

    visible: !collapsed

    readonly property bool active: mouseArea.containsMouse || updates.focused

    implicitWidth: collapsed ? 0 : row.implicitWidth + 6
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
            source: "../shared/icons/package.svg"
            sourceSize.width: 18
            sourceSize.height: 18
            width: 18
            height: 18
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: updates.active ? Theme.background : Theme.primary
                Behavior on colorizationColor {
                    ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: updates.count
            color: updates.active ? Theme.background : Theme.primary
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
        cursorShape: Qt.PointingHandCursor
        onClicked: updates.activate()
    }

    function refresh(): void {
        updatesProc.running = false
        updatesProc.running = true
    }

    Process {
        id: updatesProc
        command: ["bash", "-c",
            Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-check-system-updates"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let raw = this.text.trim()
                    updates.count = raw ? parseInt(JSON.parse(raw).text) || 0 : 0
                } catch (e) {
                    updates.count = 0
                }
            }
        }
    }

    Timer {
        interval: 1800 * 1000
        running: true
        repeat: true
        onTriggered: updates.refresh()
    }

    IpcHandler {
        target: "updates"
        function reset(): void { updates.count = 0 }
        function refresh(): void { updates.refresh() }
    }
}
