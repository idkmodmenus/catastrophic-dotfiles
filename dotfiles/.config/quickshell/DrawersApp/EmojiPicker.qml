import Quickshell
import Quickshell.Io
import QtQuick

// Emoji picker as a drawer. Enter copies the emoji to the clipboard.
PickerDrawer {
    id: root

    name: "emoji"
    placeholder: "Search emoji"
    emptyText: "Emoji list unavailable"

    // Read once, the first time the picker opens
    property bool wanted: false
    onOpened: wanted = true

    items: {
        const t = file.loaded ? file.text() : ""
        if (t === "") return []
        const out = []
        for (const line of t.split("\n")) {
            if (line === "") continue
            const f = line.split("\t")
            out.push({ glyph: f[0], text: f[1] ?? "", sub: f[2] ?? "" })
        }
        return out
    }

    onChosen: item => Quickshell.execDetached(["wl-copy", "--", item.glyph])

    FileView {
        id: file
        path: root.wanted ? Quickshell.shellPath("shared/emoji.tsv") : ""
    }
}
