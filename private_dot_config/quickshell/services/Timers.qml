pragma Singleton
import QtQuick
import Quickshell

// Countdown timers started from the sidebar's timer widget.
//
// Any number of timers run at once: start() only ever appends a new record and
// never touches an existing one, and there is no notion of a "current" timer.
// A single 1 s Timer acts purely as a shared clock driving `now`; each card
// derives its own remaining/elapsed value from `endsAt` and `now`, so one
// ticker serves the whole list and simultaneous expiries all resolve on the
// same tick.
//
// The ticker lives here rather than in the panel on purpose: a timer has to
// fire while the sidebar is closed.
Singleton {
    id: root

    // Elements: { kind, key, minutes, startedAt, endsAt, notified }.
    // Ordered newest first, matching the notification queue.
    property var entries: []

    // Wall clock in ms, republished every second. Cards bind to this.
    property double now: Date.now()

    property int nextKey: 1

    Timer {
        interval: 1000
        repeat: true
        // Keeps running while finished timers linger, so their "elapsed since"
        // counters keep moving. Stops only when the list is empty.
        running: root.entries.length > 0
        onTriggered: root.tick()
    }

    function tick() {
        now = Date.now();

        // Fire for every entry that came due, not just the first.
        let fired = false;
        for (const e of entries) {
            if (!e.notified && now >= e.endsAt) {
                e.notified = true;
                fired = true;
                Quickshell.execDetached(["notify-send", "-a", "qs-timer", "-u", "critical", "Timer finished", e.minutes + " minute timer is up"]);
            }
        }
        // `notified` is mutated in place above; republish so anything bound to
        // the list re-evaluates.
        if (fired)
            entries = entries.slice();
    }

    function start(minutes) {
        const startedAt = Date.now();
        now = startedAt;
        entries = [
            {
                kind: "timer",
                key: nextKey++,
                minutes: minutes,
                startedAt: startedAt,
                endsAt: startedAt + minutes * 60000,
                notified: false
            }
        ].concat(entries);
    }

    function remove(key) {
        entries = entries.filter(e => e.key !== key);
    }

    function clearFinished() {
        entries = entries.filter(e => root.now < e.endsAt);
    }

    // "5:04" / "1:02:03", used for both remaining and elapsed.
    function formatDuration(ms) {
        const total = Math.max(0, Math.round(ms / 1000));
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        const pad = v => (v < 10 ? "0" + v : String(v));
        return h > 0 ? h + ":" + pad(m) + ":" + pad(s) : m + ":" + pad(s);
    }
}
