import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import qs.CustomTheme
import qs.Widgets

PanelWindow {
    id: root

    // --- WAYLAND CONFIGURATION ---
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: WlrLayershell.Ignore

    implicitWidth: 420 // 380 + 40
    color: "transparent"

    property bool isHyprlandSettingsInstalled: false
    property bool isHyprsunsetInstalled: false

    anchors {
        right: true
        top: true
        bottom: true
    }

    margins {
        top: 0
        bottom: 0
    }

    // --- CLICK OUTSIDE TO CLOSE (Native Hyprland) ---
    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: {
            if (root.isOpen) {
                root.isOpen = false
            }
        }
    }

    // --- ESCAPE KEY LISTENER ---
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.isOpen) {
                root.isOpen = false
            }
        }
    }

    // --- ANIMATION LOGIC ---
    property bool isOpen: false
    visible: isOpen || slideAnim.running

    margins { right: root.currentMargin }
    property real currentMargin: isOpen ? 0 : -470

    Behavior on currentMargin {
        NumberAnimation {
            id: slideAnim
            duration: 350
            easing.type: Easing.OutQuint
        }
    }


    Process {
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-command-exists hyprmod"]
        running: root.visible

        stdout: StdioCollector {
            onStreamFinished: {
                console.log(this.text.trim())
                root.isHyprlandSettingsInstalled = (this.text.trim() === "0")
            }
        }
    }

    Process {
        command: ["bash", "-c", Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-command-exists hyprsunset"]
        running: root.visible

        stdout: StdioCollector {
            onStreamFinished: {
                root.isHyprsunsetInstalled = (this.text.trim() === "0")
            }
        }
    }

    // --- REUSABLE COMPONENTS ---
    component CatastrophicMenuItem: MenuItem {
        id: control
        contentItem: Text {
            text: control.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            color: control.highlighted ? Theme.background : Theme.primary
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            implicitWidth: 200
            implicitHeight: 36
            color: control.highlighted ? Theme.primary : "transparent"
            radius: 4
        }
    }

    component CatastrophicButton: Button {
        Layout.fillWidth: true
        background: Rectangle {
            radius: height / 2
            color: Theme.secondary_container
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Theme.on_secondary_container
                opacity: parent.parent.pressed ? 0.16 : parent.parent.hovered ? 0.08 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
        contentItem: Text {
            text: parent.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Theme.on_secondary_container
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 8
        }
    }

    component CatastrophicSwitch: Switch {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 48
        implicitHeight: 26
        indicator: Rectangle {
            implicitWidth: 48
            implicitHeight: 26
            radius: 13
            color: parent.checked ? Theme.primary : Theme.surface_container_highest
            Behavior on color { ColorAnimation { duration: 150 } }
            Rectangle {
                readonly property bool on: parent.parent.checked
                x: on ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: on ? 20 : 14
                implicitHeight: implicitWidth
                radius: width / 2
                color: on ? Theme.on_primary : Theme.outline
                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            }
        }
    }

    component SettingsWheel: Button {
        implicitWidth: 28
        implicitHeight: 28
        background: Rectangle { color: "transparent" }
        contentItem: Item {
            Image {
                anchors.centerIn: parent
                source: "../shared/icons/settings.svg"
                width: 18
                height: 18
                sourceSize.width: 18
                sourceSize.height: 18
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Theme.on_surface_variant
                }
            }
        }
    }

    // Supports text glyphs (iconTxt) for MPRIS controls and SVG files (iconSrc) for sidebar icons
    component ActionIcon: Button {
        property string iconTxt: ""
        property string iconSrc: ""
        implicitWidth: 28
        implicitHeight: 28
        background: Rectangle { color: "transparent" }
        contentItem: Item {
            Text {
                anchors.centerIn: parent
                text: iconTxt
                visible: iconSrc === ""
                color: Theme.on_surface_variant
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
            Image {
                anchors.centerIn: parent
                source: iconSrc
                width: 18
                height: 18
                sourceSize.width: 18
                sourceSize.height: 18
                visible: iconSrc !== ""
                fillMode: Image.PreserveAspectFit
                layer.enabled: iconSrc !== ""
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Theme.on_surface_variant
                }
            }
        }
    }

    // ==========================================
    // MAIN PANEL BACKGROUND
    // ==========================================
    Item {
        anchors.fill: parent
        anchors.margins: 24

        RectangularShadow {
            id: shadow
            anchors.fill: mainBgRect
            radius: mainBgRect.radius
            blur: 15
            color: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, 0.4)
        }

        Rectangle {
            id: mainBgRect
            anchors.fill: parent
            radius: 24
            color: Theme.surface
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            // --- TOP BAR (Light/Dark, Screenshot, Color Picker & Keybinds) ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ActionIcon {
                    iconSrc: "../shared/icons/darklight.svg"
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-toggle-theme"])
                    }
                }

                ActionIcon {
                    iconSrc: "../shared/icons/picker.svg"
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/catastrophic/settings/hyprpicker.sh"])
                    }
                }

                ActionIcon {
                    iconSrc: "../shared/icons/screenshot.svg"
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/screenshot.sh"])
                    }
                }

                Item { Layout.fillWidth: true }

                CatastrophicButton {
                    text: "Keybinds"
                    Layout.fillWidth: false
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/keybindings.sh"])
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3; visible: false }

            // --- THREE BUTTONS ROW ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                CatastrophicButton {
                    text: "Welcome"
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["bash", "-c", "qs ipc call welcome toggle"])
                    }
                }
                CatastrophicButton {
                    text: "Settings"
                    onClicked: {
                        root.isOpen = false
                        // Quickshell.execDetached(["kitty", "--class", "dotfiles-floating", "-e", "catastrophic-dotfiles-settings", "com.catastrophic.dotfiles"])
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-app", "settings", "toggle"])
                    }
                }
                CatastrophicButton {
                    text: "HyprMod"
                    visible: root.isHyprlandSettingsInstalled
                    onClicked: {
                        root.isOpen = false
                        Quickshell.execDetached(["hyprmod"])
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3; visible: false }

            // --- SCROLLABLE CONTENT ---
            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: mainContentColumn.implicitHeight // Tells ScrollView how tall the inner content truly is
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    interactive: true
                    contentItem: Rectangle {
                        implicitWidth: 6; radius: 3; color: Theme.primary
                        opacity: parent.pressed ? 1.0 : (parent.active ? 0.8 : 0.4)
                    }
                }

                ColumnLayout {
                    id: mainContentColumn
                    width: scrollView.width
                    spacing: 20

                    // --- SLIDERS (Loudness & Brightness) ---
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        // LOUDNESS SLIDER
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            Image {
                                source: "../shared/icons/volume.svg"
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                sourceSize.width: 20
                                sourceSize.height: 20
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: Theme.on_surface_variant
                                }
                            }

                            Slider {
                                id: volumeSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: 50 // Default

                                Process {
                                    command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'"]
                                    running: root.isOpen
                                    stdout: StdioCollector {
                                        onStreamFinished: {
                                            let val = parseInt(this.text.trim())
                                            if (!isNaN(val)) volumeSlider.value = val;
                                        }
                                    }
                                }

                                onMoved: {
                                    Quickshell.execDetached(["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(value) + "%"])
                                }

                                background: Rectangle {
                                    x: volumeSlider.leftPadding
                                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 200
                                    implicitHeight: 14
                                    width: volumeSlider.availableWidth
                                    height: implicitHeight
                                    radius: 7
                                    color: Theme.surface_container_highest

                                    Rectangle {
                                        width: Math.max(parent.height, volumeSlider.visualPosition * parent.width - 6)
                                        height: parent.height
                                        color: Theme.primary
                                        radius: 7
                                    }
                                }

                                handle: Rectangle {
                                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 4
                                    implicitHeight: volumeSlider.pressed ? 28 : 24
                                    radius: 2
                                    color: Theme.primary
                                    Behavior on implicitHeight { NumberAnimation { duration: 100 } }
                                }
                            }
                        }

                        // BRIGHTNESS SLIDER
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            Image {
                                source: "../shared/icons/brightness.svg"
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                sourceSize.width: 20
                                sourceSize.height: 20
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: 1.0
                                    colorizationColor: Theme.on_surface_variant
                                }
                            }

                            Slider {
                                id: brightnessSlider
                                Layout.fillWidth: true
                                from: 10 // Guaranteed Minimum 10%
                                to: 100
                                value: 100

                                Process {
                                    command: ["bash", "-c", "brightnessctl -m | awk -F, '{gsub(\"%\",\"\",$4); print $4}'"]
                                    running: root.isOpen
                                    stdout: StdioCollector {
                                        onStreamFinished: {
                                            let val = parseInt(this.text.trim())
                                            if (!isNaN(val)) brightnessSlider.value = Math.max(10, val);
                                        }
                                    }
                                }

                                onMoved: {
                                    Quickshell.execDetached(["bash", "-c", "brightnessctl set " + Math.round(value) + "%"])
                                }

                                background: Rectangle {
                                    x: brightnessSlider.leftPadding
                                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 200
                                    implicitHeight: 14
                                    width: brightnessSlider.availableWidth
                                    height: implicitHeight
                                    radius: 7
                                    color: Theme.surface_container_highest

                                    Rectangle {
                                        width: Math.max(parent.height, brightnessSlider.visualPosition * parent.width - 6)
                                        height: parent.height
                                        color: Theme.primary
                                        radius: 7
                                    }
                                }

                                handle: Rectangle {
                                    x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                    y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 4
                                    implicitHeight: brightnessSlider.pressed ? 28 : 24
                                    radius: 2
                                    color: Theme.primary
                                    Behavior on implicitHeight { NumberAnimation { duration: 100 } }
                                }
                            }
                        }

                        // BLUE LIGHT FILTER (HYPRSUNSET) TOGGLE
                        // Temporary status switch mirroring the SUPER+SHIFT+H
                        // keybinding: it just starts/kills hyprsunset, nothing
                        // is persisted, so the state is gone after a restart.
                        ToggleRow {
                            active: root.isOpen
                            visible: root.isHyprsunsetInstalled
                            label: "Blue Light Filter"
                            probe: "pgrep -x hyprsunset > /dev/null && echo 1 || echo 0"
                            poll: true
                            cmdOn: "pgrep -x hyprsunset > /dev/null || setsid -f hyprsunset > /dev/null 2>&1"
                            cmdOff: "pkill -x hyprsunset"
                        }
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3; Layout.topMargin: 5; Layout.bottomMargin: 5; visible: false }

                    // --- MPRIS PLAYERS (Scrollable ListView) ---
                    ListView {
                        id: mprisListView
                        Layout.fillWidth: true

                        // Dynamically scale based on players, up to 210px (max 2 players)
                        Layout.preferredHeight: contentHeight
                        Layout.maximumHeight: 210

                        spacing: 10
                        clip: true

                        model: Mpris.players.values
                        visible: Mpris.players.values.length > 0

                        // Force disable scrolling entirely unless there are 3+ players
                        interactive: mprisListView.count > 2

                        ScrollBar.vertical: ScrollBar {
                            // Explicitly hide the scrollbar unless there are 3+ players
                            policy: mprisListView.count > 2 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                            interactive: true
                            contentItem: Rectangle {
                                implicitWidth: 6; radius: 3; color: Theme.primary
                                opacity: parent.pressed ? 1.0 : (parent.active ? 0.8 : 0.4)
                            }
                        }

                        delegate: Rectangle {
                            id: playerCard
                            property var player: modelData

                            width: mprisListView.width - 16
                            implicitHeight: 100

                            radius: 20
                            color: Theme.surface_container
                            clip: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 15

                                // Cover Art Block
                                Rectangle {
                                    implicitWidth: 80
                                    implicitHeight: 80
                                    radius: 14
                                    color: Theme.surface_container_highest
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: player.trackArtUrl ? player.trackArtUrl : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: player.trackArtUrl !== ""
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰝚" // Music note icon (fallback)
                                        font.family: "monospace"
                                        font.pixelSize: 32
                                        color: Theme.primary
                                        visible: !player.trackArtUrl || player.trackArtUrl === ""
                                    }
                                }

                                // Track Info & Controls
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 5

                                    Text {
                                        Layout.fillWidth: true
                                        text: player.trackTitle ? player.trackTitle : (player.identity ? player.identity : "No Media Playing")
                                        color: Theme.on_surface
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 16
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: {
                                            if (player.trackArtist) return player.trackArtist;
                                            if (player.trackArtists && player.trackArtists.length > 0) return player.trackArtists[0];
                                            return "Unknown Artist";
                                        }
                                        color: Theme.on_background
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                        opacity: 0.8
                                    }

                                    Item { Layout.fillHeight: true }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 15

                                        Item { Layout.fillWidth: true }

                                        ActionIcon {
                                            iconTxt: "󰒮"
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            onClicked: player.previous()
                                        }

                                        ActionIcon {
                                            iconTxt: player.isPlaying ? "󰏤" : "󰐊"
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            onClicked: player.isPlaying = !player.isPlaying
                                        }

                                        ActionIcon {
                                            iconTxt: "󰒭"
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            onClicked: player.next()
                                        }

                                        Item { Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true;
                        implicitHeight: 1;
                        color: Theme.primary;
                        opacity: 0.3;
                        Layout.topMargin: 5;
                        Layout.bottomMargin: 5;
                        visible: false
                    }

                    // --- STATUS BAR ---
                    ToggleRow {
                        active: root.isOpen
                        label: "Status Bar"
                        probe: "grep -q '\"enabled\"[[:space:]]*:[[:space:]]*false' ~/.config/catastrophic-statusbar/config.json 2>/dev/null && echo 0 || echo 1"
                        poll: true
                        endPad: false
                        cmdOn: "qs ipc call statusbar enable"
                        cmdOff: "qs ipc call statusbar disable"

                        after: SettingsWheel {
                            onClicked: statusbarMenu.open()
                            Menu {
                                id: statusbarMenu
                                y: parent.height
                                implicitWidth: 220
                                padding: 8

                                background: Rectangle { color: Theme.background; border.color: Theme.primary; border.width: 1; radius: 8 }
                                CatastrophicMenuItem { text: "Reload Status Bar"; onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "~/.config/catastrophic/scripts/catastrophic-reload-statusbar"])
                                    }
                                }
                                CatastrophicMenuItem {
                                    text: "Edit configuration"
                                    onClicked: {
                                        root.isOpen = false
                                        Quickshell.execDetached(["bash", "-c", "~/.config/catastrophic/settings/editor.sh ~/.config/catastrophic-statusbar/config.json"])
                                    }
                                }
                            }
                        }
                    }

                    // A missing file or flag counts as on, the bar's own default
                    ToggleRow {
                        active: root.isOpen
                        label: "Statusbar Expanded"
                        probe: "grep -q '\"alwaysExpanded\"[[:space:]]*:[[:space:]]*false' ~/.config/catastrophic-statusbar/config.json 2>/dev/null && echo 0 || echo 1"
                        cmdOn: "qs ipc call statusbar alwaysExpand"
                        cmdOff: "qs ipc call statusbar autoCollapse"
                    }

                    ToggleRow {
                        active: root.isOpen
                        label: "Statusbar Autohide"
                        probe: "grep -q '\"autohide\"[[:space:]]*:[[:space:]]*true' ~/.config/catastrophic-statusbar/config.json 2>/dev/null && echo 1 || echo 0"
                        poll: true
                        cmdOn: "qs ipc call statusbar autohideOn"
                        cmdOff: "qs ipc call statusbar autohideOff"
                    }

                    // --- LAUNCHER ---
                    // On = Walker, Off = Rofi, persisted to ~/.config/catastrophic/settings/launcher
                    ToggleRow {
                        id: launcherRow
                        active: root.isOpen
                        label: "Launcher"
                        probe: "l=$(tr -d '[:space:]' < ~/.config/catastrophic/settings/launcher 2>/dev/null); [ \"$l\" = walker ] && echo 1 || echo 0"
                        cmdOn: "echo walker > ~/.config/catastrophic/settings/launcher"
                        cmdOff: "echo rofi > ~/.config/catastrophic/settings/launcher"

                        Text {
                            id: launcherName
                            // Follows the switch right after it in the row
                            text: launcherRow.checked ? "Walker" : "Rofi"
                            color: Theme.primary
                            opacity: 0.7
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            Layout.rightMargin: 8
                        }
                    }

                    // --- DOCK ---
                    ToggleRow {
                        active: root.isOpen
                        label: "Dock"
                        probe: "grep -q '\"enabled\"[[:space:]]*:[[:space:]]*false' ~/.config/catastrophic-dock/config.json 2>/dev/null && echo 0 || echo 1"
                        poll: true
                        endPad: false
                        cmdOn: "catastrophic-dock enable"
                        cmdOff: "catastrophic-dock disable"

                        after: SettingsWheel {
                            onClicked: dockMenu.open()
                            Menu {
                                id: dockMenu
                                y: parent.height
                                implicitWidth: 220
                                padding: 8

                                background: Rectangle { color: Theme.background; border.color: Theme.primary; border.width: 1; radius: 8 }
                                CatastrophicMenuItem { text: "Reload Dock"; onClicked: {
                                        Quickshell.execDetached(["bash", "-c", "~/.config/catastrophic/scripts/catastrophic-reload-dock"])
                                    }
                                }
                                CatastrophicMenuItem {
                                    text: "Settings"
                                    onClicked: {
                                        root.isOpen = false
                                        Quickshell.execDetached(["bash", "-c", "catastrophic-dock settings"])
                                    }
                                }
                                CatastrophicMenuItem {
                                    text: "Edit configuration"
                                    onClicked: {
                                        root.isOpen = false
                                        Quickshell.execDetached(["bash", "-c", "catastrophic-dock edit"])
                                    }
                                }
                            }
                        }
                    }

                    // --- GAMEMODE ---
                    ToggleRow {
                        active: root.isOpen
                        label: "Gamemode"
                        probe: "test -f ~/.config/catastrophic/settings/gamemode-enabled && echo 1 || echo 0"
                        cmdOn: "$HOME/.config/hypr/scripts/gamemode.sh"
                    }

                    // --- HYPRIDLE --- (runtime only: Hyprland's autostart brings it back)
                    ToggleRow {
                        active: root.isOpen
                        label: "Hypridle"
                        probe: "pgrep -x hypridle >/dev/null && echo 1 || echo 0"
                        poll: true
                        cmdOn: "$HOME/.config/hypr/scripts/hypridle.sh toggle"
                    }

                    // --- FASTFETCH ---
                    ToggleRow {
                        active: root.isOpen
                        label: "Fastfetch"
                        probe: "test -f ~/.config/catastrophic/settings/hide-fastfetch && echo 0 || echo 1"
                        cmdOn: "$HOME/.config/catastrophic/scripts/catastrophic-toggle-fastfetch"
                    }

                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.primary; opacity: 0.3; Layout.topMargin: 5; Layout.bottomMargin: 5; visible: false }

                    // --- WALLPAPER ---
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Wallpaper"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 16 }
                        Item { Layout.fillWidth: true }
                        ActionIcon {
                            iconSrc: "../shared/icons/wallpaper.svg"
                            onClicked: {
                                root.isOpen = false
                                Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/catastrophic/scripts/catastrophic-wallpaper-app"])
                            }
                        }
                    }

                    // --- THEME ---
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Theme"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 16 }
                        Item { Layout.fillWidth: true }
                        SettingsWheel {
                            onClicked: themeMenu.open()
                            Menu {
                                id: themeMenu
                                y: parent.height

                                implicitWidth: 220
                                padding: 8

                                background: Rectangle { color: Theme.background; border.color: Theme.primary; border.width: 1; radius: 8 }
                                CatastrophicMenuItem { text: "Set GTK Theme"; onClicked: {
                                        root.isOpen = false
                                        Quickshell.execDetached(["nwg-look"])
                                    }
                                }
                                CatastrophicMenuItem { text: "Set QT Theme"; onClicked: {
                                        root.isOpen = false
                                        Quickshell.execDetached(["qt6ct"])
                                    }
                                }
                                CatastrophicMenuItem { text: "Refresh GTK Theme"; onClicked: {
                                        root.isOpen = false
                                        Quickshell.execDetached(["bash", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/gtk.sh"])
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
