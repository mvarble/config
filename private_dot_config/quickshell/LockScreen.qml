import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Lock triggers for the main shell: IPC (see shell.qml), idle and system
// sleep. The lock itself runs as a separate quickshell process
// (lockscreen.qml). A WlSessionLock inside this shell would be released by
// any config reload, since the reloaded instance starts with locked = false.
Scope {
    id: root

    property real idleTimeout: 300

    readonly property string lockConfig: Quickshell.shellPath("lockscreen.qml")
    // Per display, so concurrent Hyprland sessions don't share snapshots.
    // lockscreen.qml derives the same path.
    readonly property string snapshotDir: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-lock-" + Quickshell.env("WAYLAND_DISPLAY")

    // Snapshots every screen (downscaled; they get blurred anyway), then starts
    // the lock process, unless this display already has one. Detached, so
    // reloading or restarting this shell can't take the lock down with it.
    function lock(): void {
        const script = [
            'config="$1"; dir="$2"; shift 2',
            'qs -p "$config" ipc show >/dev/null 2>&1 && exit 0',
            'mkdir -p -m 700 "$dir" && for o in "$@"; do grim -s 0.25 -o "$o" "$dir/$o.png"; done',
            'exec qs -n -p "$config"',
        ].join("\n");
        Quickshell.execDetached(["sh", "-c", script, "sh", lockConfig, snapshotDir,
            ...Quickshell.screens.map(s => s.name)]);
    }

    IdleMonitor {
        timeout: root.idleTimeout
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle)
                root.lock();
        }
    }

    // The long-running helpers below are started under `setpriv --pdeathsig`
    // so they exit if quickshell dies; otherwise a crashed shell would leave a
    // stale inhibitor delaying every suspend.

    // Logind delay inhibitor, held except while a suspend is under way, so a
    // suspend waits until the lock is up.
    Process {
        id: inhibitor
        running: true
        command: ["setpriv", "--pdeathsig", "TERM", "--",
            "systemd-inhibit", "--what=sleep", "--mode=delay", "--who=quickshell",
            "--why=Lock the screen before sleep", "sleep", "infinity"]
    }

    Process {
        running: true
        command: ["setpriv", "--pdeathsig", "TERM", "--",
            "gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1",
            "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("PrepareForSleep (true")) {
                    root.lock();
                    secureWait.attempts = 0;
                    secureWait.restart();
                } else if (line.includes("PrepareForSleep (false")) {
                    secureWait.stop();
                    inhibitor.running = true;
                }
            }
        }
    }

    // Polls the lock process until the compositor confirms the lock, then
    // releases the inhibitor so the suspend proceeds. Gives up after ~4s,
    // inside logind's default 5s delay budget.
    Timer {
        id: secureWait

        property int attempts: 0

        interval: 100
        repeat: true
        onTriggered: {
            if (++attempts > 40) {
                stop();
                inhibitor.running = false;
            } else if (!secureCheck.running) {
                secureCheck.running = true;
            }
        }
    }

    Process {
        id: secureCheck
        command: ["qs", "-p", root.lockConfig, "ipc", "call", "lockscreen", "isSecure"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (secureWait.running && text.trim() === "true") {
                    secureWait.stop();
                    inhibitor.running = false;
                }
            }
        }
    }
}
