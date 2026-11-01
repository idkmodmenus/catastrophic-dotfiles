import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.CustomTheme

// One labelled on/off row. `probe` is a shell command printing 1 when the
// switch should read on; it runs while `active` and, with `poll`, once a second
// so the switch follows changes made elsewhere (keybindings). Clicking runs
// `cmdOn` or `cmdOff` (the same script for both when `cmdOff` is empty).
// Extra items go before the switch (default slot) or after it (`after`).
RowLayout {
    id: tr

    property string label
    property string probe
    property string cmdOn
    property string cmdOff
    property bool poll: false
    property bool endPad: true
    // Bound by each use to the sidebar's open state
    property bool active: false
    property alias checked: sw.checked
    default property alias before: beforeBox.data
    property alias after: afterBox.data

    Layout.fillWidth: true

    Text { text: tr.label; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 16 }
    Item { Layout.fillWidth: true }
    RowLayout { id: beforeBox; spacing: 0 }

    Switch {
        id: sw
        property bool ready: false
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 48
        implicitHeight: 26
        indicator: Rectangle {
            implicitWidth: 48
            implicitHeight: 26
            radius: 13
            color: sw.checked ? Theme.primary : Theme.surface_container_highest
            Behavior on color { ColorAnimation { duration: 150 } }
            Rectangle {
                x: sw.checked ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: sw.checked ? 20 : 14
                implicitHeight: implicitWidth
                radius: width / 2
                color: sw.checked ? Theme.on_primary : Theme.outline
                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }

        Process {
            id: probeProc
            command: ["bash", "-c", tr.probe]
            running: tr.active
            stdout: StdioCollector {
                onStreamFinished: {
                    sw.checked = (this.text.trim() === "1")
                    sw.ready = true
                }
            }
        }
        Timer {
            interval: 1000
            repeat: true
            running: tr.poll && tr.active
            onTriggered: if (!probeProc.running) probeProc.running = true
        }
        onClicked: {
            if (!ready) return
            const cmd = checked || tr.cmdOff === "" ? tr.cmdOn : tr.cmdOff
            Quickshell.execDetached(["bash", "-c", cmd])
        }
    }

    RowLayout { id: afterBox; spacing: 0 }
    Item { visible: tr.endPad; implicitWidth: 28 }
}
