import QtQuick
import qs.CustomTheme
import qs.Widgets

// A panel that opens from one edge of the screen. Top panels hang from the
// frame's top band in its colour, joined by concave corners, and slide out
// from behind it. Bottom ones float above the dock and right ones beside the
// windows as cards that fade, settle from a slight scale and drift in.
Item {
    id: root

    property string edge: "top"   // top | bottom | right
    property bool open: false
    property real padding: 20
    // Shifts the card along its edge from the centre of the screen
    property real alongOffset: 0
    // Right edge only: sit at the top, under the bar, instead of centred
    property bool alignStart: false
    default property alias content: holder.data

    readonly property real progress: _progress
    property real _progress: open ? 1 : 0
    Behavior on _progress { NumberAnimation { duration: 340; easing.type: Easing.OutQuint } }

    readonly property bool vertical: edge === "right"
    readonly property bool attached: edge === "top"
    readonly property int fillet: 18

    implicitWidth: holder.childrenRect.width + padding * 2
    implicitHeight: holder.childrenRect.height + padding * 2
    width: implicitWidth
    height: implicitHeight
    visible: progress > 0.001

    // Room left for the dock's dots at the bottom
    readonly property real bottomClear: Geometry.bottomReserve + Geometry.gap * 2

    x: edge === "right" ? parent.width - Geometry.sideInset - width
        : parent.width / 2 - width / 2 + alongOffset
    y: edge === "top" ? Geometry.barBottom
        : edge === "bottom" ? parent.height - bottomClear - height
        : alignStart ? Geometry.barBottom + Geometry.gap
        : parent.height / 2 - height / 2 + alongOffset

    readonly property real drift: attached ? 0 : (1 - progress) * 28
    readonly property real cardScale: attached ? 1 : 0.94 + 0.06 * progress
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
    opacity: attached ? 1 : Math.min(1, progress * 2)

    // The area that counts as "over the card"; also the window's input region
    readonly property alias hit: hitArea
    readonly property bool hovered: panelHover.hovered
    Item {
        id: hitArea
        width: root.width
        height: root.height
        HoverHandler { id: panelHover }
    }

    // Swallow clicks so they don't fall through to the window below
    MouseArea { anchors.fill: parent }

    // Where the body sits while sliding out of the band (attached panels)
    readonly property real slideY: attached ? 2 - (1 - progress) * (height + 2) : 0
    // Transparent margin around a card so its blur can spread past its edges
    readonly property int blurPad: attached ? 0 : 64

    // Smears the panel along its direction of travel while it moves
    MotionTracker {
        id: motion
        x: root.edge === "right" ? root.drift : 0
        y: root.attached ? root.slideY
            : root.edge === "top" ? -root.drift : root.edge === "bottom" ? root.drift : 0
    }

    // Clipped at the band's edge for attached panels, so they slide out from
    // behind it; cards are not clipped and move with the transform above
    Item {
        id: body
        x: root.attached ? -root.fillet : -root.blurPad
        y: root.attached ? -2 : -root.blurPad
        width: root.width + (root.attached ? root.fillet * 2 : root.blurPad * 2)
        height: root.height + (root.attached ? 2 : root.blurPad * 2)
        clip: root.attached

        layer.enabled: motion.moving && root.visible
        layer.smooth: true
        layer.effect: MotionBlur {
            dx: motion.blurX
            dy: motion.blurY
            itemWidth: body.width
            itemHeight: body.height
        }

        Item {
            x: root.attached ? root.fillet : root.blurPad
            y: root.attached ? root.slideY : root.blurPad
            width: root.width
            height: root.height

            AttachedShape {
                visible: root.attached
                anchors.fill: parent
                fillet: root.fillet
            }
            Island {
                visible: !root.attached
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
