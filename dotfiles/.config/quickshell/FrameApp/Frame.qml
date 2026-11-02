import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.CustomTheme
import qs.DrawersApp

Scope {
    id: frame

    required property var modelData

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
        id: win
        screen: frame.modelData
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "frame"
        mask: Region {
            item: leftMask
            regions: [
                Region { item: centerMask },
                Region { item: rightMask },
                Region { item: popoutMask }
            ]
        }

        Item { id: leftMask; x: bar.leftIsland.x; y: bar.leftIsland.y; width: bar.leftIsland.width; height: bar.leftIsland.height }
        Item { id: centerMask; x: bar.centerIsland.x; y: bar.centerIsland.y; width: bar.centerIsland.width; height: bar.centerIsland.height }
        Item { id: rightMask; x: bar.rightIsland.x; y: bar.rightIsland.y; width: bar.rightIsland.width; height: bar.rightIsland.height }

        Item {
            id: popoutMask
            x: popout.x
            y: popout.y
            width: popout.visible ? popout.width : 0
            height: popout.visible ? popout.height : 0
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
