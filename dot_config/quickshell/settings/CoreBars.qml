import QtQuick
import QtQuick.Layouts
import ".."

// Vertically stacked horizontal usage bars (one per CPU core),
// colored by usage: green < 50%, yellow < 80%, red otherwise.
ColumnLayout {
    id: root

    property var usages: []

    spacing: 4

    Repeater {
        model: root.usages.length

        delegate: Rectangle {
            required property int index
            property real usage: root.usages[index] ?? 0

            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.surfaceAlt

            Rectangle {
                width: Math.max(0.02, parent.usage) * parent.width
                height: parent.height
                radius: 3
                color: parent.usage < 0.5 ? Theme.ok : (parent.usage < 0.8 ? Theme.warn : Theme.crit)

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }
    }
}
