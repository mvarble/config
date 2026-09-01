import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "services"
import "notifications"

// Transient popups for incoming notifications, top-right. Independent of the
// sidebar: a toast expiring here never removes the queue entry behind it.
PanelWindow {
    id: root

    // Set while the sidebar is open: both anchor top-right, and the queue
    // already shows everything a toast would, so popping one over the sidebar
    // would just obscure its own header.
    property bool suppressed: false

    anchors {
        top: true
        right: true
        left: true
        bottom: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: Notifications.toasts.length > 0 && !suppressed

    WlrLayershell.namespace: "quickshell-toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only the toast column takes input; everything else clicks through to the
    // window underneath. Without this the transparent surface would swallow
    // clicks across the whole screen.
    mask: Region {
        item: column
    }

    ColumnLayout {
        id: column

        anchors {
            top: parent.top
            right: parent.right
            margins: 12
        }
        width: Theme.panelWidth
        spacing: 8

        Repeater {
            model: Notifications.toasts

            QueueCard {
                required property var modelData

                Layout.fillWidth: true
                entry: modelData
                accentColor: modelData.notification.urgency === NotificationUrgency.Critical ? Theme.crit : (modelData.notification.urgency === NotificationUrgency.Low ? Theme.subtext : Theme.accent)
                title: modelData.notification.summary
                subtitle: modelData.notification.appName
                body: modelData.notification.body
                actions: modelData.notification.actions

                // Dismissing a toast only hides the popup; the sidebar keeps
                // its entry.
                onDismissed: Notifications.dropToast(modelData.key)

                Timer {
                    // Honour the sender's timeout when it gave one, clamped so
                    // a toast can neither flash by nor stick around.
                    interval: Math.max(2000, Math.min(10000, modelData.notification.expireTimeout > 0 ? modelData.notification.expireTimeout : 5000))
                    running: true
                    onTriggered: Notifications.dropToast(modelData.key)
                }
            }
        }
    }
}
