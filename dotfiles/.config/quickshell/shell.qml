//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import QtQuick
import "WelcomeApp"
import "SidebarApp"
import "WallpaperApp"
import "StatusbarApp"
import "CustomTheme"
import "FrameApp"
import "DrawersApp"
import "Widgets"

ShellRoot {
    // Test IPC tools: qs ipc show

    IpcHandler {
        target: "theme-manager" 
        function reload(): void {
            Theme.reloadTheme()
        }
    }

    Dashboard {}
    Osd {}
    Launcher {}
    Session {}
    WifiPrompt {}
    Clipboard {}
    EmojiPicker {}
    Monitor {}
    NotificationPopups {}
    NotificationCenter {}
    LazyWindow { name: "welcome"; openProperty: "visible"; window: Component { WelcomeWindow {} } }
    LazyWindow { name: "sidebar"; window: Component { SidebarWindow {} } }
    LazyWindow { name: "wallpaper"; window: Component { WallpaperWindow {} } }
    StatusbarWindow {}

    Variants {
        model: Quickshell.screens
        Frame {}
    }
}