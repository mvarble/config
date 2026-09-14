import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import ".."

// Now-playing card with previous / play-pause / next for the most relevant
// MPRIS player: the first one playing, else the first one. Hidden when no
// player exists.
Rectangle {
    id: root

    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    visible: player !== null
    implicitWidth: 360
    implicitHeight: 64
    radius: Theme.radius
    color: Theme.cardBackground
    border.color: Theme.cardBorder

    component MediaButton: Rectangle {
        id: button

        property string glyph: ""

        signal activated

        implicitWidth: 40
        implicitHeight: 40
        radius: 8
        color: area.containsMouse ? Theme.surfaceAlt : "transparent"
        opacity: enabled ? 1 : Theme.mutedOpacity

        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: Theme.text
            font.family: Theme.glyphFont
            font.pixelSize: 22
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.activated()
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 10
        }
        spacing: 4

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.player?.trackTitle || root.player?.identity || ""
                color: Theme.text
                font.pixelSize: Theme.fontSize
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
                elide: Text.ElideRight
            }
        }

        // Material Design nerd-font glyphs: skip_previous, play/pause, skip_next.
        MediaButton {
            glyph: "\u{F04AE}"
            enabled: root.player?.canGoPrevious ?? false
            onActivated: root.player.previous()
        }

        MediaButton {
            glyph: root.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}"
            enabled: root.player?.canTogglePlaying ?? false
            onActivated: root.player.togglePlaying()
        }

        MediaButton {
            glyph: "\u{F04AD}"
            enabled: root.player?.canGoNext ?? false
            onActivated: root.player.next()
        }
    }
}
