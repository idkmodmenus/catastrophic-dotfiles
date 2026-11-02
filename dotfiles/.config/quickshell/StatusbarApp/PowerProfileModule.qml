import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: profileRoot

    readonly property int current: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile

    property bool menuOpen: false
    property bool focused: false

    readonly property var profiles: {
        let list = [
            { "value": PowerProfile.PowerSaver,  "label": "Power Saver",  "icon": "../shared/icons/profile-power-saver.svg" },
            { "value": PowerProfile.Balanced,    "label": "Balanced",     "icon": "../shared/icons/profile-balanced.svg" }
        ]
        if (hasPerformance)
            list.push({ "value": PowerProfile.Performance, "label": "Performance", "icon": "../shared/icons/profile-performance.svg" })
        return list
    }

    readonly property string iconSource: {
        switch (current) {
        case PowerProfile.PowerSaver:   return "../shared/icons/profile-power-saver.svg"
        case PowerProfile.Performance:  return "../shared/icons/profile-performance.svg"
        default:                        return "../shared/icons/profile-balanced.svg"
        }
    }

    function setProfile(value: int): void {
        PowerProfiles.profile = value
        profileRoot.menuOpen = false
    }

    function activate(): void {
        profileRoot.menuOpen = !profileRoot.menuOpen
    }

    readonly property bool active: mouseArea.containsMouse || profileRoot.focused || profileRoot.menuOpen

    implicitWidth: 30
    implicitHeight: 30
    radius: 15

    color: active ? Theme.primary : "transparent"
    Behavior on color {
        ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
    }

    Image {
        anchors.centerIn: parent
        source: profileRoot.iconSource
        width: 18
        height: 18
        sourceSize.width: 18
        sourceSize.height: 18
        fillMode: Image.PreserveAspectFit
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: profileRoot.active ? Theme.background : Theme.primary
            Behavior on colorizationColor {
                ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: profileRoot.activate()
    }

    PopupWindow {
        id: popup
        anchor.item: profileRoot
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 10
        anchor.rect.x: profileRoot.width / 2 - popup.width / 2

        visible: profileRoot.menuOpen

        HyprlandFocusGrab {
            windows: [popup]
            active: profileRoot.menuOpen
            onCleared: profileRoot.menuOpen = false
        }

        implicitWidth: 220
        implicitHeight: menuColumn.implicitHeight + 16
        color: "transparent"

        FocusScope {
            id: keyScope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: profileRoot.menuOpen = false
        }

        onVisibleChanged: {
            if (visible)
                keyScope.forceActiveFocus()
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.background
            border.color: Theme.primary
            border.width: 1
        }

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Repeater {
                model: profileRoot.profiles
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: modelData.value === profileRoot.current
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: 4
                    color: rowMouse.containsMouse || selected ? Theme.primary : "transparent"
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutQuint }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            Layout.alignment: Qt.AlignVCenter
                            source: modelData.icon
                            width: 16
                            height: 16
                            sourceSize.width: 16
                            sourceSize.height: 16
                            fillMode: Image.PreserveAspectFit
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: (rowMouse.containsMouse || selected) ? Theme.background : Theme.primary
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            text: modelData.label
                            color: (rowMouse.containsMouse || selected) ? Theme.background : Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.bold: selected
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: profileRoot.setProfile(modelData.value)
                    }
                }
            }
        }
    }
}
