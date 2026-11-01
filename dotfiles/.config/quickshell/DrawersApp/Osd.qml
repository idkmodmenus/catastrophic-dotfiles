import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Right-edge display for volume and brightness changes. It slides out when a
// level changes and tucks away again after a moment.
Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: !!(sink?.ready && sink?.audio)
    readonly property real volume: audioReady ? sink.audio.volume : 0
    readonly property bool muted: audioReady ? sink.audio.muted : false

    property real brightness: 1
    property string active: "volume"
    // Ignore the initial values read at startup
    property bool armed: false

    PwObjectTracker { objects: [root.sink] }
    Timer { interval: 2500; running: true; onTriggered: root.armed = true }

    function show(kind: string): void {
        if (!armed) return
        active = kind
        win.open = true
        hideTimer.restart()
    }

    onVolumeChanged: show("volume")
    onMutedChanged: show("volume")
    onBrightnessChanged: show("brightness")

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: if (!win.panelHovered) win.open = false
    }

    // Backlight: the kernel updates this file whenever the level changes
    Process {
        command: ["bash", "-c", "ls -d /sys/class/backlight/*/ 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim()
                if (dir) {
                    maxFile.path = dir + "max_brightness"
                    blFile.path = dir + "brightness"
                }
            }
        }
    }
    FileView { id: maxFile }
    FileView {
        id: blFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const max = parseInt(maxFile.text())
            const cur = parseInt(text())
            if (max > 0 && !isNaN(cur)) root.brightness = cur / max
        }
    }

    DrawerWindow {
        id: win
        edge: "right"
        modal: false
        padding: 16

        onPanelHoveredChanged: if (!panelHovered && open) hideTimer.restart()

        RowLayout {
            spacing: 16

            component Meter: ColumnLayout {
                id: meter
                property string kind
                property real value
                property string glyph
                property bool dim: false
                readonly property bool current: root.active === kind

                spacing: 10
                opacity: current ? 1 : 0.55
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(meter.value * 100)
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Theme.on_surface
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 14
                    implicitHeight: 170
                    radius: 7
                    color: Theme.surface_container_highest

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(parent.width, parent.height * Math.min(1, meter.value))
                        radius: 7
                        color: meter.dim ? Theme.outline : Theme.primary
                        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: meter.glyph
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: meter.dim ? Theme.on_surface_variant : Theme.primary
                }
            }

            Meter {
                kind: "volume"
                value: root.volume
                dim: root.muted
                glyph: root.muted || root.volume === 0 ? "󰝟" : root.volume < 0.34 ? "󰕿" : root.volume < 0.67 ? "󰖀" : "󰕾"
            }
            Meter {
                kind: "brightness"
                value: root.brightness
                glyph: "󰃟"
            }
        }
    }
}
