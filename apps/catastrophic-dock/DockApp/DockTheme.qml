pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.DockApp

Singleton {
    id: root

    readonly property string fontFamily: "Fira Sans Semibold"

    readonly property var defaultColors: ({
        "background": "#0e1514",
        "on_primary": "#003734",
        "on_surface": "#dde4e2",
        "on_surface_variant": "#bec9c6",
        "outline_variant": "#3f4947",
        "primary": "#81d5cd",
        "shadow": "#000000",
        "surface_container_high": "#252b2a"
    })

    property color background: defaultColors.background
    property color on_primary: defaultColors.on_primary
    property color on_surface: defaultColors.on_surface
    property color on_surface_variant: defaultColors.on_surface_variant
    property color outline_variant: defaultColors.outline_variant
    property color primary: defaultColors.primary
    property color shadow: defaultColors.shadow
    property color surface_container_high: defaultColors.surface_container_high

    readonly property string defaultColorsFile: Quickshell.env("HOME")
        + "/.config/catastrophic-dock/colors.json"
    readonly property string colorsFile: {
        if (!DockSettings.ready)
            return ""
        const raw = `${DockSettings.settings.theme.colorsFile ?? ""}`.trim()
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
                console.warn("dock theme: could not parse " + root.colorsFile
                    + ", using the built-in colors:", e)
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
            'f="$HOME/.config/catastrophic-dock/colors.json";'
            + ' o="$HOME/.config/catastrophic/colors/colors.json";'
            + ' [ -f "$f" ] && exit 0;'
            + ' [ -f "$o" ] || exit 1;'
            + ' mkdir -p "$(dirname "$f")" && cp "$o" "$f"']
        onExited: (code) => { if (code === 0) colorsView.reload() }
    }
}
