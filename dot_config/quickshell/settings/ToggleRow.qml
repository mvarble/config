import QtQuick
import QtQuick.Layouts
import ".."

// Glyph icon + label + trailing pill switch (e.g. "hyprsunset  [on/off]").
RowLayout {
    id: root

    property string icon: ""
    property string label: ""
    property bool checked: false
    signal toggled()

    spacing: 10

    Text {
        Layout.preferredWidth: 22
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        font.family: Theme.glyphFont
        font.pixelSize: 18
        color: Theme.text
    }

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.fontSize
        elide: Text.ElideRight
    }

    Rectangle {
        implicitWidth: 36
        implicitHeight: 20
        radius: 10
        color: root.checked ? Theme.accent : Theme.surfaceAlt

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDuration
            }
        }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            x: root.checked ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.surface
            border.color: Theme.border

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggled()
        }
    }
}
