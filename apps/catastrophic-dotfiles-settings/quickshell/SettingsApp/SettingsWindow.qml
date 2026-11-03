import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

FloatingWindow {
    id: root
    visible: false
    title: "Catastrophic Dotfiles Settings"
    implicitWidth: 900
    implicitHeight: 600

    IpcHandler {
        target: "settings"
        function toggle(): void {
            root.visible = !root.visible
        }
    }

    Timer {
        interval: 10 * 60 * 1000
        running: !root.visible
        onTriggered: Qt.quit()
    }

    property string profile: Quickshell.env("PROFILE")

    color: Theme.background 

    property string scriptPath: Quickshell.env("HOME") + "/.local/bin/catastrophic-dotfiles-settings"
    
    property var settingsData: []
    property int selectedGroupIndex: 0
    
    Process {
        command: ["bash", "-c", "cat ~/.config/catastrophic-dotfiles-settings/" + root.profile + "/settings.json 2>&1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var rawOutput = this.text.trim();
                if (rawOutput === "" || rawOutput.startsWith("cat: ")) {
                    console.log("ERROR: Bash could not find or load the settings.json file.");
                    return;
                }

                try {
                    root.settingsData = JSON.parse(rawOutput);
                } catch(e) {
                    console.log("Error parsing JSON: ", e);
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            color: Theme.background

            ListView {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 5
                model: root.settingsData
                
                delegate: Rectangle {
                    implicitWidth: parent.width
                    implicitHeight: 50
                    radius: 10
                    color: index === root.selectedGroupIndex ? Theme.primary : "transparent"
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 15
                        text: modelData.group
                        font.pixelSize: 16
                        font.family: Theme.fontFamily
                        color: index === root.selectedGroupIndex ? Theme.on_primary : Theme.primary
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectedGroupIndex = index
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.background
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40

                Text {
                    text: root.settingsData[root.selectedGroupIndex] ? root.settingsData[root.selectedGroupIndex].group : "Loading..."
                    font.pixelSize: 28
                    font.bold: true
                    color: Theme.on_background
                    font.family: Theme.fontFamily
                }

                Text {
                    text: root.settingsData[root.selectedGroupIndex] ? root.settingsData[root.selectedGroupIndex].description : ""
                    font.pixelSize: 14
                    color: Theme.on_background
                    Layout.bottomMargin: 20
                    font.family: Theme.fontFamily
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 15
                    model: root.settingsData[root.selectedGroupIndex] ? root.settingsData[root.selectedGroupIndex].settings : []

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        interactive: true
                        
                        contentItem: Rectangle {
                            implicitWidth: 6
                            implicitHeight: 100
                            radius: 3
                            color: Theme.primary
                            opacity: parent.pressed ? 1.0 : (parent.active ? 0.8 : 0.4)
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    delegate: Rectangle {
                        width: ListView.view.width - 16
                        implicitHeight: 90
                        color: Theme.background
                        radius: 10
                        border.color: Theme.primary

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 20

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                }
                                Text {
                                    text: modelData.instructions
                                    font.pixelSize: 12
                                    color: Theme.primary
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                    font.family: Theme.fontFamily
                                }
                            }

                            Item {
                                id: fieldItem 
                                Layout.preferredWidth: 220
                                Layout.preferredHeight: 40
                                property string exactVal: ""
                                property var dropdownOptions: modelData.type === "choose" ? modelData.options : []

                                Process {
                                    command: [root.scriptPath, "--get", "--id", modelData.id, root.profile]
                                    running: true
                                    stdout: StdioCollector {
                                        onStreamFinished: {
                                            fieldItem.exactVal = this.text.trim();
                                        }
                                    }
                                }

                                Process {
                                    running: modelData.type === "files" || modelData.type === "folders"
                                    command: {
                                        if (modelData.type === "files") {
                                            var cmd = "ls -1p " + modelData.folder + " 2>/dev/null | grep -v /";
                                            if (modelData.filetypes) {
                                                var pattern = modelData.filetypes.replace(/\./g, "\\.").replace(/,/g, "|");
                                                cmd += " | grep -E '(" + pattern + ")$'";
                                            }
                                            cmd += " || true";
                                            return ["bash", "-c", cmd];
                                        } else if (modelData.type === "folders") {
                                            return ["bash", "-c", "ls -1p " + modelData.folder + " 2>/dev/null | grep / | sed 's|/$||' || true"]
                                        }
                                        return ["echo", ""]
                                    }
                                    stdout: StdioCollector {
                                        onStreamFinished: {
                                            var out = this.text.trim();
                                            if (out !== "") {
                                                fieldItem.dropdownOptions = out.split("\n");
                                            }
                                        }
                                    }
                                }

                                Process {
                                    id: saveProc
                                    running: false 
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: modelData.type === "textfield"
                                    color: Theme.background
                                    radius: 10
                                    border.color: Theme.primary
                                    border.width: 1

                                    TextInput {
                                        id: valInput
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        verticalAlignment: Text.AlignVCenter
                                        color: Theme.primary
                                        font.pixelSize: 14
                                        text: fieldItem.exactVal
                                        clip: true

                                        Text {
                                            anchors.fill: parent
                                            verticalAlignment: Text.AlignVCenter
                                            text: "Enter value..."
                                            color: Theme.primary
                                            visible: valInput.text === ""
                                            font.family: Theme.fontFamily
                                        }

                                        onAccepted: {
                                            saveProc.command = [root.scriptPath, "--set", "--id", modelData.id, "--value", valInput.text, root.profile]
                                            saveProc.running = true
                                            fieldItem.exactVal = valInput.text
                                            valInput.focus = false
                                        }
                                    }
                                }

                                Switch {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.type === "toggle"

                                    checked: {
                                        var tVal = modelData.true_value !== undefined ? modelData.true_value : "true"
                                        return fieldItem.exactVal === tVal
                                    }

                                    indicator: Rectangle {
                                        implicitWidth: 48
                                        implicitHeight: 26
                                        radius: 13
                                        color: parent.checked ? Theme.primary : Theme.background
                                        border.color: parent.checked ? Theme.primary : Theme.primary
                                        border.width: 1

                                        anchors.verticalCenter: parent.verticalCenter

                                        Rectangle {
                                            x: parent.parent.checked ? parent.width - width - 2 : 2
                                            y: 2
                                            width: 22
                                            implicitHeight: 22
                                            radius: 11
                                            color: parent.parent.checked ? Theme.background : Theme.on_primary
                                            Behavior on x { NumberAnimation { duration: 150 } }
                                        }
                                    }

                                    onClicked: {
                                        var tVal = modelData.true_value !== undefined ? modelData.true_value : "true"
                                        var fVal = modelData.false_value !== undefined ? modelData.false_value : "false"
                                        var newVal = checked ? tVal : fVal

                                        saveProc.command = [root.scriptPath, "--set", "--id", modelData.id, "--value", newVal, root.profile]
                                        saveProc.running = true
                                        fieldItem.exactVal = newVal
                                    }
                                }

                                ComboBox {
                                    id: combo
                                    anchors.fill: parent
                                    visible: modelData.type === "choose" || modelData.type === "files" || modelData.type === "folders"
                                    model: fieldItem.dropdownOptions

                                    onModelChanged: updateIndex()
                                    Connections {
                                        target: fieldItem
                                        function onExactValChanged() { combo.updateIndex() }
                                    }
                                    function updateIndex() {
                                        var idx = combo.find(fieldItem.exactVal)
                                        if (idx >= 0) combo.currentIndex = idx
                                    }

                                    onActivated: function(index) {
                                        var newVal = combo.textAt(index)
                                        saveProc.command = [root.scriptPath, "--set", "--id", modelData.id, "--value", newVal, root.profile]
                                        saveProc.running = true
                                        fieldItem.exactVal = newVal
                                    }

                                    background: Rectangle {
                                        color: Theme.background
                                        border.color: Theme.primary
                                        radius: 10
                                    }
                                    contentItem: Text {
                                        text: combo.displayText
                                        font.pixelSize: 14
                                        color: Theme.primary
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 10
                                        font.family: Theme.fontFamily
                                    }

                                    popup: Popup {
                                        y: combo.height - 1
                                        implicitWidth: 220
                                        implicitHeight: contentItem.implicitHeight + 16
                                        padding: 8
                                        contentItem: ListView {
                                            clip: true
                                            implicitHeight: contentHeight
                                            model: combo.popup.visible ? combo.delegateModel : null
                                            currentIndex: combo.highlightedIndex
                                            ScrollIndicator.vertical: ScrollIndicator { }
                                        }
                                        background: Rectangle {
                                            color: Theme.background
                                            border.color: Theme.primary
                                            radius: 10
                                        }
                                    }
                                    delegate: ItemDelegate {
                                        implicitWidth: 204
                                        contentItem: Text {
                                            text: modelData
                                            color: highlighted ? Theme.on_primary : Theme.primary
                                            font.pixelSize: 14
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        background: Rectangle {
                                            color: highlighted ? Theme.primary : "transparent"
                                            radius:4
                                        }
                                        highlighted: combo.highlightedIndex === index
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}