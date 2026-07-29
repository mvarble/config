pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Learns launcher usage: how often and how recently each desktop entry or
// raw command was launched. Persisted as JSON in the shell state dir and
// used by LauncherModal for initial suggestions and match ranking.
Singleton {
    id: root

    // id -> { count: int, last: epochMs }. Raw commands use "cmd:<text>".
    property var data: ({})

    FileView {
        id: historyFile
        path: Quickshell.statePath("launch-history.json")
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object")
                    root.data = parsed;
            } catch (e) {
                root.data = ({});
            }
        }
        onLoadFailed: root.data = ({})
    }

    // Frecency: launch count with a one-week half-life on recency.
    function score(id) {
        const e = data[id];
        if (!e)
            return 0;
        const days = (Date.now() - (e.last || 0)) / 86400000;
        return e.count * Math.pow(0.5, days / 7);
    }

    function record(id) {
        const d = Object.assign({}, data);
        d[id] = d[id] ? { count: d[id].count + 1, last: Date.now() } : { count: 1, last: Date.now() };
        // Keep the store bounded: drop the lowest-scored entries past 250.
        const keys = Object.keys(d);
        if (keys.length > 250) {
            const keep = keys.map(k => ({ k: k, s: score(k) }))
                .sort((a, b) => b.s - a.s)
                .slice(0, 200);
            for (const k of keys)
                if (!keep.find(x => x.k === k))
                    delete d[k];
        }
        data = d; // reassign so bindings update
        historyFile.setText(JSON.stringify(d));
    }

    // The n highest-scored ids, best first.
    function topIds(n) {
        return Object.keys(data)
            .map(id => ({ id: id, s: score(id) }))
            .sort((a, b) => b.s - a.s)
            .slice(0, n)
            .map(x => x.id);
    }
}
