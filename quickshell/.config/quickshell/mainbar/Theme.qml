import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Scope {
    id: theme

    property color background: "#1a1b26"
    property color foreground: "#c0caf5"
    property color color1: "#f7768e"
    property color color2: "#9ece6a"
    property color color3: "#e0af68"
    property color color4: "#7aa2f7"
    property color color5: "#bb9af7"
    property color color6: "#7dcfff"
    property color muted: "#414868"

    readonly property string walColorsPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"

    function applyWalColors() {
        if (!colorFile.loaded) {
            reloadTimer.restart()
            return
        }

        try {
            const data = JSON.parse(colorFile.text())
            background = data.special.background
            foreground = data.special.foreground
            color1 = data.colors.color1
            color2 = data.colors.color2
            color3 = data.colors.color3
            color4 = data.colors.color4
            color5 = data.colors.color5
            color6 = data.colors.color6
            muted = data.colors.color8
        } catch (e) {
            // Pywal can briefly leave the file incomplete while rewriting it.
            reloadTimer.restart()
        }
    }

    Timer {
        id: reloadTimer
        interval: 150
        repeat: false
        onTriggered: colorFile.reload()
    }

    Timer {
        // Poll as well as watching: some VM/shared filesystems miss Pywal's
        // atomic replacement of colors.json.
        interval: 1000
        repeat: true
        running: true
        onTriggered: colorFile.reload()
    }

    FileView {
        id: colorFile
        path: theme.walColorsPath
        watchChanges: true
        onLoaded: theme.applyWalColors()
        onFileChanged: reloadTimer.restart()
    }
}
