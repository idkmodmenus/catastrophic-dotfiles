import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history (cliphist) as a drawer. Enter copies the entry back to the
// clipboard; Ctrl+Delete or the bin removes it.
PickerDrawer {
    id: root

    name: "clipboard"
    placeholder: "Search clipboard history"
    emptyText: "Clipboard history is empty"
    deletable: true

    property var raw: []

    items: raw.map(line => {
        const tab = line.indexOf("\t")
        const preview = tab >= 0 ? line.slice(tab + 1) : line
        const binary = preview.startsWith("[[ binary data")
        return {
            glyph: binary ? "󰋩" : "󰅍",
            text: binary ? preview.replace(/^\[\[ binary data\s*/, "").replace(/\s*\]\]$/, "") || "Image" : preview,
            sub: "",
            line: line
        }
    })

    function copy(line): void {
        // The whole listed line identifies the entry, so pass it on stdin untouched
        Quickshell.execDetached(["bash", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "_", line])
    }

    onOpened: lister.running = true
    onChosen: item => copy(item.line)
    onDeleted: item => {
        Quickshell.execDetached(["bash", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "_", item.line])
        raw = raw.filter(l => l !== item.line)
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.raw = this.text.split("\n").filter(l => l.length > 0)
        }
    }

    IpcHandler {
        target: "clipboard-history"
        function wipe(): void {
            Quickshell.execDetached(["cliphist", "wipe"])
            root.raw = []
        }
    }
}
