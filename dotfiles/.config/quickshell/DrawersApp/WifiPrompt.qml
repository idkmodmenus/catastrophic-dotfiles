import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Password prompt for a secured Wi-Fi network, rising from the bottom edge.
// Replaces the nm-applet password dialog.
Scope {
    id: root

    property alias open: win.open
    readonly property var network: WifiPromptState.network
    property string error: ""
    property bool busy: false

    // Passwords shorter than 8 characters are rejected by WPA; WEP keys differ
    readonly property bool wep: network && (network.security === WifiSecurityType.StaticWep
        || network.security === WifiSecurityType.DynamicWep)
    readonly property bool valid: wep ? input.text.length >= 5 : input.text.length >= 8

    function submit(): void {
        if (!network || !valid || busy) return
        error = ""
        busy = true
        network.connectWithPsk(input.text)
        timeout.restart()
    }

    function close(): void {
        win.open = false
        busy = false
        timeout.stop()
    }

    // NetworkManager reports failure through a signal and success through state
    Connections {
        target: root.network
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) {
            if (!root.busy) return
            root.busy = false
            timeout.stop()
            root.error = "Could not connect. Check the password."
            input.selectAll()
            input.forceActiveFocus()
        }
        function onConnectedChanged() {
            if (root.busy && root.network && root.network.connected)
                root.close()
        }
    }

    // A silent failure must not leave the field stuck on "Connecting"
    Timer {
        id: timeout
        interval: 25000
        onTriggered: {
            root.busy = false
            root.error = "Timed out. Check the password and signal."
        }
    }

    Connections {
        target: WifiPromptState
        function onRequested() {
            input.text = ""
            root.error = ""
            root.busy = false
            win.open = true
        }
    }

    DrawerWindow {
        id: win
        edge: "bottom"
        padding: 16

        onOpenChanged: {
            if (open) focusTimer.restart()
            else { input.text = ""; root.busy = false }
        }
        Timer { id: focusTimer; interval: 60; onTriggered: input.forceActiveFocus() }

        ColumnLayout {
            spacing: 12
            Layout.preferredWidth: 380

            RowLayout {
                Layout.preferredWidth: 380
                spacing: 12
                Text {
                    text: "󰤨"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 22
                    color: Theme.primary
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: root.network ? (root.network.name || "Hidden network") : ""
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: Theme.on_surface
                    }
                    Text {
                        text: root.busy ? "Connecting…" : "Enter the network password"
                        font.family: Theme.fontFamilyRegular
                        font.pixelSize: 12
                        color: Theme.on_surface_variant
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 380
                implicitHeight: 46
                radius: 23
                color: Theme.surface_container_high
                border.width: root.error !== "" ? 1 : 0
                border.color: Theme.error

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 12
                    spacing: 8

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        enabled: !root.busy
                        echoMode: reveal.checked ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        color: Theme.on_surface
                        selectionColor: Theme.primary
                        selectedTextColor: Theme.on_primary
                        clip: true
                        onTextChanged: root.error = ""

                        Text {
                            visible: input.text === ""
                            text: "Password"
                            font.family: Theme.fontFamilyRegular
                            font.pixelSize: input.font.pixelSize
                            color: Theme.on_surface_variant
                        }

                        Keys.onReturnPressed: root.submit()
                        Keys.onEnterPressed: root.submit()
                        Keys.onEscapePressed: root.close()
                    }

                    // Show or hide the typed password
                    Text {
                        id: reveal
                        property bool checked: false
                        text: checked ? "󰈈" : "󰈉"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: Theme.on_surface_variant
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: reveal.checked = !reveal.checked
                        }
                    }
                }
            }

            Text {
                visible: root.error !== ""
                Layout.preferredWidth: 380
                text: root.error
                wrapMode: Text.WordWrap
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 12
                color: Theme.error
            }

            RowLayout {
                Layout.preferredWidth: 380
                spacing: 10
                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: 84
                    implicitHeight: 36
                    radius: 18
                    color: cancelArea.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.on_surface
                    }
                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                Rectangle {
                    implicitWidth: 100
                    implicitHeight: 36
                    radius: 18
                    opacity: root.valid && !root.busy ? 1 : 0.5
                    color: Theme.primary
                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "Connecting" : "Connect"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.on_primary
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: root.valid && !root.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submit()
                    }
                }
            }
        }
    }
}
