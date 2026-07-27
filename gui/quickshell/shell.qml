//@ pragma UseQApplication

import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    SettingsPanel {
        id: settingsPanel
    }

    LauncherModal {
        id: launcherModal
    }

    Wallpaper {
        id: wallpaper
    }

    CalendarPanel {
        id: calendarPanel
    }

    // The three surfaces are independent: each toggles on its own and can be
    // open at the same time as the others.
    IpcHandler {
        target: "settings"
        function open(): void { settingsPanel.open = true; }
        function close(): void { settingsPanel.open = false; }
        function toggle(): void { settingsPanel.open ? close() : open(); }
    }

    IpcHandler {
        target: "launcher"
        function open(): void { launcherModal.open = true; }
        function close(): void { launcherModal.open = false; }
        function toggle(): void { launcherModal.open ? close() : open(); }
    }

    IpcHandler {
        target: "calendar"
        function open(): void { calendarPanel.open = true; }
        function close(): void { calendarPanel.open = false; }
        function toggle(): void { calendarPanel.open ? close() : open(); }
    }
}
