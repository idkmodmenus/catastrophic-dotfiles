import QtQuick

// Measures how fast an item moves so a MotionBlur can follow it. Bind x/y to
// the moving position; blurX/blurY give the smear length in pixels, and
// `moving` is true only while there is something to smear.
QtObject {
    id: tracker

    property real x: 0
    property real y: 0
    // Smear length per pixel moved per 60 Hz frame, and its ceiling
    property real strength: 1.3
    property real maxBlur: 44

    property real vx: 0
    property real vy: 0
    // Speeds below this (px per 60 Hz frame) get no smear, so the slow tail
    // of an ease-out lands crisp instead of looking like it drags
    property real deadZone: 1.5

    readonly property real blurX: _smear(vx)
    readonly property real blurY: _smear(vy)
    readonly property bool moving: Math.abs(blurX) > 1 || Math.abs(blurY) > 1

    function _smear(v: real): real {
        const a = Math.max(0, Math.abs(v) - deadZone) * strength
        return Math.sign(v) * Math.min(maxBlur, a)
    }

    property real _lastX: 0
    property real _lastY: 0
    property double _lastT: 0

    function _sample(): void {
        const now = Date.now()
        const dt = now - _lastT
        if (_lastT > 0 && dt > 0 && dt < 120) {
            // Smoothed, in px per 60 Hz frame
            // Light smoothing only, so the blur keeps up with the motion
            vx = vx * 0.2 + (x - _lastX) * 16.7 / dt * 0.8
            vy = vy * 0.2 + (y - _lastY) * 16.7 / dt * 0.8
        }
        _lastX = x
        _lastY = y
        _lastT = now
        settle.restart()
    }

    onXChanged: _sample()
    onYChanged: _sample()

    // No movement for a moment means it has stopped
    property Timer settle: Timer {
        interval: 34
        onTriggered: { tracker.vx = 0; tracker.vy = 0 }
    }
}
