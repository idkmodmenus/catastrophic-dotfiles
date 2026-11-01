import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Month grid, Monday first, with today highlighted
ColumnLayout {
    id: cal

    property int cell: 32
    SystemClock { id: now; precision: SystemClock.Minutes }

    readonly property date today: now.date
    readonly property date first: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property int offset: (first.getDay() + 6) % 7
    readonly property int days: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    spacing: 6

    Text {
        text: Qt.formatDateTime(cal.today, "MMMM yyyy")
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        color: Theme.on_surface
    }

    Grid {
        columns: 7
        columnSpacing: 2
        rowSpacing: 2

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Text {
                required property string modelData
                width: cal.cell
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Theme.tertiary
            }
        }

        Repeater {
            model: 42
            Item {
                required property int index
                readonly property int day: index - cal.offset + 1
                readonly property bool valid: day >= 1 && day <= cal.days
                readonly property bool isToday: valid && day === cal.today.getDate()
                width: cal.cell
                height: cal.cell - 4

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.height
                    height: parent.height
                    radius: width / 2
                    color: Theme.primary
                    visible: parent.isToday
                }
                Text {
                    anchors.centerIn: parent
                    visible: parent.valid
                    text: parent.day
                    font.family: Theme.fontFamilyRegular
                    font.pixelSize: 12
                    color: parent.isToday ? Theme.on_primary : Theme.on_surface
                }
            }
        }
    }
}
