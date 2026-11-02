import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.PowerApp

PanelWindow {
    id: root

    readonly property var settings: PowerSettings.settings
    readonly property var buttons: PowerSettings.buttons

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    implicitWidth: panelBg.implicitWidth + 40
    implicitHeight: panelBg.implicitHeight + 40
    color: "transparent"

    anchors {
        right: true
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: root.isOpen = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.isOpen = false
    }

    property bool isOpen: false
    property int selectedIndex: -1

    onIsOpenChanged: {
        if (isOpen) {
            selectedIndex = buttons.length > 0 ? 0 : -1
            panelBg.forceActiveFocus()
        }
    }

    function activate(index: int): void {
        if (index < 0 || index >= buttons.length)
            return
        PowerSettings.runCommand(buttons[index])
        isOpen = false
    }

    visible: isOpen || slideAnim.running

    margins {
        right: root.currentMargin
    }

    property real currentMargin: isOpen ? settings.powermenu.marginRight
                                        : -(implicitWidth + 50)

    Behavior on currentMargin {
        NumberAnimation {
            id: slideAnim
            duration: root.settings.pill.animationDuration
            easing.type: Easing.OutQuint
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open(): void { root.isOpen = true }
        function close(): void { root.isOpen = false }
        function reload(): void {
            PowerSettings.reloadSettings()
            PowerTheme.reload()
        }
        function edit(): void { PowerSettings.editConfig() }
    }

    Item {
        id: panelBg
        implicitWidth: root.settings.button.size + 2 * root.settings.pill.paddingX
        implicitHeight: buttonLayout.implicitHeight + 2 * root.settings.pill.paddingY
        anchors.centerIn: parent

        focus: true

        Keys.onUpPressed: {
            if (root.selectedIndex <= 0)
                root.selectedIndex = root.buttons.length - 1
            else
                root.selectedIndex--
        }
        Keys.onDownPressed: {
            if (root.selectedIndex >= root.buttons.length - 1)
                root.selectedIndex = 0
            else
                root.selectedIndex++
        }
        Keys.onReturnPressed: root.activate(root.selectedIndex)
        Keys.onEnterPressed: root.activate(root.selectedIndex)

        RectangularShadow {
            anchors.fill: mainBgRect
            radius: mainBgRect.radius
            blur: 15
            color: Qt.rgba(PowerTheme.shadow.r, PowerTheme.shadow.g, PowerTheme.shadow.b, 0.4)
        }

        Rectangle {
            id: mainBgRect
            anchors.fill: parent
            radius: root.settings.pill.radius
            opacity: root.settings.opacity.normal

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: root.settings.border.colorTop !== ""
                        ? root.settings.border.colorTop
                        : PowerTheme.primary
                }
                GradientStop {
                    position: 1.0
                    color: root.settings.border.colorBottom !== ""
                        ? root.settings.border.colorBottom
                        : PowerTheme.on_primary
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: root.settings.border.width
                radius: Math.max(0, parent.radius - anchors.margins)
                color: PowerTheme.background
            }
        }

        ColumnLayout {
            id: buttonLayout
            anchors.centerIn: parent
            spacing: root.settings.button.spacing

            Repeater {
                model: root.buttons

                PowerButton {
                    required property string modelData
                    required property int index

                    iconSrc: PowerSettings.buttonIcons[modelData]
                    selected: root.selectedIndex === index
                    onClicked: root.activate(index)
                }
            }
        }
    }
}
