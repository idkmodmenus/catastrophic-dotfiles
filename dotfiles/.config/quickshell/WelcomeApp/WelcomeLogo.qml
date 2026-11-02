import QtQuick
import QtQuick.Effects
import qs.CustomTheme

Item {
    id: root

    property real blurAmount: 1
    property real planetScale: 0
    property real planetOpacity: 0
    property real planetRotation: 0
    property real bob: 0
    property real s1: 0
    property real s2: 0
    property real s3: 0

    implicitWidth: 168
    implicitHeight: 128

    function play(): void {
        intro.stop()
        blurAmount = 1; planetScale = 0; planetOpacity = 0; planetRotation = 0
        s1 = 0; s2 = 0; s3 = 0
        intro.start()
    }

    Image {
        id: planet
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.bob
        width: 112
        height: 112
        source: Qt.resolvedUrl("../FrameApp/logo.svg")
        sourceSize: Qt.size(224, 224)
        fillMode: Image.PreserveAspectFit
        smooth: true
        scale: root.planetScale
        opacity: root.planetOpacity
        rotation: root.planetRotation
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: Theme.primary
            blurEnabled: root.blurAmount > 0
            blur: root.blurAmount
            blurMax: 48
        }
    }

    Text {
        x: root.width - 30; y: 6 + root.bob * 1.6
        text: "\u{f0ae2}"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        color: Theme.primary
        opacity: root.s1
        scale: root.s1
    }
    Text {
        x: root.width - 12; y: 34 - root.bob * 1.2
        text: "\u{f0ae2}"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: Theme.primary
        opacity: root.s2
        scale: root.s2
    }
    Text {
        x: 10; y: root.height - 34 + root.bob * 1.4
        text: "\u{f0ae2}"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: Theme.primary
        opacity: root.s3
        scale: root.s3
    }

    ParallelAnimation {
        id: intro
        running: true

        SequentialAnimation {
            NumberAnimation { target: root; property: "planetRotation"; from: 0; to: 750; duration: 1000; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "planetRotation"; to: 710; duration: 300; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "planetRotation"; to: 725; duration: 350; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "planetRotation"; to: 720; duration: 250; easing.type: Easing.OutQuad }
            ScriptAction { script: root.planetRotation = 0 }
        }
        SequentialAnimation {
            NumberAnimation { target: root; property: "planetScale"; from: 0; to: 1.08; duration: 1000; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "planetScale"; to: 0.96; duration: 200; easing.type: Easing.InOutQuad }
            NumberAnimation { target: root; property: "planetScale"; to: 1; duration: 250; easing.type: Easing.OutBack }
        }
        NumberAnimation { target: root; property: "planetOpacity"; from: 0; to: 1; duration: 600; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "blurAmount"; from: 1; to: 0; duration: 900; easing.type: Easing.OutCubic }
        SequentialAnimation {
            PauseAnimation { duration: 1100 }
            NumberAnimation { target: root; property: "s1"; from: 0; to: 1.12; duration: 450; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "s1"; to: 1; duration: 350; easing.type: Easing.InOutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 1250 }
            NumberAnimation { target: root; property: "s2"; from: 0; to: 1.12; duration: 450; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "s2"; to: 1; duration: 350; easing.type: Easing.InOutQuad }
        }
        SequentialAnimation {
            PauseAnimation { duration: 1400 }
            NumberAnimation { target: root; property: "s3"; from: 0; to: 1.12; duration: 450; easing.type: Easing.OutQuad }
            NumberAnimation { target: root; property: "s3"; to: 1; duration: 350; easing.type: Easing.InOutQuad }
        }
    }

    SequentialAnimation {
        running: root.visible
        loops: Animation.Infinite
        NumberAnimation { target: root; property: "bob"; from: 0; to: -4; duration: 2500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "bob"; from: -4; to: 0; duration: 2500; easing.type: Easing.InOutQuad }
    }
}
