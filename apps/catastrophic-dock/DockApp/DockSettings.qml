pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var defaultSettings: ({
        "dock":   { "enabled": false, "autohide": false, "iconSize": 32,
                    "spacing": 8, "marginBottom": 16, "reserveSpace": true,
                    "hideDelay": 400, "launcherButton": true, "collapsible": false,
                    "launcherCommand": "~/.config/hypr/scripts/launcher.sh",
                    "editorCommand": "~/.config/catastrophic/settings/editor.sh" },
        "pill":   { "radius": 16, "padding": 12, "animationDuration": 350, "tabEdge": 0 },
        "border": { "width": 2, "colorTop": "", "colorBottom": "" },
        "opacity":{ "normal": 0.7 },
        "theme":  { "colorsFile": "~/.config/catastrophic-dock/colors.json" },
        "apps":   { "pinned": ["firefox", "kitty"] }
    })

    property var settings: defaultSettings

    readonly property bool enabled: settings.dock.enabled
    readonly property bool autohide: settings.dock.autohide
    readonly property bool launcherButton: settings.dock.launcherButton

    property bool dialogOpen: false

    property bool ready: false

    property bool seeded: false

    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/catastrophic-dock/config.json"
        blockLoading: true
        printErrors: false
        onLoaded: { root.applySettings(); root.ready = true }
        onLoadFailed: {
            if (!root.seeded) {
                root.seeded = true
                Qt.callLater(function() { seedProc.running = true })
                return
            }
            root.applySettings()
            root.ready = true
        }
    }

    Process {
        id: seedProc
        command: ["bash", "-c",
            'd="$HOME/.config/catastrophic-dock"; f="$d/config.json";'
            + ' mkdir -p "$d" || exit 1;'
            + ' [ -f "$f" ] && exit 0;'
            + ' [ -f "$d/dock.json" ] && exec mv "$d/dock.json" "$f";'
            + ' o="$HOME/.config/catastrophic/settings/dock.json";'
            + ' if [ -f "$o" ]; then cp "$o" "$f";'
            + ' else printf "{\\n}\\n" > "$f"; fi']
        onExited: settingsFile.reload()
    }

    function reloadSettings(): void {
        settingsFile.reload()
        console.log("Dock reload: re-reading dock settings")
        applySettings()
    }

    function parseSettings(src) {
        if (!src)
            return undefined
        let raw = src.replace(/\/\*[\s\S]*?\*\//g, "")
        if (raw.trim() === "")
            return undefined
        try {
            return JSON.parse(raw)
        } catch (e) {
            try {
                return JSON.parse(raw.replace(/,(\s*[}\]])/g, "$1"))
            } catch (e2) {
                console.warn("dock settings: could not parse the settings file,"
                    + " ignoring it:", e2)
                return undefined
            }
        }
    }

    function mergeSettings(merged, src): void {
        let parsed = parseSettings(src)
        if (parsed === undefined)
            return
        for (let group in parsed)
            for (let key in parsed[group])
                if (merged[group] !== undefined)
                    merged[group][key] = parsed[group][key]
    }

    function applySettings(text): void {
        let merged = JSON.parse(JSON.stringify(root.defaultSettings))
        mergeSettings(merged, (text !== undefined) ? text : settingsFile.text())
        root.settings = merged
    }

    function persistDockFlag(key, on): string {
        let src = settingsFile.text()
        let re = new RegExp('("' + key + '"\\s*:\\s*)(true|false)')
        let updated
        if (re.test(src)) {
            updated = src.replace(re, "$1" + (on ? "true" : "false"))
        } else {
            let obj = root.parseSettings(src)
            if (obj === undefined && src && src.trim() !== "") {
                console.warn("dock settings: the settings file is not valid"
                    + " JSON; leaving it untouched instead of overwriting.")
                return src
            }
            if (typeof obj !== "object" || obj === null)
                obj = {}
            if (obj.dock === undefined)
                obj.dock = {}
            obj.dock[key] = on
            updated = JSON.stringify(obj, null, 4) + "\n"
        }
        settingsFile.setText(updated)
        return updated
    }

    function persistPinned(list): void {
        let src = settingsFile.text()
        let obj = root.parseSettings(src)
        if (obj === undefined && src && src.trim() !== "") {
            console.warn("dock settings: the settings file is not valid JSON;"
                + " not writing the pinned list.")
            return
        }
        if (typeof obj !== "object" || obj === null)
            obj = {}
        if (obj.apps === undefined)
            obj.apps = {}
        obj.apps.pinned = list
        let updated = JSON.stringify(obj, null, 4) + "\n"
        settingsFile.setText(updated)
        applySettings(updated)
    }

    function editConfig(): void {
        Quickshell.execDetached(["bash", "-c",
            'f="$HOME/.config/catastrophic-dock/config.json"; c="${1/#\\~/$HOME}";'
            + ' if [ -n "$c" ] && command -v "${c%% *}" >/dev/null 2>&1;'
            + ' then eval "$c \\"\\$f\\""; else exec xdg-open "$f"; fi',
            "dock-edit", root.settings.dock.editorCommand || ""])
    }

    function setEnabled(on: bool): void {
        applySettings(persistDockFlag("enabled", on))
    }

    function setAutohide(on: bool): void {
        applySettings(persistDockFlag("autohide", on))
    }

    function setLauncherButton(on: bool): void {
        applySettings(persistDockFlag("launcherButton", on))
    }
}
