//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import "WelcomeApp"
import "SidebarApp"
import "WallpaperApp"
import "StatusbarApp"
import "CustomTheme"
import "FrameApp"
import "DrawersApp"

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
    NotificationPopups {}
    NotificationCenter {}
    WelcomeWindow {}
    SidebarWindow {}
    WallpaperWindow {}
    StatusbarWindow {}

    Variants {
        model: Quickshell.screens
        Frame {}
    }
}