import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme
import qs.Widgets

// Toasts that slide out of the top of the right edge
Scope {
    id: root

    DrawerWindow {
        id: win
        edge: "right"
        modal: false
        padding: 14
        alignStart: true
        open: Notifs.popups.length > 0 && !Notifs.centerOpen

        // Keep the last list while the panel slides away
        property var shown: []
        Connections {
            target: Notifs
            function onPopupsChanged() {
                if (Notifs.popups.length > 0) win.shown = Notifs.popups
            }
        }

        ColumnLayout {
            spacing: 10

            Repeater {
                model: win.shown

                NotificationCard {
                    id: toast
                    required property var modelData
                    notif: modelData
                    Layout.preferredWidth: 340
                    onClosed: Notifs.hidePopup(modelData)

                    Timer {
                        // Critical notifications stay until dismissed
                        running: toast.notif?.urgency !== NotificationUrgency.Critical && !win.panelHovered
                        interval: (toast.notif?.expireTimeout ?? 0) > 0 ? toast.notif.expireTimeout * 1000 : 6000
                        onTriggered: Notifs.hidePopup(toast.notif)
                    }
                }
            }
        }
    }
}
