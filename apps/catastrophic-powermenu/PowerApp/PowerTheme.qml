pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.PowerApp

Singleton {
    id: root

    readonly property var defaultColors: ({
        "background": "#0e1514",
        "on_primary": "#003734",
        "primary": "#81d5cd",
        "shadow": "#000000"
    })

    property color background: defaultColors.background
    property color on_primary: defaultColors.on_primary
    property color primary: defaultColors.primary
    property color shadow: defaultColors.shadow

    readonly property string defaultColorsFile: Quickshell.env("HOME")
        + "/.config/catastrophic-powermenu/colors.json"
    readonly property string colorsFile: {
        if (!PowerSettings.ready)
            return ""
        const raw = `${PowerSettings.settings.theme.colorsFile ?? ""}`.trim()
        if (raw === "")
            return root.defaultColorsFile
        return raw.replace(/^(~|\$HOME)(?=\/|$)/, Quickshell.env("HOME"))
    }

    function applyColors(text): void {
        let parsed = ({})
        if (text && text.trim() !== "") {
            try {
                parsed = JSON.parse(text)
            } catch (e) {
                console.warn("power menu theme: could not parse "
                    + root.colorsFile + ", using the built-in colors:", e)
            }
        }
        for (let key in root.defaultColors)
            root[key] = (typeof parsed[key] === "string" && parsed[key] !== "")
                ? parsed[key] : root.defaultColors[key]
    }

    function reload(): void {
        colorsView.reload()
    }

    property bool seeded: false

    FileView {
        id: colorsView
        path: root.colorsFile
        watchChanges: true
        printErrors: false
        onFileChanged: colorsView.reload()
        onLoaded: root.applyColors(colorsView.text())
        onLoadFailed: {
            root.applyColors("")
            if (!root.seeded && root.colorsFile === root.defaultColorsFile) {
                root.seeded = true
                Qt.callLater(function() { seedProc.running = true })
            }
        }
    }

    Process {
        id: seedProc
        command: ["bash", "-c",
            'f="$HOME/.config/catastrophic-powermenu/colors.json";'
            + ' o="$HOME/.config/catastrophic/colors/colors.json";'
            + ' [ -f "$f" ] && exit 0;'
            + ' [ -f "$o" ] || exit 1;'
            + ' mkdir -p "$(dirname "$f")" && cp "$o" "$f"']
        onExited: (code) => { if (code === 0) colorsView.reload() }
    }
}
