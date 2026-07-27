pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Provides calendar events read from a CalDAV account by caldav-fetch.py
// (read-only; nothing is ever written to the server). Events refresh on a
// timer and are cached in the shell state dir so the panel shows last-known
// data at startup and while offline.
Singleton {
    id: root

    // --- Configuration (non-secret; credentials live in the Secret Service) ---

    // Calendar display names to include, e.g. ["Personal", "Work"].
    // Empty array = every calendar the account exposes.
    readonly property var calendarNames: []

    // Poll interval and fetch window (days back / ahead of today).
    readonly property int refreshMinutes: 15
    readonly property int pastDays: 62
    readonly property int futureDays: 186

    // --- State ---

    // Normalized events: { uid, summary, start, end (epoch ms), allDay, location, calendar }
    property var events: []
    property string lastError: ""
    property bool fetching: false

    property string _stderr: ""

    readonly property string _script: Qt.resolvedUrl("caldav-fetch.py").toString().replace(/^file:\/\//, "")

    function refresh() {
        if (fetching)
            return;
        fetching = true;
        _stderr = "";
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        command: ["python3", root._script,
            "--calendars", root.calendarNames.join(","),
            "--past-days", String(root.pastDays),
            "--future-days", String(root.futureDays)]
        stdout: StdioCollector {
            onStreamFinished: root._apply(text)
        }
        stderr: StdioCollector {
            onStreamFinished: root._stderr = text.trim()
        }
        onExited: (exitCode, exitStatus) => {
            root.fetching = false;
            if (exitCode !== 0)
                root.lastError = root._stderr !== "" ? root._stderr : "fetch failed (exit " + exitCode + ")";
        }
    }

    Timer {
        interval: root.refreshMinutes * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Last-known events, written after every successful fetch.
    FileView {
        id: cacheFile
        path: Quickshell.statePath("calendar-cache.json")
        onLoaded: {
            if (root.events.length === 0)
                root._apply(text());
        }
        onLoadFailed: root.events = []
    }

    function _apply(text) {
        const t = text.trim();
        if (t === "")
            return;
        try {
            const parsed = JSON.parse(t);
            if (Array.isArray(parsed)) {
                events = parsed;
                lastError = "";
                cacheFile.setText(JSON.stringify(parsed));
            }
        } catch (e) {
            lastError = "unparseable fetch output";
        }
    }

    // Events overlapping the given day: all-day first, then chronological.
    function eventsForDay(day) {
        const t0 = new Date(day.getFullYear(), day.getMonth(), day.getDate()).getTime();
        const t1 = t0 + 86400000;
        return events
            .filter(e => e.start < t1 && e.end > t0)
            .sort((a, b) => ((b.allDay ? 1 : 0) - (a.allDay ? 1 : 0)) || (a.start - b.start) || a.summary.localeCompare(b.summary));
    }

    function hasEvents(day) {
        const t0 = new Date(day.getFullYear(), day.getMonth(), day.getDate()).getTime();
        const t1 = t0 + 86400000;
        return events.some(e => e.start < t1 && e.end > t0);
    }
}
