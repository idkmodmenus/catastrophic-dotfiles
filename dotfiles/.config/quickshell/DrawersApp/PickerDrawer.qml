import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

// Search-and-pick list that rises from the bottom edge, shared by the
// clipboard history and the emoji picker. Items are { glyph, text, sub }.
Scope {
    id: root

    // IPC target name: `qs ipc call <name> toggle`
    property string name
    property string placeholder: "Search"
    property string emptyText: "Nothing found"
    // Allow removing an entry with Delete
    property bool deletable: false
    property var items: []
    property alias open: win.open
    property string query: ""

    signal chosen(var item)
    signal deleted(var item)
    // Fired each time the drawer opens, so the owner can reload its items
    signal opened()

    readonly property int maxRows: 7
    readonly property int cap: 200

    // Computed only while showing, like the launcher
    readonly property var results: {
        if (!win.visible) return []
        const q = query.trim().toLowerCase()
        const src = items
        if (q === "") return src.slice(0, cap)
        const out = []
        for (const it of src) {
            if (it.text.toLowerCase().includes(q) || (it.sub ?? "").toLowerCase().includes(q)) {
                out.push(it)
                if (out.length >= cap) break
            }
        }
        return out
    }

    function pick(item): void {
        if (!item) return
        root.chosen(item)
        win.open = false
    }

    IpcHandler {
        target: root.name
        function toggle(): void { win.open = !win.open }
        function open(): void { win.open = true }
        function close(): void { win.open = false }
    }

    DrawerWindow {
        id: win
        edge: "bottom"
        padding: 16

        onOpenChanged: {
            if (open) {
                root.query = ""
                list.currentIndex = 0
                root.opened()
                focusTimer.restart()
            }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: input.forceActiveFocus() }

        ColumnLayout {
            spacing: 10

            ListView {
                id: list
                Layout.preferredWidth: 540
                Layout.preferredHeight: Math.min(count, root.maxRows) * 48
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
                visible: count > 0
                clip: true
                model: root.results
                currentIndex: 0
                highlightMoveDuration: 120
                boundsBehavior: Flickable.StopAtBounds
                // A shrinking result list must not leave the index past its end
                onCountChanged: if (currentIndex >= count) currentIndex = Math.max(0, count - 1)

                ScrollBar.vertical: ScrollBar {
                    policy: list.count > root.maxRows ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.outline; opacity: 0.6 }
                    background: null
                }

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: list.width
                    height: 48
                    radius: 16
                    color: current ? Theme.primary_container
                        : mouse.containsMouse ? Theme.surface_container_high : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 14

                        Text {
                            Layout.preferredWidth: 30
                            horizontalAlignment: Text.AlignHCenter
                            visible: text !== ""
                            text: item.modelData.glyph ?? ""
                            font.family: "Noto Color Emoji, JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            color: item.current ? Theme.on_primary_container : Theme.primary
                        }
                        Text {
                            Layout.fillWidth: true
                            text: item.modelData.text
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: item.current ? Theme.on_primary_container : Theme.on_surface
                        }
                        Text {
                            visible: text !== ""
                            text: item.modelData.sub ?? ""
                            font.family: Theme.fontFamilyRegular
                            font.pixelSize: 11
                            color: item.current ? Theme.on_primary_container : Theme.on_surface_variant
                            opacity: 0.8
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(item.modelData)
                        onPositionChanged: list.currentIndex = item.index
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 540
                implicitHeight: 48
                radius: 24
                color: Theme.surface_container_high

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        text: "󰍉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Theme.primary
                    }

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        text: root.query
                        onTextChanged: { root.query = text; list.currentIndex = 0 }
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        color: Theme.on_surface
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.on_primary
                        clip: true

                        Text {
                            visible: input.text === ""
                            text: root.results.length === 0 && root.items.length === 0 ? root.emptyText : root.placeholder
                            font.family: Theme.fontFamilyRegular
                            font.pixelSize: input.font.pixelSize
                            color: Theme.on_surface_variant
                        }

                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onTabPressed: list.incrementCurrentIndex()
                        Keys.onReturnPressed: root.pick(root.results[list.currentIndex])
                        Keys.onEnterPressed: root.pick(root.results[list.currentIndex])
                        Keys.onEscapePressed: win.open = false
                        // Ctrl+Delete removes the highlighted entry; plain Delete edits the text
                        Keys.onDeletePressed: event => {
                            if (root.deletable && (event.modifiers & Qt.ControlModifier)) {
                                const it = root.results[list.currentIndex]
                                if (it) root.deleted(it)
                            } else {
                                event.accepted = false
                            }
                        }
                    }

                    Text {
                        visible: root.deletable && root.results.length > 0
                        text: "󰆴"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Theme.on_surface_variant
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const it = root.results[list.currentIndex]
                                if (it) root.deleted(it)
                            }
                        }
                    }
                }
            }
        }
    }
}
