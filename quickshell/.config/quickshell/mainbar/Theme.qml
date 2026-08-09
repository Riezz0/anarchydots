import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Scope {
    id: theme

    property color background: "#1d2021"
    property color foreground: "#d5c4a1"
    property color color1: "#fb4934"
    property color color2: "#b8bb26"
    property color color3: "#fabd2f"
    property color color4: "#83a598"
    property color color5: "#d3869b"
    property color color6: "#8ec07c"
    property color muted: "#665c54"

    readonly property string walColorsPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"

    readonly property string reloadTriggerPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/reload.trigger"

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

    FileView {
        id: reloadTrigger
        path: theme.reloadTriggerPath
        watchChanges: true
        onFileChanged: colorFile.reload()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: colorFile.reload()
    }
}
