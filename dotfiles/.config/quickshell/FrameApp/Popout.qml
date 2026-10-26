import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.CustomTheme
import qs.Widgets
import qs.DrawersApp

// Caelestia-style hover popout: a panel in the frame's colour that grows out of
// the bar next to the hovered icon, joined to it by concave corners.
Item {
    id: root

    required property var bar
    required property real winHeight

    readonly property int radius: 18
    readonly property int pad: 16
    readonly property bool shown: bar.popoutKind !== ""
    readonly property alias hovered: hover.hovered

    // Kept after hiding so the content stays put while the panel fades out
    property string kind: ""

    x: bar.width
    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    clip: false

    implicitWidth: loader.item ? loader.item.implicitWidth + pad * 2 : 0
    implicitHeight: loader.item ? loader.item.implicitHeight + pad * 2 : 0
    width: implicitWidth
    height: implicitHeight

    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: root.shown; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    Behavior on height { enabled: root.shown; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    // Slide in from the bar
    transform: Translate {
        x: root.shown ? 0 : -24
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
    }

    onShownChanged: if (shown) kind = bar.popoutKind
    Connections {
        target: root.bar
        function onPopoutKindChanged() {
            if (root.bar.popoutKind !== "")
                root.kind = root.bar.popoutKind
        }
    }

    // Follow the hovered icon, staying clear of the frame's edges
    y: Math.max(bar.height > 0 ? 24 : 0, Math.min(winHeight - height - 24, bar.popoutY - height / 2))
    Behavior on y { enabled: root.shown; NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    HoverHandler { id: hover }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Body: tucks 24px under the bar so only the right-hand corners show
        ShapePath {
            fillColor: Theme.surface
            strokeColor: "transparent"
            startX: -24
            startY: 0
            PathLine { x: root.width - root.radius; y: 0 }
            PathArc { x: root.width; y: root.radius; radiusX: root.radius; radiusY: root.radius }
            PathLine { x: root.width; y: root.height - root.radius }
            PathArc { x: root.width - root.radius; y: root.height; radiusX: root.radius; radiusY: root.radius }
            PathLine { x: -24; y: root.height }
            PathLine { x: -24; y: 0 }
        }

        // Concave fillet where the top edge meets the bar
        ShapePath {
            fillColor: Theme.surface
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine { x: 0; y: -root.radius }
            PathArc {
                x: root.radius; y: 0
                radiusX: root.radius; radiusY: root.radius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: 0; y: 0 }
        }

        // ...and the bottom edge
        ShapePath {
            fillColor: Theme.surface
            strokeColor: "transparent"
            startX: 0
            startY: root.height
            PathLine { x: root.radius; y: root.height }
            PathArc {
                x: 0; y: root.height + root.radius
                radiusX: root.radius; radiusY: root.radius
                direction: PathArc.Counterclockwise
            }
            PathLine { x: 0; y: root.height }
        }
    }

    Loader {
        id: loader
        x: root.pad
        y: root.pad
        sourceComponent: root.kind === "volume" ? volumeView
            : root.kind === "battery" ? batteryView
            : root.kind === "clock" ? clockView
            : root.kind === "network" ? networkView
            : root.kind === "bluetooth" ? bluetoothView
            : root.kind === "media" ? mediaView
            : null
    }

    // Shared list row: icon, label and optional trailing text, highlighted on hover

    // Pill switch for the popout headers

    // Shared pill used for sliders
    component Slider: Item {
        id: slider
        property real value: 0
        signal moved(real value)
        implicitHeight: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 10
            radius: 5
            color: Theme.surface_container_highest

            Rectangle {
                width: Math.max(10, parent.width * slider.value)
                height: parent.height
                radius: 5
                color: Theme.primary
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function set(mx) { slider.moved(Math.max(0, Math.min(1, mx / width))) }
            onPressed: m => set(m.x)
            onPositionChanged: m => { if (pressed) set(m.x) }
            onWheel: w => slider.moved(Math.max(0, Math.min(1, slider.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }

    Component {
        id: volumeView

        ColumnLayout {
            id: vol
            readonly property PwNode sink: Pipewire.defaultAudioSink
            readonly property bool ready: !!(sink?.ready && sink?.audio)
            readonly property real level: ready ? sink.audio.volume : 0
            readonly property bool muted: ready ? sink.audio.muted : false

            // Real output devices (not app streams) and apps currently playing
            readonly property var outputs: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
            readonly property var apps: Pipewire.nodes.values.filter(n => n.isSink && n.isStream && n.audio)
            property bool pickOutput: false

            spacing: 10
            implicitWidth: 280

            PwObjectTracker { objects: [vol.sink].concat(vol.apps) }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: vol.sink ? (vol.sink.description || vol.sink.name) : "No output"
                    elide: Text.ElideRight
                    font.family: Theme.fontFamilyRegular
                    font.pixelSize: 13
                    color: Theme.on_surface_variant
                }
                Text {
                    visible: vol.outputs.length > 1
                    text: vol.pickOutput ? "󰅃" : "󰅀"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: Theme.primary
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: vol.pickOutput = !vol.pickOutput
                    }
                }
            }

            // Output device picker
            Repeater {
                model: vol.pickOutput ? vol.outputs : []
                ListRow {
                    required property var modelData
                    glyph: modelData === vol.sink ? "󰄬" : "󰓃"
                    label: modelData.description || modelData.name
                    accent: modelData === vol.sink
                    onClicked: {
                        Pipewire.preferredDefaultAudioSink = modelData
                        vol.pickOutput = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: 17
                    color: vol.muted ? Theme.error_container : Theme.secondary_container

                    Text {
                        anchors.centerIn: parent
                        text: vol.muted || vol.level === 0 ? "󰝟" : vol.level < 0.34 ? "󰕿" : vol.level < 0.67 ? "󰖀" : "󰕾"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: vol.muted ? Theme.on_error_container : Theme.on_secondary_container
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (vol.ready) vol.sink.audio.muted = !vol.sink.audio.muted
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    value: vol.level
                    onMoved: v => { if (vol.ready) vol.sink.audio.volume = v }
                }

                Text {
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(vol.level * 100) + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Theme.on_surface
                }
            }

            // Per-app volume
            Text {
                visible: vol.apps.length > 0
                Layout.topMargin: 4
                text: "Applications"
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 12
                color: Theme.on_surface_variant
            }

            Repeater {
                model: vol.apps.slice(0, 5)

                RowLayout {
                    id: appRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 90
                        text: appRow.modelData.properties["application.name"] || appRow.modelData.description || appRow.modelData.name
                        elide: Text.ElideRight
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.on_surface
                    }
                    Slider {
                        Layout.fillWidth: true
                        value: appRow.modelData.audio ? appRow.modelData.audio.volume : 0
                        onMoved: v => { if (appRow.modelData.audio) appRow.modelData.audio.volume = v }
                    }
                    Text {
                        text: appRow.modelData.audio?.muted ? "󰝟" : "󰕾"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: appRow.modelData.audio?.muted ? Theme.error : Theme.on_surface_variant
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (appRow.modelData.audio) appRow.modelData.audio.muted = !appRow.modelData.audio.muted
                        }
                    }
                }
            }
        }
    }

    Component {
        id: batteryView

        ColumnLayout {
            readonly property var device: UPower.displayDevice
            readonly property int percent: device ? Math.round(device.percentage * 100) : 0
            readonly property real secs: device ? (UPower.onBattery ? device.timeToEmpty : device.timeToFull) : 0

            function duration(s: real): string {
                const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
                return (h > 0 ? h + "h " : "") + m + "m"
            }

            spacing: 10
            implicitWidth: 220

            RowLayout {
                spacing: 12

                Text {
                    text: percent + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    color: UPower.onBattery && percent <= 15 ? Theme.error : Theme.primary
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: UPower.onBattery ? "Discharging" : percent >= 99 ? "Fully charged" : "Charging"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Theme.on_surface
                    }
                    Text {
                        visible: secs > 0
                        text: duration(secs) + (UPower.onBattery ? " remaining" : " until full")
                        font.family: Theme.fontFamilyRegular
                        font.pixelSize: 12
                        color: Theme.on_surface_variant
                    }
                }
            }

            Slider {
                Layout.fillWidth: true
                value: percent / 100
                enabled: false
            }
        }
    }

    Component {
        id: clockView

        ColumnLayout {
            id: cal
            SystemClock { id: now; precision: SystemClock.Minutes }

            readonly property date today: now.date
            readonly property date first: new Date(today.getFullYear(), today.getMonth(), 1)
            // Monday-first offset of the 1st
            readonly property int offset: (first.getDay() + 6) % 7
            readonly property int days: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

            spacing: 10
            implicitWidth: 252

            RowLayout {
                spacing: 12
                Text {
                    text: Qt.formatDateTime(cal.today, "HH:mm")
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: Qt.formatDateTime(cal.today, "dddd\nd MMMM yyyy")
                    font.family: Theme.fontFamilyRegular
                    font.pixelSize: 12
                    color: Theme.on_surface_variant
                }
            }

            Grid {
                columns: 7
                Layout.alignment: Qt.AlignHCenter
                columnSpacing: 2
                rowSpacing: 2

                Repeater {
                    model: ["M", "T", "W", "T", "F", "S", "S"]
                    Text {
                        required property string modelData
                        width: 32
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
                        width: 32
                        height: 28

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
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
    }

    Component {
        id: networkView

        ColumnLayout {
            id: net
            readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
            readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
            readonly property var networks: wifi
                ? wifi.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
                : []

            function bars(strength: real): string {
                return strength > 0.75 ? "󰤨" : strength > 0.5 ? "󰤥" : strength > 0.25 ? "󰤢" : "󰤟"
            }

            spacing: 4
            implicitWidth: 264

            // Layouts recompute implicitWidth, so pin the width with a spacer
            Item { Layout.preferredWidth: 264; implicitHeight: 0 }

            // Scan only while the panel is showing
            Binding { target: net.wifi; property: "scannerEnabled"; value: root.shown && root.kind === "network"; when: net.wifi !== null }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: Theme.on_surface
                }
                PillSwitch {
                    checked: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            ListRow {
                visible: net.wired !== null && net.wired.connected
                glyph: "󰈀"
                label: "Wired connection"
                trailing: net.wired?.linkSpeed ? net.wired.linkSpeed + " Mb/s" : "Connected"
                accent: true
            }

            Text {
                visible: Networking.wifiEnabled && net.networks.length === 0
                Layout.margins: 10
                text: net.wifi ? "Searching for networks…" : "No Wi-Fi adapter"
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 13
                color: Theme.on_surface_variant
            }
            Text {
                visible: !Networking.wifiEnabled
                Layout.margins: 10
                text: "Wi-Fi is off"
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 13
                color: Theme.on_surface_variant
            }

            Repeater {
                model: Networking.wifiEnabled ? net.networks.slice(0, 7) : []

                ListRow {
                    required property var modelData
                    glyph: net.bars(modelData.signalStrength)
                    label: modelData.name || "Connected network"
                    trailing: modelData.connected ? "Connected" : modelData.known ? "Saved" : ""
                    accent: modelData.connected
                    onClicked: {
                        if (modelData.connected) modelData.disconnect()
                        else if (modelData.known || modelData.security === WifiSecurityType.Open
                                 || modelData.security === WifiSecurityType.Owe) modelData.connect()
                        else if (modelData.security !== WifiSecurityType.Wpa2Eap
                                 && modelData.security !== WifiSecurityType.WpaEap
                                 && modelData.security !== WifiSecurityType.Wpa3SuiteB192)
                            WifiPromptState.request(modelData)
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothView

        ColumnLayout {
            id: bt
            readonly property var adapter: Bluetooth.defaultAdapter
            readonly property var devices: Bluetooth.devices.values
                .filter(d => d.paired || d.connected)
                .sort((a, b) => b.connected - a.connected)
            // Discovered but not yet paired; unnamed ones are only an address
            readonly property var nearby: Bluetooth.devices.values
                .filter(d => !d.paired && !d.connected && d.name && d.name !== d.address)

            // Pair, then trust and connect so it reconnects by itself next time
            function pairAndConnect(dev): void {
                if (dev.pairing) { dev.cancelPair(); return }
                dev.pair()
                const done = () => {
                    if (!dev.paired) return
                    dev.pairedChanged.disconnect(done)
                    dev.trusted = true
                    dev.connect()
                }
                dev.pairedChanged.connect(done)
            }

            spacing: 4
            implicitWidth: 264

            // Layouts recompute implicitWidth, so pin the width with a spacer
            Item { Layout.preferredWidth: 264; implicitHeight: 0 }

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                Text {
                    Layout.fillWidth: true
                    text: "Bluetooth"
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    color: Theme.on_surface
                }
                PillSwitch {
                    visible: bt.adapter !== null
                    checked: bt.adapter?.enabled ?? false
                    onToggled: bt.adapter.enabled = !bt.adapter.enabled
                }
            }

            // Look for nearby devices only while the panel is showing
            Binding {
                target: bt.adapter
                property: "discovering"
                value: root.shown && root.kind === "bluetooth"
                when: bt.adapter !== null && bt.adapter.enabled
            }

            Text {
                visible: !bt.adapter || !bt.adapter.enabled || (bt.devices.length === 0 && bt.nearby.length === 0)
                Layout.margins: 10
                text: !bt.adapter ? "No Bluetooth adapter" : !bt.adapter.enabled ? "Bluetooth is off" : "Searching for devices…"
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 13
                color: Theme.on_surface_variant
            }

            Repeater {
                model: bt.adapter?.enabled ? bt.devices.slice(0, 7) : []

                ListRow {
                    required property var modelData
                    glyph: "󰂯"
                    label: modelData.name
                    trailing: modelData.connected
                        ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "Connected")
                        : ""
                    accent: modelData.connected
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }

            Text {
                visible: bt.adapter?.enabled && bt.nearby.length > 0
                Layout.topMargin: 6
                Layout.leftMargin: 10
                text: "Nearby"
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 12
                color: Theme.on_surface_variant
            }

            Repeater {
                model: bt.adapter?.enabled ? bt.nearby.slice(0, 5) : []

                ListRow {
                    required property var modelData
                    glyph: "󰂲"
                    label: modelData.name
                    trailing: modelData.pairing ? "Pairing…" : "Pair"
                    onClicked: bt.pairAndConnect(modelData)
                }
            }
        }
    }

    Component {
        id: mediaView

        MediaCard {
            color: "transparent"
            padding: 0
            implicitWidth: 300
        }
    }
}
