import QtQuick
import QtQuick.Layouts
import "../services"
import ".."

// Minutes-only timer launcher. Presets only *select* a value; the accent play
// button is what enqueues. It holds no reference to what it started, so
// pressing play repeatedly stacks up independent timers.
ColumnLayout {
    id: root

    property int pendingMinutes: 15

    readonly property int minMinutes: 1
    readonly property int maxMinutes: 600

    function adjust(delta) {
        pendingMinutes = Math.max(minMinutes, Math.min(maxMinutes, pendingMinutes + delta));
    }

    spacing: 8

    // ------------------------- Presets -------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: [15, 30, 45, 60]

            Rectangle {
                required property int modelData

                Layout.fillWidth: true
                implicitHeight: 26
                radius: 6
                color: root.pendingMinutes === modelData ? Theme.accent : (presetArea.containsMouse ? Theme.surfaceAlt : "transparent")
                border.color: Theme.cardBorder

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData + "m"
                    color: root.pendingMinutes === parent.modelData ? Theme.surface : Theme.text
                    font.pixelSize: Theme.fontSize - 2
                }

                MouseArea {
                    id: presetArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.pendingMinutes = parent.modelData
                }
            }
        }
    }

    // ------------------------- Stepper + play -------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        StepButton {
            glyph: "−"
            onActivated: root.adjust(-1)
        }

        // The minutes readout. Scrolling anywhere over it steps by one, the
        // same amount as the buttons.
        Item {
            Layout.fillWidth: true
            implicitHeight: 34

            Text {
                anchors.centerIn: parent
                text: root.pendingMinutes + " min"
                color: Theme.text
                font.pixelSize: Theme.titleSize
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent

                // High-resolution wheels emit many sub-notch events, so steps
                // are accumulated and only applied per full notch (120 units)
                // rather than once per event.
                property int wheelAccum: 0

                onWheel: function (wheel) {
                    wheelAccum += wheel.angleDelta.y;
                    while (wheelAccum >= 120) {
                        wheelAccum -= 120;
                        root.adjust(1);
                    }
                    while (wheelAccum <= -120) {
                        wheelAccum += 120;
                        root.adjust(-1);
                    }
                    wheel.accepted = true;
                }
            }
        }

        StepButton {
            glyph: "+"
            onActivated: root.adjust(1)
        }

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: Theme.accent
            opacity: playArea.containsMouse ? 0.85 : 1

            Text {
                anchors.centerIn: parent
                text: "▶"
                color: Theme.surface
                font.family: Theme.glyphFont
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: playArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Timers.start(root.pendingMinutes)
            }
        }
    }
}
