import QtQuick
import Quickshell
import Quickshell.Wayland

// Desktop wallpaper: one background-layer surface per screen, showing the
// image at Theme.wallpaperPath cropped to fill.
Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        anchors {
            left: true
            top: true
            right: true
            bottom: true
        }
        color: "#1c1c1e"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "quickshell-wallpaper"
        WlrLayershell.layer: WlrLayer.Background

        Image {
            anchors.fill: parent
            source: Theme.wallpaperPath
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
        }
    }
}
