import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import "services"
import "settings"

// Left-edge slide-in settings panel. Toggled via `qs ipc call settings toggle`.
PanelWindow {
    id: root

    property bool open: false

    // Close choreography: `open` is the toggle target. On close, the
    // sections animate out first (staggered) and only then does the panel
    // itself slide away (`shown` -> false via closeTimer).
    property bool shown: false
    property bool sectionsEnter: false

    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            shown = true;
            sectionsEnter = true;
        } else {
            sectionsEnter = false;
            closeTimer.restart();
        }
    }

    // Longest section exit delay (200) + exit animation duration (350).
    Timer {
        id: closeTimer
        interval: 550
        onTriggered: root.shown = false
    }
    anchors {
        left: true
        top: true
        bottom: true
    }
    implicitWidth: Theme.panelWidth
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // The panel itself has no slide animation: it appears instantly on open
    // and unmaps once the sections have finished their exit animations.
    visible: shown

    // Required for PwNode.audio properties to be valid.
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    // Throttles brightnessctl calls while the brightness slider is dragged.
    Timer {
        id: brightApply
        interval: 120
        property real pending: 0
        onTriggered: Quickshell.execDetached(["brightnessctl", "set", Math.round(pending * 100) + "%"])
    }

    Rectangle {
        id: panel
        width: parent.width
        height: parent.height
        color: Theme.panelBackground

        focus: true
        Keys.onEscapePressed: root.open = false

        // Absorb clicks so nothing falls through to windows below.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            anchors {
                fill: parent
                // Left margin doubles as the travel lane for the sections'
                // bounce animation (Section.travel = 24), so cards are never
                // cropped and rest margins stay balanced (24 left, 24 right).
                leftMargin: 0
                rightMargin: 24
                topMargin: 0
                bottomMargin: 16
            }
            spacing: 12

            ScrollView {
                id: scrollView
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: scrollView.availableWidth
                    spacing: 14

                    // ------------------------------------------------------
                    Section {
                        Layout.fillWidth: true
                        title: "Sound & Display"
                        enter: root.sectionsEnter
                        enterDelay: 0
                        exitDelay: 200

                        ValueSlider {
                            Layout.fillWidth: true
                            caption: "Output volume"
                            icon: {
                                const sink = Pipewire.defaultAudioSink;
                                if (!sink || !sink.audio || sink.audio.muted)
                                    return "";
                                const v = sink.audio.volume;
                                return v < 0.33 ? "" : (v < 0.66 ? "" : "");
                            }
                            sourceValue: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                            onApplied: value => {
                                if (Pipewire.defaultAudioSink)
                                    Pipewire.defaultAudioSink.audio.volume = value;
                            }
                        }

                        ValueSlider {
                            Layout.fillWidth: true
                            caption: "Screen brightness"
                            icon: "󰃠"
                            sourceValue: SystemMonitor.brightness
                            // Backlight is polled once per second; keep the
                            // handle in place until the poll catches up.
                            settleDelay: 1500
                            onApplied: value => {
                                brightApply.pending = value;
                                brightApply.restart();
                            }
                        }
                    }

                    // ------------------------------------------------------
                    Section {
                        Layout.fillWidth: true
                        title: "Network"
                        enter: root.sectionsEnter
                        enterDelay: 100
                        exitDelay: 100

                        NetIface {
                            Layout.fillWidth: true
                            icon: "󰈀"
                            connected: NetworkInfo.ethernet?.connected ?? false
                            title: connected ? NetworkInfo.ethernet.name : "Ethernet"
                            subtitle: connected ? NetworkInfo.ethernet.ip : "disconnected"
                            rxText: NetworkInfo.fmtRate(NetworkInfo.ethernet?.rxRate ?? 0)
                            txText: NetworkInfo.fmtRate(NetworkInfo.ethernet?.txRate ?? 0)
                        }

                        NetIface {
                            Layout.fillWidth: true
                            wifiBars: true
                            linkQuality: NetworkInfo.wifi?.link ?? -1
                            connected: NetworkInfo.wifi?.connected ?? false
                            title: connected ? NetworkInfo.wifi.name : "Wi-Fi"
                            subtitle: connected ? NetworkInfo.wifi.ip : "disconnected"
                            rxText: NetworkInfo.fmtRate(NetworkInfo.wifi?.rxRate ?? 0)
                            txText: NetworkInfo.fmtRate(NetworkInfo.wifi?.txRate ?? 0)
                            menuButton: true
                            onMenuClicked: Quickshell.execDetached(["nm-connection-editor"])
                        }
                    }

                    // ------------------------------------------------------
                    Section {
                        Layout.fillWidth: true
                        title: "Resources"
                        enter: root.sectionsEnter
                        enterDelay: 200
                        exitDelay: 0

                        // Power profile segmented control.
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "Saver", profile: PowerProfile.PowerSaver },
                                    { label: "Balanced", profile: PowerProfile.Balanced },
                                    { label: "Performance", profile: PowerProfile.Performance }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool activeProfile: PowerProfiles.profile === modelData.profile
                                    readonly property bool available: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile

                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 8
                                    opacity: available ? 1 : Theme.mutedOpacity
                                    color: activeProfile ? Theme.accent : Theme.surfaceAlt

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.pixelSize: Theme.fontSize - 2
                                        color: parent.activeProfile ? "#ffffff" : Theme.text
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: if (parent.available) PowerProfiles.profile = modelData.profile
                                    }
                                }
                            }
                        }

                        StatRow {
                            Layout.fillWidth: true
                            icon: "󰘚"
                            label: "CPU"
                            value: Math.round(SystemMonitor.cpuUsage * 100) + "%"
                        }

                        CoreBars {
                            Layout.fillWidth: true
                            usages: SystemMonitor.coreUsages
                        }

                        StatRow {
                            Layout.fillWidth: true
                            icon: "󰍛"
                            label: "Memory"
                            value: Math.round(SystemMonitor.memUsage * 100) + "% · " + SystemMonitor.memText
                        }

                        CoreBars {
                            Layout.fillWidth: true
                            usages: [SystemMonitor.memUsage]
                        }

                        StatRow {
                            Layout.fillWidth: true
                            icon: SystemMonitor.cpuTemp < 45 ? "" : (SystemMonitor.cpuTemp < 60 ? "" : (SystemMonitor.cpuTemp < 80 ? "" : ""))
                            iconColor: SystemMonitor.cpuTemp < 60 ? Theme.ok : (SystemMonitor.cpuTemp < 80 ? Theme.warn : Theme.crit)
                            label: "CPU temperature"
                            value: Math.round(SystemMonitor.cpuTemp) + " °C"
                        }

                        StatRow {
                            Layout.fillWidth: true
                            visible: UPower.displayDevice.ready
                            icon: {
                                const dev = UPower.displayDevice;
                                const p = dev.percentage > 1 ? dev.percentage / 100 : dev.percentage;
                                if (dev.state === UPowerDeviceState.Charging) {
                                    if (p >= 0.9) return "󰂅";
                                    if (p >= 0.8) return "󰂋";
                                    if (p >= 0.7) return "󰂊";
                                    if (p >= 0.6) return "󰢞";
                                    if (p >= 0.5) return "󰂉";
                                    if (p >= 0.4) return "󰢝";
                                    if (p >= 0.3) return "󰂈";
                                    if (p >= 0.2) return "󰂇";
                                    if (p >= 0.1) return "󰂆";
                                    return "󰢜";
                                }
                                if (p >= 0.9) return "󰂂";
                                if (p >= 0.8) return "󰂁";
                                if (p >= 0.7) return "󰂀";
                                if (p >= 0.6) return "󰁿";
                                if (p >= 0.5) return "󰁾";
                                if (p >= 0.4) return "󰁽";
                                if (p >= 0.3) return "󰁼";
                                if (p >= 0.2) return "󰁻";
                                if (p >= 0.1) return "󰁺";
                                return "󰂎";
                            }
                            iconColor: {
                                const dev = UPower.displayDevice;
                                if (dev.state === UPowerDeviceState.Charging) return Theme.ok;
                                const p = dev.percentage > 1 ? dev.percentage / 100 : dev.percentage;
                                if (p >= 0.6) return Theme.ok;
                                if (p >= 0.3) return Theme.warn;
                                return Theme.crit;
                            }
                            label: "Battery"
                            value: {
                                const p = UPower.displayDevice.percentage;
                                return Math.round(p > 1 ? p : p * 100) + "%";
                            }
                        }
                    }

                    Item {
                        implicitHeight: 2
                    }
                }
            }
        }
    }
}
