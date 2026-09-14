import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."

// One screen's lockscreen: that screen's desktop snapshot blurred and dimmed,
// a clock, the password field and, on the focused monitor only, media
// controls. All password state lives in the shared LockAuth.
Item {
    id: root

    required property LockAuth auth
    property string screenName: ""
    property url snapshot

    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === screenName

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Image {
        id: backdrop
        anchors.fill: parent
        source: root.snapshot
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false // same path on every lock; always reload the fresh capture
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: backdrop
        visible: backdrop.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 48
    }

    // Dims the blurred desktop so the light text and cards stand out.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    // Clicking anywhere returns focus to the password field.
    MouseArea {
        anchors.fill: parent
        onClicked: field.forceActiveFocus()
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 12

        // Clock and date, with a soft shadow so the light text stays legible
        // over bright desktops.
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 24
            spacing: 12

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.6)
                shadowBlur: 0.8
                shadowVerticalOffset: 2
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.surface
                font.family: Theme.glyphFont
                font.pixelSize: 112
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(clock.date, "dddd, MMMM d")
                color: Theme.surface
                font.pixelSize: 22
            }
        }

        TextField {
            id: field
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 360
            implicitHeight: 52
            focus: true
            enabled: !root.auth.busy
            echoMode: TextInput.Password
            horizontalAlignment: TextInput.AlignHCenter
            placeholderText: root.auth.busy ? "Checking…" : "Password"
            color: Theme.text
            placeholderTextColor: Theme.subtext
            font.pixelSize: Theme.fontSize + 2

            // Mirrors the shared buffer so every screen shows the same input.
            text: root.auth.buffer
            onTextEdited: root.auth.buffer = text
            onAccepted: root.auth.submit()
            Keys.onEscapePressed: root.auth.buffer = ""

            background: Rectangle {
                radius: Theme.radius
                color: Theme.cardBackground
                border.color: root.auth.messageIsError && root.auth.message !== "" ? Theme.crit
                    : field.activeFocus ? Theme.accent : Theme.cardBorder
            }

            // Refocus after a failed attempt re-enables the field.
            onEnabledChanged: if (enabled) forceActiveFocus()
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 20
            text: root.auth.message
            color: root.auth.messageIsError ? Theme.crit : Theme.surface
            font.pixelSize: Theme.fontSize
            font.bold: root.auth.messageIsError
        }

        MediaControls {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            visible: root.focusedScreen && player !== null
        }
    }

    Component.onCompleted: field.forceActiveFocus()
}
