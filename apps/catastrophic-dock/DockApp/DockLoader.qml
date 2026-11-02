import Quickshell
import Quickshell.Io
import qs.DockApp

Scope {
    id: root

    IpcHandler {
        target: "dock"
        function toggle(): void { DockSettings.setEnabled(!DockSettings.enabled) }
        function enable(): void { DockSettings.setEnabled(true) }
        function disable(): void { DockSettings.setEnabled(false) }
        function autohideOn(): void { DockSettings.setAutohide(true) }
        function autohideOff(): void { DockSettings.setAutohide(false) }
        function autohideToggle(): void {
            DockSettings.setAutohide(!DockSettings.autohide)
        }
        function reload(): void {
            DockSettings.reloadSettings()
            DockTheme.reload()
        }
        function settings(): void { DockSettings.dialogOpen = true }
        function edit(): void { DockSettings.editConfig() }
    }

    LazyLoader {
        active: DockSettings.ready && DockSettings.enabled
        DockWindow {}
    }

    LazyLoader {
        active: DockSettings.dialogOpen
        DockSettingsWindow {}
    }
}
