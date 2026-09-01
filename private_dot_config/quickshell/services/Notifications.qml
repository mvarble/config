pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Owns org.freedesktop.Notifications for the session (nothing else on this
// machine does; dunst is installed but never started and has no D-Bus
// activation file, so there is no race for the name).
//
// Two lists come out of here:
//   entries - the persistent queue shown in NotificationSidebar. Nothing ever
//             leaves it on a timeout; only dismiss()/clearAll() remove things.
//   toasts  - the short-lived popups drawn by NotificationToasts.
Singleton {
    id: root

    // Newest first. Elements: { kind, key, time, notification }.
    property var entries: []

    // Newest first, same element shape. A toast expiring does not touch the
    // queue entry that shares its notification.
    property var toasts: []

    // Timer expiry notifications are sent with `notify-send -a qs-timer` so
    // they round-trip through this server and get a toast like anything else.
    // They deliberately do not join the queue: the timer's own card is already
    // the persistent record, and it flips to counting elapsed time.
    readonly property string timerAppName: "qs-timer"

    property int nextKey: 1

    NotificationServer {
        id: server

        // Survive a config reload so editing QML doesn't wipe the queue.
        keepOnReload: true

        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true

        onNotification: function (notification) {
            const entry = {
                kind: "notification",
                key: root.nextKey++,
                time: Date.now(),
                notification: notification
            };

            if (notification.appName === root.timerAppName) {
                // Toast only. Left untracked, so the server drops it once the
                // toast is gone.
                root.toasts = [entry].concat(root.toasts);
                return;
            }

            // Tracking is what keeps the object alive past its expire timeout;
            // without it the queue would hold dangling entries.
            notification.tracked = true;
            root.entries = [entry].concat(root.entries);
            root.toasts = [entry].concat(root.toasts);
        }
    }

    function dismiss(key) {
        const kept = [];
        for (const e of entries) {
            if (e.key === key)
                e.notification.dismiss();
            else
                kept.push(e);
        }
        entries = kept;
        dropToast(key);
    }

    function clearAll() {
        for (const e of entries)
            e.notification.dismiss();
        entries = [];
        toasts = [];
    }

    // Removes a popup without disturbing the queue.
    function dropToast(key) {
        toasts = toasts.filter(e => e.key !== key);
    }
}
