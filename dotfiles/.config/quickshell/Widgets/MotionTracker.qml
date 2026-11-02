import QtQuick

QtObject {
    id: tracker

    property real x: 0
    property real y: 0
    property real strength: 1.2
    property real maxBlur: 40
    property real deadZone: 1.0

    property real vx: 0
    property real vy: 0

    readonly property real blurX: _smear(vx)
    readonly property real blurY: _smear(vy)
    readonly property bool active: _awake
    readonly property bool moving: _awake

    function _smear(v: real): real {
        const s = Math.abs(v)
        const over = s <= deadZone ? 0 : (s - deadZone) * (1 - Math.exp(-(s - deadZone) / deadZone))
        return Math.sign(v) * Math.min(maxBlur, over * strength)
    }

    property bool _awake: false
    property real _lastX: 0
    property real _lastY: 0
    property int _still: 0

    function _wake(): void {
        if (!_awake) {
            _still = 0
            _awake = true
        }
    }

    property bool enabled: true
    onXChanged: enabled ? _wake() : (_lastX = x)
    onYChanged: enabled ? _wake() : (_lastY = y)
    onEnabledChanged: if (!enabled) { _lastX = x; _lastY = y; vx = 0; vy = 0; _awake = false }

    function _step(frameTime: real): void {
        const frames = Math.max(0.25, Math.min(4, (frameTime > 0 ? frameTime : 1 / 60) * 60))
        const rx = (x - _lastX) / frames
        const ry = (y - _lastY) / frames
        _lastX = x
        _lastY = y
        vx = vx * 0.35 + rx * 0.65
        vy = vy * 0.35 + ry * 0.65

        if (rx === 0 && ry === 0 && Math.abs(vx) < 0.05 && Math.abs(vy) < 0.05) {
            if (++_still >= 3) {
                vx = 0
                vy = 0
                _awake = false
            }
        } else {
            _still = 0
        }
    }

    property FrameAnimation frames: FrameAnimation {
        running: tracker._awake
        onTriggered: tracker._step(frameTime)
    }

    Component.onCompleted: {
        _lastX = x
        _lastY = y
    }
}
