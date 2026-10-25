import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import qs.CustomTheme
import qs.DrawersApp

// Caelestia-style screen frame: a slim vertical bar on the left that runs into
// a thin border around the screen, with rounded inner corners where the windows
// sit. One static shape, redrawn only when the theme changes.
Scope {
    id: frame

    required property var modelData

    readonly property int thickness: 10
    readonly property int barWidth: 44
    readonly property int radius: 24
    // Extra room at the bottom for the dock's dots, which sit on the frame edge
    readonly property int bottomZone: 20

    // The frame's edges are reserved through empty, click-through surfaces so
    // windows tile inside it; the frame itself ignores exclusive zones.
    PanelWindow {
        screen: frame.modelData
        anchors { left: true; top: true; bottom: true }
        implicitWidth: 1
        exclusiveZone: frame.barWidth
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "frame-edge"
    }
    PanelWindow {
        screen: frame.modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: 1
        exclusiveZone: frame.thickness
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "frame-edge"
    }
    PanelWindow {
        screen: frame.modelData
        anchors { right: true; top: true; bottom: true }
        implicitWidth: 1
        exclusiveZone: frame.thickness
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "frame-edge"
    }
    PanelWindow {
        screen: frame.modelData
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 1
        exclusiveZone: frame.bottomZone
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
        // Only the bar takes input; the rest of the surface is click-through
        mask: Region {
            item: sideBar
            regions: [Region { item: popoutMask }, Region { item: topEdge }]
        }

        // Follows the popout only while it is showing, so a hidden popout never
        // blocks the windows beside the bar
        Item {
            id: popoutMask
            x: popout.x
            y: popout.y
            width: popout.visible ? popout.width : 0
            height: popout.visible ? popout.height : 0
        }

        // The frame's top border opens the dashboard when the pointer rests on it
        Item {
            id: topEdge
            x: frame.barWidth + 120
            y: 0
            width: win.width - frame.barWidth - 240
            height: frame.thickness

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: DrawerState.topEdgeActivity()
                onPositionChanged: DrawerState.topEdgeActivity()
                onContainsMouseChanged: DrawerState.topEdgeInside = containsMouse
            }
        }

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
                    x: frame.barWidth
                    y: frame.thickness
                    width: win.width - frame.barWidth - frame.thickness
                    height: win.height - 2 * frame.thickness
                    radius: frame.radius
                }
            }
        }

        // Below the bar so the join is hidden behind its icons
        Popout {
            id: popout
            bar: sideBar
            winHeight: win.height
        }

        Bar {
            id: sideBar
            width: frame.barWidth
            height: win.height
        }

        Binding { target: sideBar; property: "popoutHovered"; value: popout.hovered }
    }
}
