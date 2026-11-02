pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool ready: temperature !== ""
    property string temperature: ""
    property string condition: ""
    property string glyph: "󰖐"

    function glyphFor(c: string): string {
        c = c.toLowerCase()
        return c.includes("thunder") ? "󰖓"
            : c.includes("snow") || c.includes("sleet") ? "󰖘"
            : c.includes("rain") || c.includes("drizzle") || c.includes("shower") ? "󰖗"
            : c.includes("fog") || c.includes("mist") || c.includes("haze") ? "󰖑"
            : c.includes("partly") ? "󰖕"
            : c.includes("cloud") || c.includes("overcast") ? "󰖐"
            : c.includes("sun") || c.includes("clear") ? "󰖙" : "󰖐"
    }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "8", "wttr.in/?format=%C|%t"]
        onExited: code => { if (code !== 0) retry.restart() }
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|")
                if (parts.length !== 2 || !parts[1].includes("°")) {
                    retry.restart()
                    return
                }
                root.condition = parts[0].trim()
                root.temperature = parts[1].replace("+", "").trim()
                root.glyph = root.glyphFor(root.condition)
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetch.running = true
    }
    Timer {
        id: retry
        interval: 2 * 60 * 1000
        onTriggered: fetch.running = true
    }
}
