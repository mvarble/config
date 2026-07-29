pragma Singleton
import QtQuick
import Quickshell

// Central place for all visual constants (light theme).
Singleton {
    // Palette
    readonly property color background: "#e6e9ef"
    readonly property color surface: "#eff1f5"
    readonly property color surfaceAlt: "#bcc0cc"
    readonly property color text: "#4c4f69"
    readonly property color subtext: "#5c5f77"
    readonly property color accent: "#8839ef"
    readonly property color border: "#bcc0cc"

    // Launcher backdrop dim, fixed at 0 (fully transparent backdrop).
    readonly property real scrimOpacity: 0.0
    readonly property color scrim: Qt.rgba(0, 0, 0, scrimOpacity)

    // Status colors (usage bars, temperature, etc.)
    readonly property color ok: "#40a02b"
    readonly property color warn: "#df8e1d"
    readonly property color crit: "#d20f39"

    // Settings panel: the panel itself has no background at all. The cards
    // are semi-transparent so Hyprland's blur (layerrule) shows through
    // them like frosted glass; borders stay opaque for definition.
    readonly property color panelBackground: "transparent"
    readonly property color cardBackground: Qt.rgba(surface.r, surface.g, surface.b, 0.7)
    readonly property color cardBorder: border

    // Opacity applied to disconnected/unavailable utility rows.
    readonly property real mutedOpacity: 0.4

    // Font containing icon glyphs (volume, wifi, cpu, battery, ...).
    readonly property string glyphFont: "CaskaydiaCove Nerd Font Mono"

    // Wallpaper shown by Wallpaper.qml on the background layer. May point at
    // a single image file, or at a directory of images cycled randomly
    // (slideshow) every wallpaperInterval seconds.
    readonly property string wallpaperPath: "file:///home/mvarble/pictures/wallpapers"
    readonly property int wallpaperInterval: 300

    // Metrics
    readonly property int radius: 12
    readonly property int fontSize: 14
    readonly property int titleSize: 18
    readonly property int panelWidth: 376
    readonly property int animDuration: 220

    // Width of the persistent LeftBar. SettingsPanel indents its content by
    // this much so its cards rest clear of (and emerge from behind) the bar.
    readonly property int barWidth: 40
}
