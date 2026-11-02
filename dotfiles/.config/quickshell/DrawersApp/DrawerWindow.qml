import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: win

    property alias panel: framePanel
    readonly property bool panelHovered: framePanel.hovered
    property alias edge: framePanel.edge
    property alias open: framePanel.open
    property alias padding: framePanel.padding
    property alias alongOffset: framePanel.alongOffset
    property alias alignStart: framePanel.alignStart
    property bool modal: true
    default property alias content: framePanel.content

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: framePanel.progress > 0.001
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "frame-drawer"
    WlrLayershell.keyboardFocus: modal && open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: modal && open ? null : panelMask
    Item {
        id: maskProxy
        x: framePanel.x + framePanel.hit.x
        y: framePanel.y + framePanel.hit.y
        width: framePanel.hit.width
        height: framePanel.hit.height
    }
    Region { id: panelMask; item: maskProxy }

    HyprlandFocusGrab {
        windows: [win]
        active: win.modal && win.open
        onCleared: win.open = false
    }

    Shortcut {
        sequence: "Escape"
        enabled: win.modal && win.open
        onActivated: win.open = false
    }

    MouseArea {
        anchors.fill: parent
        enabled: win.modal && win.open
        onPressed: win.open = false
    }

    FramePanel { id: framePanel }
}
