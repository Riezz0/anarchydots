import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var themes: []
    property var _scanBuffer: []

    function applyTheme(script) {
        applyProc.command = ["setsid", "bash", "/home/riezzo/.config/.hypr-themes/run-theme.sh", script]
        applyProc.running = true
    }

    function scanThemes() {
        root._scanBuffer = []
        scanProc.running = true
    }

    Process {
        id: applyProc
        running: false
    }

    Process {
        id: scanProc
        command: ["bash", "/home/riezzo/.config/.hypr-themes/scan-themes.sh"]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim()
                if (!trimmed) return
                try {
                    const t = JSON.parse(trimmed)
                    t.thumbnail = "file://" + t.thumbnail
                    root._scanBuffer.push(t)
                    root.themes = root._scanBuffer.slice()
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!scanProc.running) scanThemes()
        }
    }

    Component.onCompleted: scanThemes()
}
