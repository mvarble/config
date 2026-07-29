pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Polls /proc and /sys for CPU, memory, temperature and backlight state.
// All values are exposed as plain properties updated once per second.
Singleton {
    id: root

    // Aggregate CPU usage 0..1 and per-core usages 0..1.
    property real cpuUsage: 0
    property var coreUsages: []

    // Memory usage 0..1 and a human readable "used / total" string.
    property real memUsage: 0
    property string memText: ""

    // CPU package temperature in degrees Celsius.
    property real cpuTemp: 0

    // Backlight brightness 0..1.
    property real brightness: 0

    // First backlight device found at startup ("" when none, e.g. desktops
    // without an internal panel); the settings panel only shows the
    // brightness slider when one exists.
    property string _backlightDevice: ""
    readonly property bool brightnessAvailable: _backlightDevice !== ""

    // Previous /proc/stat snapshots: [idle, total] per line.
    property var _prevTotal: []
    property var _prevCores: ({})

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: root._parseStat(text())
    }

    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoaded: root._parseMeminfo(text())
    }

    FileView {
        id: brightnessFile
        path: root._backlightDevice === "" ? "" : "/sys/class/backlight/" + root._backlightDevice + "/brightness"
        onLoaded: root._updateBrightness()
    }

    FileView {
        id: maxBrightnessFile
        path: root._backlightDevice === "" ? "" : "/sys/class/backlight/" + root._backlightDevice + "/max_brightness"
        onLoaded: root._updateBrightness()
    }

    // One-shot startup probe for a backlight device; empty output means the
    // machine has no controllable backlight (e.g. a desktop).
    Process {
        id: backlightProbe
        running: true
        command: ["sh", "-c", "ls /sys/class/backlight 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: root._backlightDevice = text.trim()
        }
    }

    // Find the CPU thermal zone at runtime instead of hardcoding an index.
    Process {
        id: tempProc
        command: ["sh", "-c", 'for z in /sys/class/thermal/thermal_zone*/type; do t=$(cat "$z" 2>/dev/null); case "$t" in x86_pkg_temp|k10temp|zenpower) cat "${z%/type}/temp" 2>/dev/null; break;; esac; done']
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseFloat(text.trim());
                if (!isNaN(v))
                    root.cpuTemp = v / 1000;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            meminfoFile.reload();
            if (root.brightnessAvailable) {
                brightnessFile.reload();
                maxBrightnessFile.reload();
            }
            tempProc.running = true;
        }
    }

    function _usage(prev, idle, total) {
        if (prev && prev.length === 2 && total > prev[1])
            return Math.max(0, Math.min(1, 1 - (idle - prev[0]) / (total - prev[1])));
        return 0;
    }

    function _parseStat(text) {
        const cores = [];
        for (const line of text.split("\n")) {
            if (!line.startsWith("cpu"))
                continue;
            const parts = line.trim().split(/\s+/);
            const nums = parts.slice(1).map(Number);
            const busy = nums[0] + nums[1] + nums[2] + nums[5] + nums[6] + nums[7];
            const idle = nums[3] + nums[4];
            const total = busy + idle;
            if (parts[0] === "cpu") {
                cpuUsage = _usage(_prevTotal, idle, total);
                _prevTotal = [idle, total];
            } else {
                const idx = parseInt(parts[0].slice(3));
                cores[idx] = _usage(_prevCores[idx], idle, total);
                _prevCores[idx] = [idle, total];
            }
        }
        coreUsages = cores;
    }

    function _parseMeminfo(text) {
        let total = 0, avail = 0;
        for (const line of text.split("\n")) {
            if (line.startsWith("MemTotal:"))
                total = parseInt(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                avail = parseInt(line.split(/\s+/)[1]);
        }
        if (total > 0) {
            memUsage = 1 - avail / total;
            memText = ((total - avail) / 1048576).toFixed(1) + " / " + (total / 1048576).toFixed(1) + " GiB";
        }
    }

    function _updateBrightness() {
        const cur = parseFloat(brightnessFile.text());
        const max = parseFloat(maxBrightnessFile.text());
        if (!isNaN(cur) && !isNaN(max) && max > 0)
            brightness = Math.max(0, Math.min(1, cur / max));
    }
}
