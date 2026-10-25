import QtQuick
import QtQuick.Shapes
import qs.CustomTheme

// A panel in the frame's colour that grows out of one of its edges and is
// joined to it by concave corners. The shape is drawn once for the top edge
// and flipped or rotated for the others.
Item {
    id: root

    property string edge: "top"   // top | bottom | right
    property bool open: false
    property real padding: 20
    // Shifts the panel along its edge from the centre of the free area
    property real alongOffset: 0
    // Right edge only: sit at the top instead of centred
    property bool alignStart: false
    default property alias content: holder.data

    readonly property real progress: _progress
    property real _progress: open ? 1 : 0
    Behavior on _progress { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }

    readonly property bool vertical: edge === "right"
    readonly property real along: vertical ? height : width
    readonly property real depth: vertical ? width : height

    implicitWidth: holder.childrenRect.width + padding * 2
    implicitHeight: holder.childrenRect.height + padding * 2
    width: implicitWidth
    height: implicitHeight
    visible: progress > 0.001

    // Free area between the bar and the other three frame edges
    readonly property real areaX: Geometry.barWidth
    readonly property real areaW: parent ? parent.width - Geometry.barWidth - Geometry.thickness : 0

    x: edge === "right" ? parent.width - Geometry.thickness - width
        : areaX + areaW / 2 - width / 2 + alongOffset
    y: edge === "top" ? Geometry.thickness
        : edge === "bottom" ? parent.height - Geometry.thickness - height
        : alignStart ? Geometry.thickness + 14
        : parent.height / 2 - height / 2 + alongOffset

    // Slides in from behind the frame
    transform: Translate {
        x: root.edge === "right" ? (1 - root.progress) * (root.width + Geometry.thickness) : 0
        y: root.edge === "top" ? -(1 - root.progress) * (root.height + Geometry.thickness)
            : root.edge === "bottom" ? (1 - root.progress) * (root.height + Geometry.thickness) : 0
    }
    opacity: Math.min(1, progress * 3)

    // The area that counts as "over the panel": its rectangle plus the frame
    // border it grows from and the curved corners beside it, so resting the
    // pointer there keeps it open. Also used as the window's input region.
    readonly property alias hit: hitArea
    readonly property bool hovered: panelHover.hovered
    Item {
        id: hitArea
        x: root.vertical ? 0 : -Geometry.fillet
        y: root.edge === "top" ? -Geometry.thickness : root.vertical ? -Geometry.fillet : 0
        width: root.width + (root.vertical ? Geometry.thickness : Geometry.fillet * 2)
        height: root.height + (root.vertical ? Geometry.fillet * 2 : Geometry.thickness)
        HoverHandler { id: panelHover }
    }

    // Swallow clicks so they don't fall through to the window below
    MouseArea { anchors.fill: parent }

    Item {
        id: shapeHost
        width: root.along
        height: root.depth
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        rotation: root.vertical ? 90 : 0
        transform: Scale {
            yScale: root.edge === "bottom" ? -1 : 1
            origin.y: shapeHost.height / 2
        }

        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: Theme.surface
                strokeColor: "transparent"
                PathSvg {
                    readonly property real w: shapeHost.width
                    readonly property real h: shapeHost.height
                    readonly property real r: Geometry.panelRadius
                    readonly property real f: Geometry.fillet
                    readonly property real o: Geometry.overshoot
                    path: "M " + (-f) + " " + (-o)
                        + " L " + (w + f) + " " + (-o)
                        + " L " + (w + f) + " 0"
                        + " A " + f + " " + f + " 0 0 0 " + w + " " + f
                        + " L " + w + " " + (h - r)
                        + " A " + r + " " + r + " 0 0 1 " + (w - r) + " " + h
                        + " L " + r + " " + h
                        + " A " + r + " " + r + " 0 0 1 0 " + (h - r)
                        + " L 0 " + f
                        + " A " + f + " " + f + " 0 0 0 " + (-f) + " 0 Z"
                }
            }
        }
    }

    Item {
        id: holder
        x: root.padding
        y: root.padding
    }
}
