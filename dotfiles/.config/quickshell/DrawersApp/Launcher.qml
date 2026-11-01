import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

// Application launcher that rises from the bottom edge of the frame
Scope {
    id: root

    property string query: ""
    property alias open: win.open

    IpcHandler {
        target: "launcher"
        function toggle(): void { win.open = !win.open }
        function open(): void { win.open = true }
        function close(): void { win.open = false }
    }

    // Only computed while the launcher is showing: sorting every installed app at
    // login was wasted work for a menu that is usually closed
    readonly property var results: {
        if (!win.visible) return []
        const q = query.trim().toLowerCase()
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
        if (q === "")
            return apps.slice().sort((a, b) => a.name.localeCompare(b.name))

        const scored = []
        for (const a of apps) {
            const name = a.name.toLowerCase()
            let score = -1
            if (name.startsWith(q)) score = 100
            else if (name.split(/[\s-]+/).some(w => w.startsWith(q))) score = 80
            else if (name.includes(q)) score = 60
            else if ((a.genericName ?? "").toLowerCase().includes(q)) score = 40
            else if ((a.keywords ?? []).some(k => k.toLowerCase().includes(q))) score = 30
            else if ((a.comment ?? "").toLowerCase().includes(q)) score = 10
            if (score >= 0) scored.push({ a, score })
        }
        scored.sort((x, y) => y.score - x.score || x.a.name.localeCompare(y.a.name))
        return scored.map(s => s.a)
    }

    function launch(entry): void {
        if (!entry) return
        entry.execute()
        win.open = false
    }

    DrawerWindow {
        id: win
        edge: "bottom"
        padding: 16

        onOpenChanged: {
            if (open) {
                root.query = ""
                list.currentIndex = 0
                focusTimer.restart()
            }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: input.forceActiveFocus() }

        ColumnLayout {
            spacing: 10

            // Results grow upwards from the search field
            ListView {
                id: list
                Layout.preferredWidth: 540
                Layout.preferredHeight: Math.min(count, 7) * 52 + (count > 0 ? 0 : 0)
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
                visible: count > 0
                clip: true
                spacing: 0
                model: root.results
                currentIndex: 0
                highlightMoveDuration: 120
                boundsBehavior: Flickable.StopAtBounds

                // Thin indicator so a long list reads as scrollable
                ScrollBar.vertical: ScrollBar {
                    policy: list.count > 7 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.outline
                        opacity: 0.6
                    }
                    background: null
                }

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    required property int index
                    readonly property bool current: ListView.isCurrentItem

                    width: list.width
                    height: 52
                    radius: 16
                    color: current ? Theme.primary_container
                        : mouse.containsMouse ? Theme.surface_container_high : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 14
                        spacing: 14

                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            source: Quickshell.iconPath(item.modelData.icon, "application-x-executable")
                            sourceSize: Qt.size(32, 32)
                            smooth: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: item.modelData.name
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: item.current ? Theme.on_primary_container : Theme.on_surface
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: item.modelData.genericName || item.modelData.comment || ""
                                elide: Text.ElideRight
                                font.family: Theme.fontFamilyRegular
                                font.pixelSize: 11
                                color: item.current ? Theme.on_primary_container : Theme.on_surface_variant
                                opacity: 0.8
                            }
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(item.modelData)
                        onPositionChanged: list.currentIndex = item.index
                    }
                }
            }

            // Search field
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
                            text: "Search applications"
                            font.family: Theme.fontFamilyRegular
                            font.pixelSize: input.font.pixelSize
                            color: Theme.on_surface_variant
                        }

                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onTabPressed: list.incrementCurrentIndex()
                        Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
                        Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
                        Keys.onEscapePressed: win.open = false
                    }
                }
            }
        }
    }
}
