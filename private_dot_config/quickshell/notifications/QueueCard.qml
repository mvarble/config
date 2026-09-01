import QtQuick
import QtQuick.Layouts
import ".."

// One row of the sidebar queue. Used for both notifications and timers; the
// caller supplies the text, the accent stripe color and what dismissing does.
Rectangle {
    id: root

    // The queue element this card renders. Set by the sidebar's Loader.
    property var entry

    property string title: ""
    property string subtitle: ""
    property string body: ""
    property color accentColor: Theme.accent

    // Timers show a clock, which needs tabular digits so it doesn't jitter.
    property bool monospaceTitle: false

    // NotificationAction list, or null.
    property var actions: null

    signal dismissed

    implicitHeight: layout.implicitHeight + 20
    radius: Theme.radius
    color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85)
    border.color: Theme.cardBorder

    readonly property int stripeWidth: 3

    // Urgency / state stripe down the left edge. It is a rounded rectangle
    // sharing the card's radius, clipped to the leftmost few pixels, so what
    // survives is exactly the left corner arcs: the stripe hugs the card's
    // curve and tapers out at the ends rather than cutting straight across
    // them. Drawing it as a clipped sliver rather than as a backing behind the
    // card matters because the card face is translucent (frosted by
    // Hyprland's blur) — an accent panel behind it would tint the whole card.
    Item {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: root.stripeWidth
        clip: true

        Rectangle {
            width: Theme.radius * 2
            height: parent.height
            radius: Theme.radius
            color: root.accentColor
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }

    ColumnLayout {
        id: layout
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 10
            topMargin: 10
            bottomMargin: 10
        }
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    color: Theme.subtext
                    opacity: Theme.mutedOpacity
                    font.pixelSize: Theme.fontSize - 3
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.text
                    font.pixelSize: root.monospaceTitle ? Theme.titleSize : Theme.fontSize
                    font.bold: true
                    font.family: root.monospaceTitle ? Theme.glyphFont : font.family
                    elide: Text.ElideRight
                }
            }

            // Dismiss. Always reachable rather than hover-only: the queue is
            // cleared by hand, so this is the primary control.
            Text {
                text: "✕"
                color: closeArea.containsMouse ? Theme.crit : Theme.subtext
                opacity: hover.containsMouse || closeArea.containsMouse ? 1 : Theme.mutedOpacity
                font.pixelSize: Theme.fontSize

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    onClicked: root.dismissed()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.body !== ""
            text: root.body
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 1
            wrapMode: Text.WordWrap
            maximumLineCount: 6
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        // Notification actions, when the sender supplied any.
        Flow {
            Layout.fillWidth: true
            visible: root.actions !== null && root.actions.length > 0
            spacing: 6

            Repeater {
                model: root.actions

                Rectangle {
                    required property var modelData

                    width: actionLabel.implicitWidth + 16
                    height: actionLabel.implicitHeight + 8
                    radius: 6
                    color: actionArea.containsMouse ? Theme.accent : "transparent"
                    border.color: Theme.cardBorder

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: actionArea.containsMouse ? Theme.surface : Theme.text
                        font.pixelSize: Theme.fontSize - 2
                    }

                    MouseArea {
                        id: actionArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: parent.modelData.invoke()
                    }
                }
            }
        }
    }
}
