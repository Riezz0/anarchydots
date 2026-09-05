import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Scope {
    id: theme

    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"
    property color color1: "#f38ba8"
    property color color2: "#a6e3a1"
    property color color3: "#f9e2af"
    property color color4: "#89b4fa"
    property color color5: "#f5c2e7"
    property color color6: "#94e2d5"
    property color muted: "#585b70"

    readonly property string walColorsPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"

    function applyWalColors() {
        if (!colorFile.loaded)
            return

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
            console.warn("powerbar: failed to parse pywal colors:", e)
        }
    }

    FileView {
        id: colorFile
        path: theme.walColorsPath
        watchChanges: true
        onLoaded: theme.applyWalColors()
        onFileChanged: theme.applyWalColors()
    }
}
