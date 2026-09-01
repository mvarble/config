import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "services"
import "notifications"

// Right-edge sidebar holding the notification queue and a timer widget.
// Toggled via `qs ipc call notifications toggle` (SUPER+N).
//
// The queue is manual: nothing leaves it on a timeout. Running timers appear
// in the same list as notifications, counting down and then counting up once
// they have fired.
PanelWindow {
    id: root

    property bool open: false

    // Same choreography as CalendarPanel: `open` is the toggle target, the
    // card slides out first and only then does the window unmap.
    property bool shown: false
    property bool cardIn: false

    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            shown = true;
            cardIn = true;
        } else {
            cardIn = false;
            closeTimer.restart();
        }
    }

    onCardInChanged: {
        enterAnim.stop();
        exitAnim.stop();
        if (cardIn) {
            slide.x = card.travel;
            card.opacity = 0;
            enterAnim.restart();
        } else {
            exitAnim.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 380
        onTriggered: root.shown = false
    }

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: shown

    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Merged queue, newest first. Timers sort by start time, notifications by
    // arrival, so a freshly started timer lands at the top like a new alert.
    readonly property var queue: {
        const merged = Notifications.entries.concat(Timers.entries);
        merged.sort((a, b) => (b.kind === "timer" ? b.startedAt : b.time) - (a.kind === "timer" ? a.startedAt : a.time));
        return merged;
    }

    function urgencyColor(u) {
        if (u === NotificationUrgency.Critical)
            return Theme.crit;
        if (u === NotificationUrgency.Low)
            return Theme.subtext;
        return Theme.accent;
    }

    // Backdrop: clicking outside the card closes it.
    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        id: card

        readonly property int travel: 32

        width: Theme.panelWidth
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            margins: 8
        }
        radius: Theme.radius
        color: Theme.cardBackground
        border.color: Theme.cardBorder
        opacity: 0

        transform: Translate {
            id: slide
            x: card.travel
        }

        // Enter/exit mirror the calendar card, with the travel on X: a short
        // horizontal slide with a back-eased overshoot plus a fade.
        ParallelAnimation {
            id: enterAnim

            NumberAnimation {
                target: slide
                property: "x"
                to: 0
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }

            NumberAnimation {
                target: card
                property: "opacity"
                to: 1
                duration: Theme.animDuration
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            id: exitAnim

            NumberAnimation {
                target: slide
                property: "x"
                to: card.travel
                duration: 350
                easing.type: Easing.InBack
                easing.overshoot: 1.4
            }

            NumberAnimation {
                target: card
                property: "opacity"
                to: 0
                duration: 200
                easing.type: Easing.InCubic
            }
        }

        focus: true
        Keys.onEscapePressed: root.open = false

        // Absorb clicks so the backdrop doesn't close when clicking inside.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 12

            // ------------------------- Header -------------------------
            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.text
                    font.pixelSize: Theme.titleSize
                    font.bold: true
                }

                Text {
                    text: "Clear all"
                    color: clearArea.containsMouse ? Theme.accent : Theme.subtext
                    font.pixelSize: Theme.fontSize
                    opacity: root.queue.length > 0 ? 1 : Theme.mutedOpacity

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        onClicked: {
                            Notifications.clearAll();
                            Timers.entries = [];
                        }
                    }
                }
            }

            // ------------------------- Timer widget -------------------------
            TimerWidget {
                Layout.fillWidth: true
            }

            // ------------------------- Queue -------------------------
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.queue
                boundsBehavior: Flickable.StopAtBounds

                delegate: Loader {
                    required property var modelData
                    width: ListView.view.width
                    sourceComponent: modelData.kind === "timer" ? timerCard : notificationCard
                    onLoaded: item.entry = modelData
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.fillHeight: root.queue.length === 0
                visible: root.queue.length === 0
                text: "Nothing here."
                color: Theme.subtext
                opacity: Theme.mutedOpacity
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // ------------------------- Delegates -------------------------

    Component {
        id: notificationCard

        QueueCard {
            id: nc
            accentColor: root.urgencyColor(entry.notification.urgency)
            onDismissed: Notifications.dismiss(entry.key)

            title: entry.notification.summary
            subtitle: entry.notification.appName
            body: entry.notification.body
            actions: entry.notification.actions
        }
    }

    Component {
        id: timerCard

        QueueCard {
            id: tc

            readonly property bool done: Timers.now >= entry.endsAt

            accentColor: done ? Theme.crit : Theme.accent
            onDismissed: Timers.remove(entry.key)

            title: done ? "+" + Timers.formatDuration(Timers.now - entry.endsAt) : Timers.formatDuration(entry.endsAt - Timers.now)
            subtitle: entry.minutes + " minute timer"
            body: done ? "Finished. Time since it went off." : ""
            monospaceTitle: true
        }
    }
}
