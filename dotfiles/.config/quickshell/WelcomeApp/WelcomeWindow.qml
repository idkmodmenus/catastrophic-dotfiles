import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import qs.CustomTheme

FloatingWindow {
    id: root
    visible: false
    title: "Catastrophic Welcome"
    implicitWidth: 940
    implicitHeight: 640
    color: Theme.surface_container_low

    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: home + "/.config/catastrophic/scripts/"

    property int page: 0
    property string version: ""
    property bool isHyprModInstalled: false
    property bool showOnStartup: true
    property var info: ({})

    function run(cmd: var): void { Quickshell.execDetached(cmd) }
    function floating(script: string): void {
        run(["kitty", "--class", "dotfiles-floating", "-e", scripts + script])
    }
    function openUrl(url: string): void { run(["xdg-open", url]) }

    FileView {
        id: versionFile
        path: root.home + "/.config/catastrophic/version.json"
        blockLoading: true
        printErrors: false
        onLoaded: {
            try { root.version = JSON.parse(this.text()).Version || "" }
            catch (e) { root.version = "" }
        }
        onLoadFailed: root.version = ""
    }

    onVisibleChanged: {
        if (!visible) return
        page = 0
        versionFile.reload()
        logo.play()
    }

    Process {
        command: ["bash", "-c", root.scripts + "catastrophic-command-exists hyprmod"]
        running: root.visible
        stdout: StdioCollector {
            onStreamFinished: root.isHyprModInstalled = (this.text.trim() === "0")
        }
    }

    Process {
        command: ["bash", "-c", "test -f ~/.cache/catastrophic-welcome-autostart && echo off || echo on"]
        running: root.visible
        stdout: StdioCollector {
            onStreamFinished: root.showOnStartup = (this.text.trim() !== "off")
        }
    }

    Process {
        running: root.visible
        command: ["bash", "-c",
            ". /etc/os-release 2>/dev/null; echo \"distro=${PRETTY_NAME:-$NAME}\";" +
            "echo \"host=$(cat /etc/hostname 2>/dev/null || uname -n)\";" +
            "echo \"kernel=$(uname -r)\";" +
            "echo \"hyprland=$(hyprctl version 2>/dev/null | sed -n '1s/^Hyprland \\([^ ]*\\).*/\\1/p')\";" +
            "echo \"quickshell=$(qs --version 2>/dev/null | awk '{print $2; exit}')\";" +
            "echo \"cpu=$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1)\";" +
            "echo \"memory=$(awk '/MemTotal/{printf \"%.1f GiB\", $2/1048576}' /proc/meminfo)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {}
                for (const line of this.text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) out[line.slice(0, i)] = line.slice(i + 1).trim()
                }
                root.info = out
            }
        }
    }

    ColumnLayout {
        id: nav
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 18
        width: 272
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 18
            Layout.leftMargin: 6
            spacing: 10
            Image {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                source: Qt.resolvedUrl("../FrameApp/logo.svg")
                sourceSize: Qt.size(60, 60)
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: Theme.primary
                }
            }
            ColumnLayout {
                spacing: -2
                Text {
                    text: "Catastrophic"
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    color: Theme.on_surface
                }
                Text {
                    text: "Welcome hub"
                    font.family: Theme.fontFamilyRegular
                    font.pixelSize: 12
                    color: Theme.on_surface_variant
                }
            }
        }

        WelcomeNavItem {
            first: true
            icon: "\u{f02dc}"; label: "Start"; sub: "Hello and first steps"
            current: root.page === 0; onClicked: root.page = 0
        }
        WelcomeNavItem {
            last: true
            icon: "\u{f030c}"; label: "Shortcuts"; sub: "Keys worth knowing"
            current: root.page === 1; onClicked: root.page = 1
        }

        Item { Layout.preferredHeight: 10 }

        WelcomeNavItem {
            first: true
            icon: "\u{f0493}"; label: "Settings"; sub: "Input, displays, look"
            current: root.page === 2; onClicked: root.page = 2
        }
        WelcomeNavItem {
            icon: "\u{f061a}"; label: "System"; sub: "Info and tools"
            current: root.page === 3; onClicked: root.page = 3
        }
        WelcomeNavItem {
            last: true
            icon: "\u{f02d7}"; label: "Help"; sub: "Links and updates"
            current: root.page === 4; onClicked: root.page = 4
        }

        Item { Layout.fillHeight: true }

        WelcomeRow {
            first: true; last: true
            color: Theme.surface_container_high
            label: "Show on startup"
            toggle: true
            checked: root.showOnStartup
            onClicked: {
                root.showOnStartup = !root.showOnStartup
                root.run(root.showOnStartup
                    ? ["rm", "-f", root.home + "/.cache/catastrophic-welcome-autostart"]
                    : ["touch", root.home + "/.cache/catastrophic-welcome-autostart"])
            }
        }
    }

    Rectangle {
        id: pane
        anchors.left: nav.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 12
        anchors.leftMargin: 18
        radius: 26
        color: Theme.surface

        WelcomePage {
            index: 0; current: root.page

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: hero.implicitHeight + 56
                radius: 20
                color: Theme.surface_container

                ColumnLayout {
                    id: hero
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 4

                    WelcomeLogo {
                        id: logo
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 6
                        text: "Catastrophic OS"
                        font.family: Theme.fontFamily
                        font.pixelSize: 32
                        font.letterSpacing: 0.5
                        color: Theme.on_surface
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.version ? "v" + root.version : "…"
                        font.family: Theme.fontFamilyRegular
                        font.pixelSize: 14
                        color: Theme.on_surface_variant
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        Layout.maximumWidth: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: "Welcome! Your desktop is ready. Here is everything you need to make it yours."
                        font.family: Theme.fontFamilyRegular
                        font.pixelSize: 13
                        color: Theme.outline
                    }
                }
            }

            WelcomeSection { text: "Get started" }
            WelcomeRow {
                first: true
                icon: "\u{f02e9}"; label: "Pick a wallpaper"; sub: "Colours follow the wallpaper"
                trailing: "\u{f0142}"
                onClicked: root.run(["bash", "-c", root.scripts + "catastrophic-wallpaper-app"])
            }
            WelcomeRow {
                icon: "\u{f0379}"; label: "Set up your monitors"; sub: "Resolution, scale, layout"
                trailing: "\u{f0142}"
                onClicked: root.run(["nwg-displays"])
            }
            WelcomeRow {
                icon: "\u{f0675}"; label: "Dotfiles settings"; sub: "Apps, bar, animations and more"
                trailing: "\u{f0142}"
                onClicked: root.run([root.scripts + "catastrophic-app", "settings", "toggle"])
            }
            WelcomeRow {
                last: true
                icon: "\u{f030c}"; label: "Learn the shortcuts"; sub: "The keys you will use every day"
                trailing: "\u{f0142}"
                onClicked: root.page = 1
            }
        }

        WelcomePage {
            index: 1; current: root.page; title: "Shortcuts"

            WelcomeSection { first: true; text: "Apps" }
            WelcomeRow { first: true; label: "Terminal"; keys: true; value: "Super + Enter" }
            WelcomeRow { label: "Drop-down terminal"; keys: true; value: "Super + `" }
            WelcomeRow { label: "Browser"; keys: true; value: "Super + B" }
            WelcomeRow { label: "File manager"; keys: true; value: "Super + E" }
            WelcomeRow { last: true; label: "App launcher"; keys: true; value: "Super + Ctrl + Enter" }

            WelcomeSection { text: "Shell" }
            WelcomeRow { first: true; label: "Dashboard"; keys: true; value: "Super + D" }
            WelcomeRow { label: "Notifications"; keys: true; value: "Super + N" }
            WelcomeRow { label: "Sidebar"; keys: true; value: "Super + Ctrl + S" }
            WelcomeRow { label: "Wallpaper selector"; keys: true; value: "Super + Ctrl + W" }
            WelcomeRow { label: "Clipboard history"; keys: true; value: "Super + V" }
            WelcomeRow { last: true; label: "Power menu"; keys: true; value: "Super + Ctrl + P" }

            WelcomeSection { text: "Windows" }
            WelcomeRow { first: true; label: "Close window"; keys: true; value: "Super + Q" }
            WelcomeRow { label: "Toggle floating"; keys: true; value: "Super + T" }
            WelcomeRow { label: "Fullscreen"; keys: true; value: "Super + F" }
            WelcomeRow { last: true; label: "Lock screen"; keys: true; value: "Super + Ctrl + L" }

            WelcomeRow {
                Layout.topMargin: 14
                first: true; last: true
                icon: "\u{f0279}"; label: "All keybindings"; sub: "Searchable list (Super + Ctrl + K)"
                trailing: "\u{f03cc}"
                onClicked: root.run(["bash", "-c", root.home + "/.config/hypr/scripts/keybindings.sh"])
            }
        }

        WelcomePage {
            index: 2; current: root.page; title: "Settings"

            WelcomeSection { first: true; text: "Devices" }
            WelcomeRow {
                first: true
                icon: "\u{f037d}"; label: "Input"; sub: "Keyboard layout, mouse, touchpad"
                trailing: "\u{f03cc}"
                onClicked: root.run(["gnome-text-editor", root.home + "/.config/hypr/input.lua"])
            }
            WelcomeRow {
                icon: "\u{f0d76}"; label: "Gestures"; sub: "Touchpad swipes"
                trailing: "\u{f03cc}"
                onClicked: root.run(["gnome-text-editor", root.home + "/.config/hypr/gestures.lua"])
            }
            WelcomeRow {
                icon: "\u{f0379}"; label: "Monitors"
                trailing: "\u{f03cc}"
                onClicked: root.run(["nwg-displays"])
            }
            WelcomeRow {
                icon: "\u{f05a9}"; label: "Network"
                trailing: "\u{f03cc}"
                onClicked: root.floating("catastrophic-network")
            }
            WelcomeRow {
                last: true
                icon: "\u{f00af}"; label: "Bluetooth"
                trailing: "\u{f03cc}"
                onClicked: root.run(["blueman-manager"])
            }

            WelcomeSection { text: "Look and feel" }
            WelcomeRow {
                first: true
                icon: "\u{f02e9}"; label: "Wallpaper"
                trailing: "\u{f03cc}"
                onClicked: root.run(["bash", "-c", root.scripts + "catastrophic-wallpaper-app"])
            }
            WelcomeRow {
                icon: "\u{f03d8}"; label: "GTK theme"; sub: "Icons, cursor, fonts"
                trailing: "\u{f03cc}"
                onClicked: root.run(["nwg-look"])
            }
            WelcomeRow {
                last: true
                icon: "\u{f10ab}"; label: "Sidebar"
                trailing: "\u{f03cc}"
                onClicked: root.run(["qs", "ipc", "call", "sidebar", "toggle"])
            }

            WelcomeSection { text: "More" }
            WelcomeRow {
                first: true
                icon: "\u{f0675}"; label: "Dotfiles settings"
                trailing: "\u{f03cc}"
                onClicked: root.run([root.scripts + "catastrophic-app", "settings", "toggle"])
            }
            WelcomeRow {
                last: true
                icon: "\u{f062e}"
                label: root.isHyprModInstalled ? "HyprMod" : "Install HyprMod"
                sub: "Graphical Hyprland settings"
                trailing: "\u{f03cc}"
                onClicked: root.isHyprModInstalled ? root.run(["hyprmod"])
                                                   : root.floating("catastrophic-install-hyprmod")
            }
        }

        WelcomePage {
            index: 3; current: root.page; title: "System"

            WelcomeSection { first: true; text: "This computer" }
            WelcomeRow { first: true; label: "Hostname"; value: root.info.host || "…" }
            WelcomeRow { label: "Distro"; value: root.info.distro || "…" }
            WelcomeRow { label: "Kernel"; value: root.info.kernel || "…" }
            WelcomeRow { label: "Processor"; value: root.info.cpu || "…" }
            WelcomeRow { last: true; label: "Memory"; value: root.info.memory || "…" }

            WelcomeSection { text: "Software" }
            WelcomeRow { first: true; label: "Catastrophic OS"; value: root.version || "…" }
            WelcomeRow { label: "Hyprland"; value: root.info.hyprland || "…" }
            WelcomeRow { last: true; label: "Quickshell"; value: root.info.quickshell || "…" }

            WelcomeSection { text: "Tools" }
            WelcomeRow {
                first: true
                icon: "\u{f0342}"; label: "Display manager"; sub: "Install or change the login screen"
                trailing: "\u{f03cc}"
                onClicked: root.floating("catastrophic-install-sddm")
            }
            WelcomeRow {
                icon: "\u{f05a9}"; label: "Network applet"; sub: "Show or hide nm-applet"
                trailing: "\u{f0142}"
                onClicked: root.run(["bash", "-c", root.scripts + "catastrophic-toggle-nmapplet"])
            }
            WelcomeRow {
                icon: "\u{f018d}"; label: "Change shell"; sub: "bash, zsh or fish"
                trailing: "\u{f03cc}"
                onClicked: root.floating("catastrophic-change-shell")
            }
            WelcomeRow {
                icon: "\u{f02fc}"; label: "System info"
                trailing: "\u{f03cc}"
                onClicked: root.run(["bash", "-c", root.scripts + "catastrophic-hyprsysteminfo"])
            }
            WelcomeRow {
                icon: "\u{f05b2}"; label: "Float or tile this window"
                trailing: "\u{f0142}"
                onClicked: {
                    if (Hyprland.usingLua)
                        Hyprland.dispatch("hl.dsp.window.float({ action = 'toggle' })")
                    else
                        Hyprland.dispatch("togglefloating")
                }
            }
            WelcomeRow {
                icon: "\u{f024b}"; label: "Open the dotfiles folder"
                trailing: "\u{f03cc}"
                onClicked: root.run(["bash", "-c", "$(cat ~/.config/catastrophic/settings/filemanager) ~/.mydotfiles"])
            }
            WelcomeRow {
                icon: "\u{f024b}"; label: "Open the backup folder"
                trailing: "\u{f03cc}"
                onClicked: root.run(["bash", "-c", "$(cat ~/.config/catastrophic/settings/filemanager) ~/.mydotfiles/backups"])
            }
            WelcomeRow {
                last: true
                icon: "\u{f0425}"; label: "Log out or power off"
                trailing: "\u{f0142}"
                onClicked: root.run(["qs", "ipc", "call", "session", "toggle"])
            }
        }

        WelcomePage {
            index: 4; current: root.page; title: "Help"

            WelcomeSection { first: true; text: "Catastrophic OS" }
            WelcomeRow {
                first: true
                icon: "\u{f06b0}"; label: "Check for updates"; sub: "Installed: " + (root.version || "…")
                trailing: "\u{f0142}"
                onClicked: root.run([root.scripts + "catastrophic-update-check", "--prompt"])
            }
            WelcomeRow {
                icon: "\u{f02a4}"; label: "GitHub"; sub: "Source, issues and install command"
                trailing: "\u{f03cc}"
                onClicked: root.openUrl("https://github.com/idkmodmenus/catastrophic-dotfiles")
            }
            WelcomeRow {
                last: true
                icon: "\u{f14de}"; label: "Releases"; sub: "What changed in each version"
                trailing: "\u{f03cc}"
                onClicked: root.openUrl("https://github.com/idkmodmenus/catastrophic-dotfiles/releases")
            }

            WelcomeSection { text: "Hyprland" }
            WelcomeRow {
                first: true
                icon: "\u{f02fd}"; label: "Hyprland homepage"
                trailing: "\u{f03cc}"
                onClicked: root.openUrl("https://hypr.land")
            }
            WelcomeRow {
                last: true
                icon: "\u{f1064}"; label: "Hyprland wiki"
                trailing: "\u{f03cc}"
                onClicked: root.openUrl("https://wiki.hypr.land")
            }
        }
    }

    Rectangle {
        anchors.top: pane.top
        anchors.right: pane.right
        anchors.margins: 12
        width: 38
        height: 38
        radius: 19
        color: closeMouse.containsMouse ? Qt.alpha(Theme.error, 0.14) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: "\u{f0156}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: closeMouse.containsMouse ? Theme.error : Theme.on_surface_variant
            scale: closeMouse.pressed ? 0.8 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.visible = false
        }
    }
}
