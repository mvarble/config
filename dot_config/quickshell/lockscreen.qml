// Standalone lock process, started by LockScreen.qml as `qs -n -p lockscreen.qml`
// (one per display). Locks at startup and quits once PAM succeeds.
//
// Kept out of the main shell on purpose: on a config reload, WlSessionLock
// takes over the old instance's lock but applies the *new* instance's
// `locked` value, so a lock toggled imperatively inside the main shell is
// released by any reload. Here `locked: true` is static, so reloading this
// process (e.g. after editing lock/*.qml) keeps the session locked.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "lock"

ShellRoot {
    id: root

    // Same path LockScreen.qml snapshots into.
    readonly property string snapshotDir: Quickshell.env("XDG_RUNTIME_DIR") + "/qs-lock-" + Quickshell.env("WAYLAND_DISPLAY")

    LockAuth {
        id: lockAuth
        onSucceeded: {
            sessionLock.locked = false;
            Quickshell.execDetached(["rm", "-rf", root.snapshotDir]);
            Qt.quit();
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            id: surface
            color: "#1c1c1e"

            LockContent {
                anchors.fill: parent
                auth: lockAuth
                screenName: surface.screen?.name ?? ""
                snapshot: "file://" + root.snapshotDir + "/" + screenName + ".png"
            }
        }
    }

    // Lets the main shell hold a pending suspend until the compositor has
    // confirmed the lock. Read-only: there is deliberately no unlock here.
    IpcHandler {
        target: "lockscreen"
        function isSecure(): bool { return sessionLock.secure; }
    }
}
