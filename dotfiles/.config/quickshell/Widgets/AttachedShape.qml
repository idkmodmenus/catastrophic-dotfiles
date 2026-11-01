import QtQuick
import QtQuick.Shapes
import qs.CustomTheme

// Body of a panel hanging from the frame's top band: the frame's colour,
// rounded at the bottom and joined to the band by concave corners. Size it to
// the panel; the corners reach `fillet` px out to either side and the body
// `overlap` px up into the band so no seam shows.
Shape {
    id: shape

    property real radius: Geometry.cardRadius
    property real fillet: 18
    property real overlap: 2

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: Theme.surface
        strokeColor: "transparent"
        PathSvg {
            readonly property real w: shape.width
            readonly property real h: shape.height
            readonly property real r: Math.min(shape.radius, shape.height / 2)
            readonly property real f: shape.fillet
            readonly property real o: shape.overlap
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
