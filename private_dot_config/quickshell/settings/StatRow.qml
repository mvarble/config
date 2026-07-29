import QtQuick
import QtQuick.Layouts
import ".."

// Glyph icon + label + trailing value text (e.g. "CPU .... 42%").
RowLayout {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property color iconColor: Theme.text

    spacing: 10

    Text {
        Layout.preferredWidth: 22
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        font.family: Theme.glyphFont
        font.pixelSize: 18
        color: root.iconColor
    }

    Text {
        Layout.fillWidth: true
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.fontSize
        elide: Text.ElideRight
    }

    Text {
        text: root.value
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 2
    }
}
