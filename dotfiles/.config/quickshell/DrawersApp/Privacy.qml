pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var micApps: names(Pipewire.nodes.values.filter(n =>
        n.type === PwNodeType.AudioInStream
        && n.properties["stream.capture.sink"] !== "true"
        && !(n.properties["stream.monitor"] === "true")))

    readonly property var screenApps: Pipewire.nodes.values.some(n =>
        n.type === PwNodeType.VideoSource && (n.name ?? "").startsWith("xdph")) ? ["Screen sharing"] : []

    property var cameraApps: []

    readonly property bool mic: micApps.length > 0
    readonly property bool camera: cameraApps.length > 0
    readonly property bool screen: screenApps.length > 0
    readonly property bool active: mic || camera || screen

    function names(nodes): var {
        const seen = []
        for (const n of nodes) {
            const name = n.properties["application.name"] || n.description || n.name || "Unknown app"
            if (seen.indexOf(name) < 0) seen.push(name)
        }
        return seen
    }

    property bool hasCamera: false
    Process {
        running: true
        command: ["sh", "-c", "ls /dev/video* >/dev/null 2>&1 && echo yes || echo no"]
        stdout: StdioCollector { onStreamFinished: root.hasCamera = text.trim() === "yes" }
    }

    Process {
        id: watcher
        running: root.hasCamera
        command: ["sh", "-c", "exec inotifywait -m -q -e open -e close --format x /dev/video*"]
        stdout: SplitParser { onRead: settle.restart() }
    }

    Timer {
        id: settle
        interval: 400
        onTriggered: holders.running = true
    }

    Process {
        id: holders
        command: ["sh", "-c", "for p in $(fuser /dev/video* 2>/dev/null); do cat /proc/$p/comm 2>/dev/null; done | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const progs = text.split("\n").filter(s => s && s !== "inotifywait" && s !== "wireplumber")
                const viaPw = root.names(Pipewire.nodes.values.filter(n =>
                    n.type === PwNodeType.VideoSink && n.isStream))
                root.cameraApps = progs.map(p => p === "pipewire" ? null : p)
                    .filter(p => p).concat(progs.indexOf("pipewire") >= 0
                        ? (viaPw.length ? viaPw : ["Camera"]) : [])
            }
        }
    }
}
