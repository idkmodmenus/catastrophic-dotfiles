import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// Full-screen click-through surface hosting one FramePanel. Only the panel
// itself takes input.
PanelWindow {
    id: win

    property alias panel: framePanel
    readonly property bool panelHovered: framePanel.hovered
    property alias edge: framePanel.edge
    property alias open: framePanel.open
    property alias padding: framePanel.padding
    property alias alongOffset: framePanel.alongOffset
    property alias alignStart: framePanel.alignStart
    // Take keyboard focus and close on outside click / Escape
    property bool modal: true
    default property alias content: framePanel.content

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    // Driven by the slide progress, not framePanel.visible: an item inside a hidden
    // window is itself hidden, which would keep the window closed for good
    visible: framePanel.progress > 0.001
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "frame-drawer"
    WlrLayershell.keyboardFocus: modal && open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    // A modal drawer covers the whole screen while open: the compositor's focus
    // grab treats a click inside a click-through window as outside it, which
    // closed the panel on every press. Clicks outside the panel are caught below.
    // Non-modal drawers stay click-through everywhere except the panel.
    mask: modal && open ? null : panelMask
    // The region follows a proxy with explicit window coordinates. Following the
    // item nested inside the panel missed the panel moving (a toast widening
    // shifts it left), which left the clickable area in the wrong place.
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

    // Click away from the panel closes a modal drawer
    MouseArea {
        anchors.fill: parent
        enabled: win.modal && win.open
        onPressed: win.open = false
    }

    FramePanel { id: framePanel }
}
