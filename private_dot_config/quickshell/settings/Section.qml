import QtQuick
import QtQuick.Layouts
import ".."

// A titled card grouping related controls. When `enter` becomes true the
// card bounces in from the left, delayed by `enterDelay` to stagger
// multiple sections; when it becomes false the card slides back out after
// `exitDelay`. The offset is applied via a Translate transform so it does
// not fight the surrounding Layout for the item's x position.
ColumnLayout {
    id: root

    property string title: ""
    property int enterDelay: 0
    property int exitDelay: 0
    property bool enter: false
    default property alias content: body.data

    // Horizontal distance the bounce travels. The panel's outer left margin
    // reserves exactly this much room, so the card is never cropped
    // mid-animation; the right margin covers the overshoot.
    readonly property int travel: 24
    Layout.rightMargin: 8

    spacing: 0
    opacity: 0

    transform: Translate {
        id: slide
        x: -root.travel
    }

    onEnterChanged: {
        enterAnim.stop();
        exitAnim.stop();
        if (enter) {
            slide.x = -root.travel;
            opacity = 0;
            enterAnim.restart();
        } else {
            exitAnim.restart();
        }
    }

    SequentialAnimation {
        id: enterAnim

        PauseAnimation {
            duration: root.enterDelay
        }

        ParallelAnimation {
            NumberAnimation {
                target: slide
                property: "x"
                to: 0
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }

            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }

    SequentialAnimation {
        id: exitAnim

        PauseAnimation {
            duration: root.exitDelay
        }

        ParallelAnimation {
            NumberAnimation {
                target: slide
                property: "x"
                to: -root.travel
                duration: 350
                easing.type: Easing.InBack
                easing.overshoot: 1.4
            }

            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: 200
                easing.type: Easing.InCubic
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + 24
        radius: Theme.radius
        color: Theme.cardBackground
        border.color: Theme.cardBorder

        ColumnLayout {
            id: body
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 10

            Text {
                Layout.fillWidth: true
                visible: root.title !== ""
                text: root.title
                color: Theme.subtext
                font.pixelSize: Theme.fontSize - 2
                font.bold: true
                font.capitalization: Font.AllUppercase
            }
        }
    }
}
