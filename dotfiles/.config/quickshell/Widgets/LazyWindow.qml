import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    required property string name
    required property Component window
    property string openProperty: "isOpen"

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
