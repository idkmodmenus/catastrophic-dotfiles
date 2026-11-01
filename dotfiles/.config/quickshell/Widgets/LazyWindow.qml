import Quickshell
import Quickshell.Io
import QtQuick

// Holds a window that is only created the first time it is asked to open, so a
// rarely used window costs no memory at login. It answers the same IPC commands
// the window used to, so keybindings and scripts keep working unchanged.
Scope {
    id: root

    // IPC target name, for example "sidebar" (qs ipc call sidebar toggle)
    required property string name
    required property Component window
    // The window property that shows and hides it
    property string openProperty: "isOpen"

    // Open the window as soon as it has finished loading
    property bool openWhenLoaded: false

    function currentlyOpen(): bool {
        return loader.item ? !!loader.item[openProperty] : false
    }

    function setOpen(on: bool): void {
        if (loader.item) {
            loader.item[openProperty] = on
        } else if (on) {
            openWhenLoaded = true
            loader.activeAsync = true
        }
    }

    LazyLoader {
        id: loader
        component: root.window

        onItemChanged: {
            if (item && root.openWhenLoaded) {
                root.openWhenLoaded = false
                item[root.openProperty] = true
            }
        }
    }

    IpcHandler {
        target: root.name
        function toggle(): void { root.setOpen(!root.currentlyOpen()) }
        function open(): void { root.setOpen(true) }
        function close(): void { root.setOpen(false) }
        function isOpen(): bool { return root.currentlyOpen() }
    }
}
