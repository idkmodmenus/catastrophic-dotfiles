import QtQuick

// Measures how fast an item moves so a MotionBlur can follow it. Bind x/y to
// the moving position; blurX/blurY give the smear length in pixels, and
// `moving` is true only while there is something to smear.
QtObject {
    id: tracker

    property real x: 0
    property real y: 0
    // Smear length per pixel moved per 60 Hz frame, and its ceiling
    property real strength: 1.7
    property real maxBlur: 70

    property real vx: 0
    property real vy: 0
    readonly property real blurX: Math.max(-maxBlur, Math.min(maxBlur, vx * strength))
    readonly property real blurY: Math.max(-maxBlur, Math.min(maxBlur, vy * strength))
    readonly property bool moving: Math.abs(blurX) > 0.75 || Math.abs(blurY) > 0.75

    property real _lastX: 0
    property real _lastY: 0
    property double _lastT: 0

    function _sample(): void {
        const now = Date.now()
        const dt = now - _lastT
        if (_lastT > 0 && dt > 0 && dt < 120) {
            // Smoothed, in px per 60 Hz frame
            vx = vx * 0.4 + (x - _lastX) * 16.7 / dt * 0.6
            vy = vy * 0.4 + (y - _lastY) * 16.7 / dt * 0.6
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
        interval: 50
        onTriggered: { tracker.vx = 0; tracker.vy = 0 }
    }
}
