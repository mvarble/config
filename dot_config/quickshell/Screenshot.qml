import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Region screenshot. `start()` (bound to `qs ipc call screenshot start`,
// SUPER+S) freezes every output with grim, then shows the frozen frames
// full-screen so a box can be dragged on any one of them. Releasing the
// mouse crops that box out of the frozen frame (at native resolution),
// saves it to ~/pictures/screenshots/<timestamp>.png and copies it to the
// clipboard. Escape or right-click cancels.
Scope {
    id: root

    // idle -> capturing (grim running) -> selecting (overlay up) -> idle
    property string phase: "idle"

    // Unique per capture so the Image elements never show a cached frame.
    property string token: ""
    readonly property string freezeDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-screenshot"
    readonly property string saveDir: Quickshell.env("HOME") + "/pictures/screenshots"

    function framePath(screenName) {
        return freezeDir + "/" + token + "-" + screenName + ".png";
    }

    function start() {
        if (phase !== "idle")
            return;
        token = Date.now().toString();
        const cmds = ["mkdir -p '" + freezeDir + "'"];
        for (const s of Quickshell.screens)
            cmds.push("grim -o '" + s.name + "' '" + framePath(s.name) + "'");
        capture.command = ["sh", "-c", cmds.join(" && ")];
        phase = "capturing";
        capture.running = true;
    }

    function cancel() {
        if (phase === "idle")
            return;
        phase = "idle";
        Quickshell.execDetached(["rm", "-rf", freezeDir]);
    }

    // Crop (x, y, w, h), given in frame pixels, out of `screenName`'s frozen
    // frame and save it.
    function finish(screenName, x, y, w, h) {
        const frame = framePath(screenName);
        const out = saveDir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png";
        phase = "idle";
        Quickshell.execDetached(["sh", "-c",
            "mkdir -p \"$1\" && magick \"$2\" -crop \"$3\" +repage \"$4\" && wl-copy --type image/png < \"$4\"" +
            " && notify-send -a Screenshot -i \"$4\" 'Screenshot saved' \"$4\"; rm -rf \"$5\"",
            "screenshot", saveDir, frame, w + "x" + h + "+" + x + "+" + y, out, freezeDir]);
    }

    Process {
        id: capture
        onExited: (code) => {
            if (root.phase !== "capturing")
                return;
            if (code === 0) {
                root.phase = "selecting";
            } else {
                root.cancel();
                Quickshell.execDetached(["notify-send", "-a", "Screenshot", "Screenshot failed", "grim exited with code " + code]);
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            anchors {
                left: true
                top: true
                right: true
                bottom: true
            }
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            visible: root.phase === "selecting"

            WlrLayershell.namespace: "quickshell-screenshot"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            // Selection in window (logical) coordinates.
            property bool dragging: false
            property real x0: 0
            property real y0: 0
            property real x1: 0
            property real y1: 0
            readonly property real selX: Math.min(x0, x1)
            readonly property real selY: Math.min(y0, y1)
            readonly property real selW: Math.abs(x1 - x0)
            readonly property real selH: Math.abs(y1 - y0)
            readonly property bool hasSelection: dragging && selW >= 1 && selH >= 1

            // Frame pixels per logical pixel (the output's scale).
            readonly property real pixelScale: frame.sourceSize.width > 0 ? frame.sourceSize.width / width : 1

            onVisibleChanged: dragging = false

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.cancel()

                Image {
                    id: frame
                    anchors.fill: parent
                    source: root.token !== "" && root.phase === "selecting" ? "file://" + root.framePath(win.modelData.name) : ""
                    cache: false
                    smooth: false
                    fillMode: Image.Stretch
                }

                // Dim everything outside the selection (the whole frame
                // while nothing is selected).
                component Dim: Rectangle {
                    color: Qt.rgba(0, 0, 0, 0.35)
                }
                Dim {
                    x: 0
                    y: 0
                    width: parent.width
                    height: win.hasSelection ? win.selY : parent.height
                }
                Dim {
                    visible: win.hasSelection
                    x: 0
                    y: win.selY + win.selH
                    width: parent.width
                    height: parent.height - y
                }
                Dim {
                    visible: win.hasSelection
                    x: 0
                    y: win.selY
                    width: win.selX
                    height: win.selH
                }
                Dim {
                    visible: win.hasSelection
                    x: win.selX + win.selW
                    y: win.selY
                    width: parent.width - x
                    height: win.selH
                }

                // Selection outline, drawn just outside the captured box.
                Rectangle {
                    visible: win.hasSelection
                    x: win.selX - border.width
                    y: win.selY - border.width
                    width: win.selW + 2 * border.width
                    height: win.selH + 2 * border.width
                    color: "transparent"
                    border.color: Theme.accent
                    border.width: 2
                }

                // Size readout pill, under the box (above it near the bottom).
                Rectangle {
                    visible: win.hasSelection
                    readonly property bool below: win.selY + win.selH + 8 + height < parent.height
                    x: Math.max(4, Math.min(win.selX, parent.width - width - 4))
                    y: below ? win.selY + win.selH + 8 : Math.max(4, win.selY - height - 8)
                    width: sizeText.implicitWidth + 20
                    height: sizeText.implicitHeight + 10
                    radius: 8
                    color: Theme.cardBackground
                    border.color: Theme.cardBorder

                    Text {
                        id: sizeText
                        anchors.centerIn: parent
                        text: Math.round(win.selW * win.pixelScale) + " × " + Math.round(win.selH * win.pixelScale)
                        color: Theme.text
                        font.pixelSize: Theme.fontSize
                    }
                }

                // Hint card, below the top bar; hidden once dragging.
                Rectangle {
                    visible: !win.dragging
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Theme.barHeight + 16
                    width: hint.implicitWidth + 32
                    height: hint.implicitHeight + 20
                    radius: Theme.radius
                    color: Theme.cardBackground
                    border.color: Theme.cardBorder

                    Text {
                        id: hint
                        anchors.centerIn: parent
                        text: "Drag to capture a region  ·  Esc to cancel"
                        color: Theme.text
                        font.pixelSize: Theme.fontSize
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.CrossCursor

                    onPressed: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            root.cancel();
                            return;
                        }
                        win.x0 = win.x1 = mouse.x;
                        win.y0 = win.y1 = mouse.y;
                        win.dragging = true;
                    }
                    onPositionChanged: (mouse) => {
                        if (!win.dragging)
                            return;
                        win.x1 = Math.max(0, Math.min(mouse.x, width));
                        win.y1 = Math.max(0, Math.min(mouse.y, height));
                    }
                    onReleased: (mouse) => {
                        if (!win.dragging || mouse.button !== Qt.LeftButton)
                            return;
                        win.dragging = false;
                        const s = win.pixelScale;
                        const x = Math.round(win.selX * s);
                        const y = Math.round(win.selY * s);
                        const w = Math.round(win.selW * s);
                        const h = Math.round(win.selH * s);
                        // A click without a drag selects nothing; stay open.
                        if (w < 2 || h < 2)
                            return;
                        root.finish(win.modelData.name, x, y, w, h);
                    }
                }
            }
        }
    }
}
