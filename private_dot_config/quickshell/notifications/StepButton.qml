import QtQuick
import ".."

// Square −/+ button used by the timer stepper. Holding it repeats.
Rectangle {
    id: root

    property string glyph: ""

    signal activated

    implicitWidth: 34
    implicitHeight: 34
    radius: 8
    color: area.containsMouse ? Theme.surfaceAlt : "transparent"
    border.color: Theme.cardBorder

    Text {
        anchors.centerIn: parent
        text: root.glyph
        color: Theme.text
        font.pixelSize: Theme.titleSize
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.activated()
        onPressAndHold: repeatTimer.start()
        onReleased: repeatTimer.stop()
        onCanceled: repeatTimer.stop()
    }

    Timer {
        id: repeatTimer
        interval: 80
        repeat: true
        onTriggered: root.activated()
    }
}
