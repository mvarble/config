pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Tracks and controls hyprsunset (screen color temperature / gamma). State
// is polled once per second through hyprctl's hyprsunset IPC: numeric
// replies mean the daemon is running and the values are live; anything else
// means it is not running.
Singleton {
    id: root

    // Whether a hyprsunset process is currently running.
    property bool active: false

    // Color temperature in Kelvin and gamma in percent. While the daemon
    // runs these mirror its live settings; otherwise they hold the values
    // used the next time it is started.
    property real temperature: 6000
    property real gamma: 100

    Process {
        id: poll
        command: ["sh", "-c", "hyprctl hyprsunset temperature; hyprctl hyprsunset gamma"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const t = parseFloat(lines[0]);
                const g = parseFloat(lines[1]);
                if (isNaN(t) || isNaN(g)) {
                    root.active = false;
                    return;
                }
                root.active = true;
                root.temperature = t;
                root.gamma = g;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }

    // Throttles hyprctl calls while the panel sliders are dragged (same
    // pattern as the panel's brightApply timer).
    Timer {
        id: apply
        interval: 120
        onTriggered: {
            if (!root.active)
                return;
            Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(Math.round(root.temperature))]);
            Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", String(Math.round(root.gamma))]);
        }
    }

    function toggle() {
        if (active)
            Quickshell.execDetached(["pkill", "-x", "hyprsunset"]);
        else
            Quickshell.execDetached(["hyprsunset", "-t", String(Math.round(temperature)), "-g", String(Math.round(gamma))]);
        // Optimistic; the next poll confirms the real state.
        active = !active;
    }

    function setTemperature(kelvin) {
        temperature = Math.round(kelvin);
        apply.restart();
    }

    function setGamma(percent) {
        gamma = Math.round(percent);
        apply.restart();
    }
}
