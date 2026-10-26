import QtQuick
import qs.CustomTheme

// Filled line graph of values between 0 and `max`, newest on the right
Canvas {
    id: spark

    property var values: []
    property real max: 1
    property color tone: Theme.primary

    implicitHeight: 48
    onValuesChanged: requestPaint()
    onToneChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        const v = values
        if (!v || v.length < 2 || width <= 0 || height <= 0) return
        const step = width / (v.length - 1)
        const y = x => height - 2 - Math.max(0, Math.min(1, x / max)) * (height - 4)

        ctx.beginPath()
        ctx.moveTo(0, height)
        for (let i = 0; i < v.length; i++)
            ctx.lineTo(i * step, y(v[i]))
        ctx.lineTo(width, height)
        ctx.closePath()
        ctx.fillStyle = Qt.rgba(tone.r, tone.g, tone.b, 0.18)
        ctx.fill()

        ctx.beginPath()
        for (let i = 0; i < v.length; i++) {
            if (i === 0) ctx.moveTo(0, y(v[i]))
            else ctx.lineTo(i * step, y(v[i]))
        }
        ctx.strokeStyle = tone
        ctx.lineWidth = 2
        ctx.lineJoin = "round"
        ctx.stroke()
    }
}
