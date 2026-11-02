import QtQuick
import qs.CustomTheme
import qs.Widgets

Item {
    id: root

    property string edge: "top"
    property bool open: false
    property real padding: 20
    property real alongOffset: 0
    property bool alignStart: false
    default property alias content: holder.data

    readonly property real progress: _progress
    property real _progress: open ? 1 : 0
    Behavior on _progress { NumberAnimation { duration: root.open ? 420 : 220; easing.type: Easing.BezierSpline; easing.bezierCurve: root.open ? [0.05, 0.7, 0.1, 1, 1, 1] : [0.3, 0, 0.8, 0.15, 1, 1] } }

    implicitWidth: holder.childrenRect.width + padding * 2
    implicitHeight: holder.childrenRect.height + padding * 2
    width: implicitWidth
    height: implicitHeight
    visible: progress > 0.001

    x: edge === "right" ? parent.width - Geometry.sideInset - width
        : parent.width / 2 - width / 2 + alongOffset
    y: edge === "top" || (edge === "right" && alignStart) ? Geometry.barBottom + Geometry.gap
        : edge === "bottom" ? parent.height - Geometry.gap * 2 - height
        : parent.height / 2 - height / 2 + alongOffset

    readonly property real drift: (1 - progress) * 28
    readonly property real cardScale: 0.94 + 0.06 * progress
    transform: [
        Scale {
            origin.x: root.edge === "right" ? root.width : root.width / 2
            origin.y: root.edge === "top" ? 0 : root.edge === "bottom" ? root.height : root.height / 2
            xScale: root.cardScale
            yScale: root.cardScale
        },
        Translate {
            x: root.edge === "right" ? root.drift : 0
            y: root.edge === "top" ? -root.drift : root.edge === "bottom" ? root.drift : 0
        }
    ]
    opacity: Math.min(1, progress * 2)

    readonly property alias hit: hitArea
    readonly property bool hovered: panelHover.hovered
    Item {
        id: hitArea
        width: root.width
        height: root.height
        HoverHandler { id: panelHover }
    }

    MouseArea { anchors.fill: parent }

    readonly property int blurPad: 32

    MotionTracker {
        id: motion
        x: root.edge === "right" ? root.drift : 0
        y: root.edge === "top" ? -root.drift : root.edge === "bottom" ? root.drift : 0
        enabled: root.visible
    }

    Item {
        id: body
        x: -root.blurPad
        y: -root.blurPad
        width: root.width + root.blurPad * 2
        height: root.height + root.blurPad * 2

        layer.enabled: motion.active && root.visible
        layer.smooth: true
        layer.effect: MotionBlur {
            dx: motion.blurX
            dy: motion.blurY
            itemWidth: body.width
            itemHeight: body.height
        }

        Item {
            x: root.blurPad
            y: root.blurPad
            width: root.width
            height: root.height

            Island {
                anchors.fill: parent
                radius: Geometry.cardRadius
            }

            Item {
                id: holder
                x: root.padding
                y: root.padding
            }
        }
    }
}
