import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: row

    property string icon: ""
    property string label: ""
    property string sub: ""
    property string value: ""
    property string trailing: ""
    property bool first: false
    property bool last: false
    property bool toggle: false
    property bool checked: false
    property bool keys: false
    readonly property bool clickable: trailing !== "" || toggle

    signal clicked()

    readonly property real bigRadius: 20
    readonly property real smallRadius: 5

    Layout.fillWidth: true
    implicitHeight: Math.max(54, content.implicitHeight + 22)
    color: Theme.surface_container

    topLeftRadius: first ? bigRadius : smallRadius
    topRightRadius: first ? bigRadius : smallRadius
    bottomLeftRadius: last ? bigRadius : smallRadius
    bottomRightRadius: last ? bigRadius : smallRadius

    Rectangle {
        anchors.fill: parent
        topLeftRadius: parent.topLeftRadius
        topRightRadius: parent.topRightRadius
        bottomLeftRadius: parent.bottomLeftRadius
        bottomRightRadius: parent.bottomRightRadius
        color: Theme.on_surface
        opacity: !row.clickable ? 0 : mouse.pressed ? 0.12 : mouse.containsMouse ? 0.06 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 14

        Rectangle {
            visible: row.icon !== ""
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            radius: 17
            color: Theme.secondary_container
            Text {
                anchors.centerIn: parent
                text: row.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 17
                color: Theme.on_secondary_container
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: row.label
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 14
                color: Theme.on_surface
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                visible: row.sub !== ""
                text: row.sub
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 12
                color: Theme.outline
                elide: Text.ElideRight
            }
        }

        Text {
            visible: row.value !== "" && !row.keys
            Layout.maximumWidth: row.width / 2
            text: row.value
            font.family: Theme.fontFamilyRegular
            font.pixelSize: 13
            color: Theme.on_surface_variant
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Row {
            visible: row.keys
            spacing: 5
            Repeater {
                model: row.keys ? row.value.split(" + ") : []
                Rectangle {
                    required property string modelData
                    height: 26
                    width: Math.max(26, keyText.implicitWidth + 16)
                    radius: 8
                    color: Theme.surface_container_highest
                    border.width: 1
                    border.color: Theme.outline_variant
                    Text {
                        id: keyText
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.on_surface
                    }
                }
            }
        }

        Text {
            visible: row.trailing !== "" && !row.toggle
            text: row.trailing
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: Theme.on_surface_variant
        }

        Rectangle {
            visible: row.toggle
            Layout.preferredWidth: 50
            Layout.preferredHeight: 30
            radius: 15
            color: row.checked ? Theme.primary : Theme.surface_container_highest
            border.width: row.checked ? 0 : 2
            border.color: Theme.outline
            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                property real knob: row.checked ? 22 : (mouse.pressed ? 24 : 16)
                width: knob
                height: knob
                radius: knob / 2
                anchors.verticalCenter: parent.verticalCenter
                x: row.checked ? parent.width - width - 4 : 7
                color: row.checked ? Theme.on_primary : Theme.outline
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on knob { NumberAnimation { duration: 150 } }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: row.clickable
        hoverEnabled: true
        cursorShape: row.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: row.clicked()
    }
}
