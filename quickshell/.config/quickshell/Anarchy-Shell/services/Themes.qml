pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

/// Theme switching service for the dashboard "Themes" tab.
/// Scans ~/.config/.hypr-themes (same JSON lines as the Anarchy-Bar picker)
/// and applies themes through run-theme.sh + wal-to-caelestia so the
/// wallpaper, pywal palette and the shell itself all update together.
Singleton {
    id: root

    property var themes: []
    property bool applying: false
    property string applyingName: ""
    property string currentTheme: {
        // tracks the active theme name from hypr-theme-active.sh
        try {
            return activeFile.text().match(/THEME_NAME="(.*)"/)?.[1] ?? "";
        } catch (e) {
            return "";
        }
    }

    readonly property string themeRoot: `${Paths.home}/.config/.hypr-themes`

    function scan(): void {
        scanProc.running = true;
    }

    function apply(theme: var): void {
        if (!theme || !theme.script || root.applying)
            return;
        root.applying = true;
        root.applyingName = theme.name;
        // Match Anarchy-Bar: run-theme.sh applies the theme, updates the
        // wallpaper, and synchronizes the shell scheme itself.
        applyProc.command = ["bash", `${root.themeRoot}/run-theme.sh`, theme.script];
        applyProc.running = true;
    }

    FileView {
        id: activeFile

        path: `${Paths.home}/.local/share/themes/hypr-theme-active.sh`
        watchChanges: true
        onFileChanged: reload()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: activeFile.reload()
    }

    Process {
        id: scanProc

        command: ["bash", `${root.themeRoot}/scan-themes.sh`]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                const lines = text.trim().split("\n");
                for (let i = 0; i < lines.length; ++i) {
                    if (!lines[i].trim())
                        continue;
                    try {
                        found.push(JSON.parse(lines[i]));
                    } catch (e) {}
                }
                root.themes = found;
            }
        }
    }

    Process {
        id: applyProc

        command: []
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: {
            root.applying = false;
            root.applyingName = "";
        }
    }
}
