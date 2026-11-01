import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import qs.CustomTheme
import qs.DrawersApp

// Screen frame: a thin border around the windows with rounded inner corners,
// widening at the top into a band that holds three separate island pills.
// Hover popouts drop below the island they came from as free-standing cards.
Scope {
    id: frame

    required property var modelData

    // Space is reserved through empty, click-through surfaces so windows tile
    // below the islands; the drawing surface itself ignores exclusive zones.
    PanelWindow {
        screen: frame.modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: 1
        exclusiveZone: Geometry.barBottom
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "frame-edge"
    }
    PanelWindow {
        screen: frame.modelData
        anchors { left: true; top: true; bottom: true }
        implicitWidth: 1
        exclusiveZone: Geometry.thickness
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "frame-edge"
    }
    PanelWindow {
        screen: frame.modelData
        anchors { right: true; top: true; bottom: true }
        implicitWidth: 1
        exclusiveZone: Geometry.thickness
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "frame-edge"
    }
    // Also keeps the dock's dots clear of the windows
    PanelWindow {
        screen: frame.modelData
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 1
        exclusiveZone: Geometry.bottomReserve
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "frame-edge"
    }

    PanelWindow {
        id: win
        screen: frame.modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "frame"
        // Only the islands and an open popout take input; the rest is click-through
        mask: Region {
            item: leftMask
            regions: [
                Region { item: centerMask },
                Region { item: rightMask },
                Region { item: popoutMask }
            ]
        }

        // Proxies in window coordinates: a region that follows an item nested in
        // the bar can miss it moving when an island changes width
        Item { id: leftMask; x: bar.leftIsland.x; y: bar.leftIsland.y; width: bar.leftIsland.width; height: bar.leftIsland.height }
        Item { id: centerMask; x: bar.centerIsland.x; y: bar.centerIsland.y; width: bar.centerIsland.width; height: bar.centerIsland.height }
        Item { id: rightMask; x: bar.rightIsland.x; y: bar.rightIsland.y; width: bar.rightIsland.width; height: bar.rightIsland.height }

        // Follows the popout only while it is showing, so a hidden popout never
        // blocks the windows below the bar
        Item {
            id: popoutMask
            x: popout.x
            y: popout.y
            width: popout.visible ? popout.width : 0
            height: popout.visible ? popout.height : 0
        }

        // One static shape, redrawn only when the theme changes
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.surface
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill

                PathRectangle {
                    width: win.width
                    height: win.height
                }
                PathRectangle {
                    x: Geometry.thickness
                    y: Geometry.barBottom
                    width: win.width - 2 * Geometry.thickness
                    height: win.height - Geometry.barBottom - Geometry.thickness
                    radius: Geometry.frameRadius
                }
            }
        }

        Popout {
            id: popout
            bar: bar
            winWidth: win.width
        }

        Bar {
            id: bar
            width: win.width
            height: Geometry.barBottom
        }

        Binding { target: bar; property: "popoutHovered"; value: popout.hovered }
        Binding { target: DrawerState; property: "popoutOpen"; value: popout.shown }
    }
}
