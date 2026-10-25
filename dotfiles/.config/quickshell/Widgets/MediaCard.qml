import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

// Now playing: cover art, title, artist and transport controls
Card {
    id: card

    // Prefer a player that is actually playing
    readonly property var player: {
        const list = Mpris.players.values
        return list.find(p => p.isPlaying) ?? list[0] ?? null
    }
    readonly property bool active: player !== null

    implicitWidth: 300
    implicitHeight: 112

    RowLayout {
        anchors.fill: parent
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 84
            Layout.preferredHeight: 84
            radius: 14
            color: Theme.surface_container_highest
            clip: true

            Image {
                anchors.fill: parent
                source: card.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                text: "󰝚"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 30
                color: Theme.on_surface_variant
                visible: !card.player?.trackArtUrl
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: card.active ? (card.player.trackTitle || card.player.identity) : "Nothing playing"
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.on_surface
            }
            Text {
                Layout.fillWidth: true
                text: card.player?.trackArtist ?? ""
                elide: Text.ElideRight
                font.family: Theme.fontFamilyRegular
                font.pixelSize: 12
                color: Theme.on_surface_variant
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                spacing: 6
                enabled: card.active

                component Ctl: Rectangle {
                    id: ctl
                    property string glyph
                    property bool primaryStyle: false
                    signal clicked()
                    implicitWidth: primaryStyle ? 44 : 34
                    implicitHeight: 34
                    radius: height / 2
                    color: primaryStyle ? Theme.primary
                        : area.containsMouse ? Theme.surface_container_highest : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: ctl.glyph
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: ctl.primaryStyle ? Theme.on_primary : Theme.on_surface
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ctl.clicked()
                    }
                }

                Ctl { glyph: "󰒮"; onClicked: card.player?.previous() }
                Ctl {
                    glyph: card.player?.isPlaying ? "󰏤" : "󰐊"
                    primaryStyle: true
                    onClicked: if (card.player) card.player.isPlaying = !card.player.isPlaying
                }
                Ctl { glyph: "󰒭"; onClicked: card.player?.next() }
            }
        }
    }
}
