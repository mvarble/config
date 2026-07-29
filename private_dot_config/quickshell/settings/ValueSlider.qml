import QtQuick
import QtQuick.Layouts
import ".."

// Glyph icon + slider (0..1) + percentage label, with an optional caption
// underneath. Built from a plain MouseArea and Rectangles instead of
// QtQuick.Controls' Slider, whose drags were being stolen by the
// ScrollView's Flickable in this panel.
//
// `sourceValue` is the externally observed value; it drives the handle
// whenever the user is not dragging. `applied` fires on user movement.
ColumnLayout {
    id: root

    property string icon: ""
    property string caption: ""
    property real sourceValue: 0
    // How long the handle keeps its dragged position after release while
    // waiting for the underlying service to report the new value back.
    property int settleDelay: 400
    signal applied(real value)

    // Displayed fraction, 0..1.
    property real position: 0

    spacing: 2

    Component.onCompleted: position = sourceValue

    onSourceValueChanged: {
        if (!dragArea.pressed && !settle.running)
            position = sourceValue;
    }

    // Shared by drag, click and scroll: clamp, display, emit, settle.
    function applyFraction(f) {
        f = Math.min(Math.max(f, 0), 1);
        position = f;
        applied(f);
        settle.restart();
    }

    // Scroll steps from a wheel event. Touchpads typically report pixel
    // deltas with a zero angle delta, so fall back to those (~40px/notch).
    function wheelSteps(event) {
        if (event.angleDelta.y !== 0)
            return event.angleDelta.y / 120;
        if (event.pixelDelta.y !== 0)
            return event.pixelDelta.y / 40;
        return 0;
    }

    function applyWheel(event) {
        const steps = wheelSteps(event);
        if (steps === 0)
            return;
        applyFraction(position + steps * 0.05);
        event.accepted = true;
    }

    Timer {
        id: settle
        interval: root.settleDelay
        onTriggered: if (!dragArea.pressed) root.position = root.sourceValue;
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Scrolling anywhere on the row adjusts the value (5% per notch).
        WheelHandler {
            onWheel: event => root.applyWheel(event)
        }

        Text {
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignHCenter
            text: root.icon
            font.family: Theme.glyphFont
            font.pixelSize: 18
            color: Theme.text
        }

        Item {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            // Groove.
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                height: 6
                radius: 3
                color: Theme.surfaceAlt

                // Fill.
                Rectangle {
                    width: root.position * parent.width
                    height: parent.height
                    radius: 3
                    color: Theme.accent
                }
            }

            // Handle.
            Rectangle {
                width: 16
                height: 16
                radius: 8
                x: root.position * (track.width - width)
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surface
                border.color: dragArea.pressed ? Theme.accent : Theme.border
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                // Do not let the surrounding Flickable steal drags.
                preventStealing: true

                function applyMouse(mouseX) {
                    root.applyFraction(mouseX / width);
                }

                onPressed: mouse => applyMouse(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        applyMouse(mouse.x);
                }
                onReleased: settle.restart()
                onWheel: wheel => root.applyWheel(wheel)
            }
        }

        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.position * 100) + "%"
            color: Theme.subtext
            font.pixelSize: Theme.fontSize - 2
        }
    }

    Text {
        visible: root.caption !== ""
        text: root.caption
        color: Theme.subtext
        font.pixelSize: Theme.fontSize - 3
        Layout.leftMargin: 32
    }
}
