import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme
import qs.Widgets

// System monitor on the right edge: CPU, RAM and GPU history, disk use and the
// busiest processes with a kill button. Sampling runs only while it is open.
Scope {
    id: root

    readonly property int points: 60
    property alias open: win.open

    property var cpuHist: []
    property var memHist: []
    property var gpuHist: []
    property real cpu: 0
    property real mem: 0
    property real gpu: -1
    property real gpuTemp: 0
    property real cpuTemp: 0
    property real diskUsed: 0
    property real diskSize: 1
    property real memUsedKib: 0
    property real memTotalKib: 1
    property var procs: []
    // Previous CPU counters, to turn jiffies into a percentage
    property var last: null

    function push(hist, v): var {
        const out = hist.length >= points ? hist.slice(1) : hist.slice()
        out.push(v)
        return out
    }

    function gib(bytes): string { return (bytes / 1073741824).toFixed(1) }

    function reset(): void {
        cpuHist = []; memHist = []; gpuHist = []
        last = null
        procs = []
    }

    function parse(text): void {
        const procs = []
        let gpu = -1
        for (const line of text.split("\n")) {
            const f = line.trim().split(/\s+/)
            switch (f[0]) {
            case "cpu": {
                const busy = Number(f[1]), total = Number(f[2])
                if (root.last && total > root.last.total) {
                    root.cpu = Math.max(0, Math.min(1, (busy - root.last.busy) / (total - root.last.total)))
                    root.cpuHist = root.push(root.cpuHist, root.cpu)
                }
                root.last = { busy, total }
                break
            }
            case "mem":
                root.memUsedKib = Number(f[1]); root.memTotalKib = Number(f[2]) || 1
                root.mem = root.memUsedKib / root.memTotalKib
                root.memHist = root.push(root.memHist, root.mem)
                break
            case "disk":
                root.diskUsed = Number(f[1]); root.diskSize = Number(f[2]) || 1
                break
            case "gpu":
                gpu = Number(f[1]) / 100
                root.gpuTemp = Number(f[2]) || 0
                break
            case "cputemp":
                root.cpuTemp = Number(f[1]) || 0
                break
            case "proc":
                procs.push({ pid: Number(f[1]), cpu: Number(f[2]), mem: Number(f[3]), name: f.slice(4).join(" ") })
                break
            }
        }
        root.gpu = gpu
        if (gpu >= 0) root.gpuHist = root.push(root.gpuHist, gpu)
        root.procs = procs
    }

    IpcHandler {
        target: "monitor"
        function toggle(): void { win.open = !win.open }
        function open(): void { win.open = true }
        function close(): void { win.open = false }
    }

    Process {
        id: sampler
        command: [Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-sysinfo"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }

    Timer {
        interval: 2000
        repeat: true
        running: win.open
        triggeredOnStart: true
        onTriggered: if (!sampler.running) sampler.running = true
    }

    DrawerWindow {
        id: win
        edge: "right"
        padding: 16
        onOpenChanged: if (!open) root.reset()

        ColumnLayout {
            spacing: 10
            Layout.preferredWidth: 340

            Text {
                text: "System"
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.weight: Font.DemiBold
                color: Theme.on_surface
            }

            // One graph card per resource
            component Graph: Rectangle {
                id: g
                property string title
                property string detail
                property var values: []
                property color tone: Theme.primary
                property real current: 0
                Layout.preferredWidth: 340
                Layout.preferredHeight: 96
                radius: 18
                color: Theme.surface_container

                RowLayout {
                    id: gh
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 14
                    anchors.topMargin: 10
                    Text {
                        text: g.title
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: g.tone
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: g.detail
                        font.family: Theme.fontFamilyRegular
                        font.pixelSize: 11
                        color: Theme.on_surface_variant
                    }
                    Text {
                        Layout.preferredWidth: 42
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(g.current * 100) + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Theme.on_surface
                    }
                }
                Sparkline {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.top: gh.bottom
                    anchors.margins: 10
                    anchors.topMargin: 4
                    values: g.values
                    tone: g.tone
                }
            }

            Graph {
                title: "CPU"
                detail: root.cpuTemp > 0 ? root.cpuTemp + "°C" : ""
                values: root.cpuHist
                current: root.cpu
                tone: Theme.primary
            }
            Graph {
                title: "Memory"
                detail: root.gib(root.memUsedKib * 1024) + " / " + root.gib(root.memTotalKib * 1024) + " GiB"
                values: root.memHist
                current: root.mem
                tone: Theme.tertiary
            }
            Graph {
                visible: root.gpu >= 0
                title: "GPU"
                detail: root.gpuTemp > 0 ? root.gpuTemp + "°C" : ""
                values: root.gpuHist
                current: Math.max(0, root.gpu)
                tone: Theme.secondary
            }

            // Disk usage of /
            Rectangle {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 52
                radius: 18
                color: Theme.surface_container

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Disk"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: Theme.primary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.gib(root.diskUsed) + " / " + root.gib(root.diskSize) + " GiB"
                            font.family: Theme.fontFamilyRegular
                            font.pixelSize: 11
                            color: Theme.on_surface_variant
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Theme.surface_container_highest
                        Rectangle {
                            width: parent.width * Math.min(1, root.diskUsed / root.diskSize)
                            height: parent.height
                            radius: 3
                            color: root.diskUsed / root.diskSize > 0.9 ? Theme.error : Theme.primary
                        }
                    }
                }
            }

            // Busiest processes
            Text {
                visible: root.procs.length > 0
                Layout.topMargin: 4
                text: "Processes"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Theme.on_surface_variant
            }

            Repeater {
                model: root.procs

                Rectangle {
                    id: prow
                    required property var modelData
                    // Two clicks to end a process, so a stray click does nothing
                    property bool armed: false
                    Layout.preferredWidth: 340
                    Layout.preferredHeight: 38
                    radius: 14
                    color: armed ? Theme.error_container : Theme.surface_container

                    Timer { id: disarm; interval: 3000; onTriggered: prow.armed = false }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 8
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: prow.modelData.name
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: prow.armed ? Theme.on_error_container : Theme.on_surface
                        }
                        Text {
                            text: prow.modelData.cpu.toFixed(0) + "%"
                            font.family: Theme.fontFamilyRegular
                            font.pixelSize: 11
                            color: prow.armed ? Theme.on_error_container : Theme.on_surface_variant
                        }
                        Rectangle {
                            implicitWidth: killLabel.implicitWidth + 18
                            implicitHeight: 26
                            radius: 13
                            color: prow.armed ? Theme.error : Theme.surface_container_highest
                            Text {
                                id: killLabel
                                anchors.centerIn: parent
                                text: prow.armed ? "End?" : "󰅖"
                                font.family: prow.armed ? Theme.fontFamily : "JetBrainsMono Nerd Font"
                                font.pixelSize: prow.armed ? 11 : 13
                                color: prow.armed ? Theme.on_error : Theme.on_surface
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!prow.armed) {
                                        prow.armed = true
                                        disarm.restart()
                                        return
                                    }
                                    Quickshell.execDetached(["kill", String(prow.modelData.pid)])
                                    prow.armed = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
