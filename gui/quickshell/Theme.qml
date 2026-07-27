pragma Singleton
import QtQuick
import Quickshell

// Central place for all visual constants (light theme).
Singleton {
    // Palette
    readonly property color background: "#f2f2f7"
    readonly property color surface: "#ffffff"
    readonly property color surfaceAlt: "#e5e5ea"
    readonly property color text: "#1c1c1e"
    readonly property color subtext: "#6e6e73"
    readonly property color accent: "#0a84ff"
    readonly property color border: "#d1d1d6"

    // Launcher backdrop dim, fixed at 0 (fully transparent backdrop).
    readonly property real scrimOpacity: 0.0
    readonly property color scrim: Qt.rgba(0, 0, 0, scrimOpacity)

    // Status colors (usage bars, temperature, etc.)
    readonly property color ok: "#34c759"
    readonly property color warn: "#ffcc00"
    readonly property color crit: "#ff3b30"

    // Settings panel: the panel itself has no background at all. The cards
    // are semi-transparent so Hyprland's blur (layerrule) shows through
    // them like frosted glass; borders stay opaque for definition.
    readonly property color panelBackground: "transparent"
    readonly property color cardBackground: Qt.rgba(surface.r, surface.g, surface.b, 0.8)
    readonly property color cardBorder: border

    // Opacity applied to disconnected/unavailable utility rows.
    readonly property real mutedOpacity: 0.4

    // Font containing icon glyphs (volume, wifi, cpu, battery, ...).
    readonly property string glyphFont: "CaskaydiaCove Nerd Font Mono"

    // Wallpaper image shown by Wallpaper.qml on the background layer.
    readonly property string wallpaperPath: "file:///home/mvarble/pictures/wallpapers/kaitlynne-hawaii-cropped.png"

    // Metrics
    readonly property int radius: 12
    readonly property int fontSize: 14
    readonly property int titleSize: 18
    readonly property int panelWidth: 376
    readonly property int animDuration: 220
}
