import QtQuick
import QtQuick.Controls
import qs.DockApp

Switch {
    id: control

    property bool value: false

    signal toggledTo(bool on)

    checked: control.value
    onToggled: {
        control.toggledTo(control.checked)
        control.checked = Qt.binding(() => control.value)
    }

    implicitWidth: 48
    implicitHeight: 26

    indicator: Rectangle {
        implicitWidth: 48
        implicitHeight: 26
        radius: 13
        color: control.checked ? DockTheme.primary : DockTheme.background
        border.color: DockTheme.primary
        border.width: 1

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            y: 2
            implicitWidth: 22
            implicitHeight: 22
            radius: 11
            color: control.checked ? DockTheme.background : DockTheme.on_primary
            Behavior on x { NumberAnimation { duration: 150 } }
        }
    }
}
