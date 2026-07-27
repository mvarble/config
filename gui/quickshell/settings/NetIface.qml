import QtQuick
import QtQuick.Layouts
import ".."

// One network interface row: glyph (or wifi signal bands), interface name,
// IP address and transfer rates. Renders muted when disconnected.
RowLayout {
    id: root

    property bool connected: false
    property string icon: ""        // glyph shown when wifiBars is false
    property bool wifiBars: false   // show reception bands instead of a glyph
    property int linkQuality: -1    // 0..70, -1 = unknown
    property string title: ""       // interface name, or generic label
    property string subtitle: ""    // IP address, or "disconnected"
    property string rxText: ""
    property string txText: ""
    property bool menuButton: false
    signal menuClicked()

    spacing: 10
    opacity: connected ? 1 : Theme.mutedOpacity

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animDuration
        }
    }

    Item {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22

        Text {
            anchors.centerIn: parent
            visible: !root.wifiBars
            text: root.icon
            font.family: Theme.glyphFont
            font.pixelSize: 18
            color: Theme.text
        }

        // Four reception bands; highlighted count follows link quality.
        Row {
            visible: root.wifiBars
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            spacing: 2

            Repeater {
                model: 4

                Rectangle {
                    required property int index
                    readonly property int bandLevel: root.linkQuality < 0 ? 0 : Math.round(root.linkQuality / 70 * 4)

                    width: 4
                    height: 5 + index * 3
                    y: 14 - height
                    radius: 1
                    color: index < bandLevel ? Theme.text : Theme.surfaceAlt
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.text
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            // Chevron (›) drawn from two rotated rectangles — indicates the
            // row opens another dialog. Pure Qt Quick, no font dependency.
            Item {
                visible: root.menuButton
                Layout.preferredWidth: 14
                Layout.preferredHeight: 22

                Rectangle {
                    width: 9
                    height: 2
                    radius: 1
                    x: 2
                    y: 7
                    rotation: 45
                    color: menuArea.containsMouse ? Theme.text : Theme.subtext
                }

                Rectangle {
                    width: 9
                    height: 2
                    radius: 1
                    x: 2
                    y: 12
                    rotation: -45
                    color: menuArea.containsMouse ? Theme.text : Theme.subtext
                }

                MouseArea {
                    id: menuArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.menuClicked()
                }
            }
        }

        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 3
        }

        Text {
            visible: root.connected
            text: "↓ " + root.rxText + "   ↑ " + root.txText
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 3
        }
    }
}
