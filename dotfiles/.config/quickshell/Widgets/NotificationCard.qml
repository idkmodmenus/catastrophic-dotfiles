import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// One notification: icon or picture, summary, body and action buttons
Rectangle {
    id: card

    required property var notif
    visible: notif !== null
    // Called after the card is clicked or closed
    signal closed()
    // Typing needs keyboard focus, which toasts never take: they ask for the centre instead
    property bool canType: false
    signal replyRequested()

    readonly property bool replyable: notif?.hasInlineReply ?? false

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical
    readonly property var actions: notif?.actions ?? []

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 28
    radius: 20
    color: critical ? Theme.error_container : Theme.surface_container

    // Click anywhere to trigger the default action, if the app has one
    MouseArea {
        id: bodyArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const def = card.actions.find(a => a.identifier === "default")
            if (def) def.invoke()
            card.notif?.dismiss()
            card.closed()
        }
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            radius: 14
            color: card.critical ? Theme.error : Theme.secondary_container
            clip: true

            Image {
                id: picture
                anchors.fill: parent
                source: card.notif?.image || Quickshell.iconPath(card.notif?.appIcon ?? "", true)
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !picture.visible
                text: "󰂚"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                color: card.critical ? Theme.on_error : Theme.on_secondary_container
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: card.notif?.summary ?? ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: card.critical ? Theme.on_error_container : Theme.on_surface
                }
                Text {
                    Layout.maximumWidth: 84
                    elide: Text.ElideRight
                    text: card.notif?.appName ?? ""
                    font.family: Theme.fontFamilyRegular
                    font.pixelSize: 11
                    color: card.critical ? Theme.on_error_container : Theme.on_surface_variant
                    opacity: 0.8
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: card.notif?.body ?? ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 12
                color: card.critical ? Theme.on_error_container : Theme.on_surface_variant
            }

            // Inline reply: a field in the centre, a button on toasts
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: card.replyable && card.canType
                implicitHeight: 36
                radius: 18
                color: Theme.surface_container_highest

                TextInput {
                    id: replyInput
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 40
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    color: Theme.on_surface
                    selectionColor: Theme.primary
                    selectedTextColor: Theme.on_primary
                    clip: true
                    function send() {
                        const t = text.trim()
                        if (t === "" || !card.notif) return
                        card.notif.sendInlineReply(t)
                        text = ""
                        card.closed()
                    }
                    Keys.onReturnPressed: send()
                    Keys.onEnterPressed: send()

                    Text {
                        visible: replyInput.text === ""
                        text: card.notif?.inlineReplyPlaceholder || "Reply"
                        font: replyInput.font
                        color: Theme.on_surface_variant
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒊"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: replyInput.text.trim() !== "" ? Theme.primary : Theme.on_surface_variant
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: replyInput.send()
                    }
                }
            }

            // Wraps onto a second line when the labels are long
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 6
                visible: actionList.count > 0 || (card.replyable && !card.canType)
                spacing: 6

                Rectangle {
                    visible: card.replyable && !card.canType
                    implicitWidth: replyLabel.implicitWidth + 24
                    implicitHeight: 32
                    radius: 16
                    color: replyBtn.containsMouse ? Theme.primary_container : Theme.surface_container_highest
                    Text {
                        id: replyLabel
                        anchors.centerIn: parent
                        text: "Reply"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.on_surface
                    }
                    MouseArea {
                        id: replyBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.replyRequested()
                    }
                }

                Repeater {
                    id: actionList
                    model: card.actions.filter(a => a.identifier !== "default")

                    Rectangle {
                        id: btn
                        required property var modelData
                        implicitWidth: label.implicitWidth + 24
                        implicitHeight: 32
                        radius: 16
                        color: btnArea.containsMouse ? Theme.primary_container : Theme.surface_container_highest

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: btn.modelData.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Theme.on_surface
                        }
                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                btn.modelData.invoke()
                                card.closed()
                            }
                        }
                    }
                }
            }
        }
    }

    // Close button, shown on hover
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        width: 28
        height: 28
        radius: 14
        color: Theme.surface_container_highest
        opacity: bodyArea.containsMouse || closeArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: Theme.on_surface
        }
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                card.notif?.dismiss()
                card.closed()
            }
        }
    }
}
