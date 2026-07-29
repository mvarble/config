import QtQuick
import Quickshell
import Quickshell.Wayland
import Qt.labs.folderlistmodel

// Desktop wallpaper: one background-layer surface per screen. Theme.wallpaperPath
// may point at a single image file, or at a directory of images that is cycled
// randomly every Theme.wallpaperInterval seconds with a crossfade between them.
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

        // A non-empty listing means wallpaperPath is a directory of images
        // (slideshow mode); otherwise it is treated as a single image file.
        FolderListModel {
            id: wallModel
            folder: Theme.wallpaperPath
            showDirs: false
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp",
                          "*.JPG", "*.JPEG", "*.PNG", "*.WEBP", "*.BMP"]

            onStatusChanged: {
                if (status !== FolderListModel.Ready || started)
                    return;
                started = true;
                if (count > 0) {
                    currentIndex = Math.floor(Math.random() * count);
                    imageA.source = get(currentIndex, "fileUrl");
                } else {
                    imageA.source = Theme.wallpaperPath;
                }
            }
        }

        readonly property bool slideshow: wallModel.status === FolderListModel.Ready && wallModel.count > 0
        property bool started: false
        property int currentIndex: -1
        // Which of the two stacked images is currently visible, and which one
        // is mid-fade (waiting for its source to finish loading).
        property bool frontIsA: true
        property Image pending: null

        // Picks the next slideshow image at random, never repeating the
        // current one when the directory has more than one image.
        function pickNext(): url {
            if (wallModel.count < 2)
                return wallModel.get(0, "fileUrl");
            let next = currentIndex;
            while (next === currentIndex)
                next = Math.floor(Math.random() * wallModel.count);
            currentIndex = next;
            return wallModel.get(currentIndex, "fileUrl");
        }

        // Starts the crossfade to the next image: the incoming image is
        // stacked on top and faded in once its source has finished loading.
        function advance(): void {
            const front = frontIsA ? imageA : imageB;
            const back = frontIsA ? imageB : imageA;
            back.z = 1;
            front.z = 0;
            pending = back;
            back.source = pickNext();
            if (back.status === Image.Ready) // already cached
                revealPending();
        }

        function revealPending(): void {
            if (pending === null)
                return;
            pending.opacity = 1;
            (pending === imageA ? imageB : imageA).opacity = 0;
            frontIsA = pending === imageA;
            pending = null;
        }

        Timer {
            interval: Theme.wallpaperInterval * 1000
            running: slideshow && wallModel.count > 1
            repeat: true
            onTriggered: advance()
        }

        Image {
            id: imageA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            opacity: 1

            Behavior on opacity {
                NumberAnimation { duration: Theme.animDuration }
            }

            onStatusChanged: {
                if (status === Image.Ready && pending === imageA)
                    revealPending();
            }
        }

        Image {
            id: imageB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.animDuration }
            }

            onStatusChanged: {
                if (status === Image.Ready && pending === imageB)
                    revealPending();
            }
        }
    }
}
