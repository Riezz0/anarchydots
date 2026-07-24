import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Scope {
    id: theme

    property color background: "#1e0c0c"
    property color foreground: "#c6c2c2"
    property color color1: "#B96E48"
    property color color2: "#54616c"
    property color color3: "#9c7251"
    property color color4: "#D1986C"
    property color color5: "#9a8f8f"
    property color color6: "#718291"
    property color muted: "#705c5c"

    readonly property string walColorsPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"

    function applyWalColors() {
        if (!colorFile.loaded)
            return

        try {
            const data = JSON.parse(colorFile.text())
            background = data.special.background
            foreground = data.special.foreground
            accent = data.colors.color4
            red = data.colors.color1
            green = data.colors.color2
            yellow = data.colors.color3
            blue = data.colors.color4
            magenta = data.colors.color5
            cyan = data.colors.color6
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
