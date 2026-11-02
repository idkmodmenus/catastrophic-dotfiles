import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.CustomTheme

Rectangle {
    id: battery

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device !== null
        && device.isLaptopBattery && device.isPresent
    readonly property bool pluggedIn: !UPower.onBattery
    readonly property int percent: device ? Math.round(device.percentage * 100) : 0

    property bool preview: false

    readonly property bool collapsed: !preview && !hasBattery
    readonly property int shownPercent: preview && !hasBattery ? 72 : percent
    readonly property bool shownCharging: preview && !hasBattery ? false : pluggedIn

    readonly property string iconSource: {
        if (shownCharging)
            return "../shared/icons/battery-charging.svg"
        if (shownPercent <= 33)
            return "../shared/icons/battery-low.svg"
        if (shownPercent <= 66)
            return "../shared/icons/battery-medium.svg"
        return "../shared/icons/battery-full.svg"
    }

    visible: !collapsed

    readonly property bool active: false

    implicitWidth: collapsed ? 0 : row.implicitWidth + 6
    implicitHeight: 30
    radius: 15
    color: "transparent"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Image {
            Layout.alignment: Qt.AlignVCenter
            source: battery.iconSource
            sourceSize.width: 18
            sourceSize.height: 18
            width: 18
            height: 18
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: battery.active ? Theme.background : Theme.primary
                Behavior on colorizationColor {
                    ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: battery.shownPercent + "%"
            color: battery.active ? Theme.background : Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
            Behavior on color {
                ColorAnimation { duration: 500; easing.type: Easing.OutQuint }
            }
        }
    }
}
