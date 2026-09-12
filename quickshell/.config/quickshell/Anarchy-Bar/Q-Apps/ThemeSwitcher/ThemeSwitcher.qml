import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: switcher

    property string cursorMonitor: ""

    function monitorForCursor() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === cursorMonitor)
                return Quickshell.screens[i]
        }
        return Quickshell.screens[0]
    }

    screen: monitorForCursor()
    visible: cursorMonitor.length > 0
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var themes: []
    property var carouselThemes: []
    property bool cacheReady: false
    property int cardRadius: 8
    property int cardBorderThickness: 1
    property string thumbnailStyle: "cover"
    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"
    property color muted: "#7f849c"
    property color accent: "#89b4fa"
    property color secondary: "#a6e3a1"

    function reloadColors() {
        try {
            var data = JSON.parse(walColors.text())
            background = data.special.background
            foreground = data.special.foreground
            muted = data.colors.color8
            accent = data.colors.color4
            secondary = data.colors.color2
        } catch (e) {}
    }

    FileView {
        id: walColors
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"
        watchChanges: true
        onLoaded: switcher.reloadColors()
        onFileChanged: switcher.reloadColors()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: walColors.reload()
    }
    property string themeRoot: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        .toString().replace(/^file:\/\//, "") + "/.config/.hypr-themes"
    property string cacheDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        .toString().replace(/^file:\/\//, "") + "/.cache/anarchy-theme-switcher/thumbnails"

    function reloadSettings() {
        try {
            var data = JSON.parse(settingsFile.text())
            if (data.themeCardRadius !== undefined) cardRadius = data.themeCardRadius
            if (data.themeCardBorderThickness !== undefined) cardBorderThickness = data.themeCardBorderThickness
            if (data.themeThumbnailStyle !== undefined) thumbnailStyle = data.themeThumbnailStyle
        } catch (e) {}
    }

    FileView {
        id: settingsFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"
        watchChanges: true
        onLoaded: switcher.reloadSettings()
        onFileChanged: switcher.reloadSettings()
    }

    Process {
        id: cursorProcess
        command: ["bash", "-c", "bash ~/.config/quickshell/Anarchy-Bar/Scripts/detect-cursor-monitor.sh"]
        running: true
        stdout: StdioCollector {
            id: cursorOutput
            onStreamFinished: switcher.cursorMonitor = cursorOutput.text.trim()
        }
    }

    Process {
        id: scanProcess
        command: ["bash", switcher.themeRoot + "/scan-themes.sh"]
        running: true
        stdout: StdioCollector {
            id: scanOutput
            onStreamFinished: {
                var found = []
                var lines = scanOutput.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i].trim()) continue
                    try { found.push(JSON.parse(lines[i])) } catch (e) {}
                }
                switcher.themes = found
                switcher.carouselThemes = found.concat(found, found, found, found, found)
                cacheProcess.running = true
                Qt.callLater(function() {
                    if (found.length > 0) {
                        themeList.currentIndex = found.length * 2
                        themeList.positionViewAtIndex(themeList.currentIndex, ListView.Center)
                    }
                })
            }
        }
    }

    Process {
        id: cacheProcess
        command: ["bash", "-c", "cache=\"$HOME/.cache/anarchy-theme-switcher/thumbnails\"; mkdir -p \"$cache\"; for d in \"$HOME/.config/.hypr-themes\"/*/; do [ -d \"$d\" ] || continue; name=$(basename \"$d\"); for f in thumbnail.png thumbnail.jpg thumbnail.jpeg thumbnail.webp; do if [ -f \"$d$f\" ]; then cp -f \"$d$f\" \"$cache/$name.png\"; break; fi; done; done"]
        running: false
        onExited: switcher.cacheReady = true
    }

    Process {
        id: applyProcess
        running: false
        onExited: Qt.quit()
    }

    function applyTheme(themeData) {
        if (!themeData || !themeData.script) return
        Quickshell.execDetached({
            command: ["bash", switcher.themeRoot + "/run-theme.sh", themeData.script]
        })
        Qt.quit()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(switcher.background.r, switcher.background.g, switcher.background.b, 0.55)
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 20

        Text {
            width: parent.width
            text: "Themes"
            color: switcher.foreground
            font.pixelSize: 24
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            horizontalAlignment: Text.AlignHCenter
        }

        ListView {
            id: themeList
            width: parent.width
            height: Math.min(switcher.height - 180, 420)
            orientation: ListView.Horizontal
            spacing: 18
            clip: true
            cacheBuffer: width * 2
            displayMarginBeginning: width
            displayMarginEnd: width
            model: switcher.carouselThemes
            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapToItem
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 115
            preferredHighlightEnd: width / 2 + 115
            currentIndex: switcher.themes.length

            onMovementEnded: {
                var count = switcher.themes.length
                if (count === 0) return
                if (currentIndex < count) currentIndex += count * 2
                else if (currentIndex >= count * 4) currentIndex -= count * 2
            }

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: 230
                height: 360
                radius: switcher.cardRadius
                color: themeCardMouse.containsMouse
                    ? Qt.rgba(switcher.accent.r, switcher.accent.g, switcher.accent.b, 0.75)
                    : Qt.rgba(switcher.background.r, switcher.background.g, switcher.background.b, 0.88)
                border.color: index === themeList.currentIndex ? switcher.accent : switcher.muted
                border.width: index === themeList.currentIndex
                    ? Math.max(1, switcher.cardBorderThickness + 2)
                    : switcher.cardBorderThickness
                scale: index === themeList.currentIndex ? 1.0 : 0.86
                Behavior on scale { NumberAnimation { duration: 180 } }

                Image {
                    id: thumbnail
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 7
                    anchors.leftMargin: 7
                    anchors.rightMargin: 7
                    height: 285
                        source: switcher.cacheReady
                        ? "file://" + switcher.cacheDir + "/" + modelData.name + ".png"
                        : ""
                    cache: true
                    fillMode: switcher.thumbnailStyle === "contain"
                        ? Image.PreserveAspectFit
                        : (switcher.thumbnailStyle === "stretch" ? Image.Stretch : Image.PreserveAspectCrop)
                    asynchronous: true
                    clip: true
                }

                Rectangle {
                    anchors.fill: thumbnail
                    color: "transparent"
                    border.color: switcher.muted
                    border.width: 1
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    text: modelData.name
                    color: themeCardMouse.containsMouse ? switcher.background : switcher.foreground
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: themeCardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        themeList.currentIndex = index
                        switcher.applyTheme(modelData)
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Use Left/Right to browse  •  Enter to apply  •  Escape to close"
            color: switcher.muted
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        WheelHandler {
            onWheel: event => {
                event.accepted = true
                if (event.angleDelta.y < 0) themeList.incrementCurrentIndex()
                else if (event.angleDelta.y > 0) themeList.decrementCurrentIndex()
                themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain)
            }
        }

        Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) {
            event.accepted = true
            if (themeList.currentIndex <= 0)
                themeList.currentIndex = switcher.carouselThemes.length - 1
            else
                themeList.decrementCurrentIndex()
            themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain)
        } else if (event.key === Qt.Key_Right) {
            event.accepted = true
            if (themeList.currentIndex >= switcher.carouselThemes.length - 1)
                themeList.currentIndex = 0
            else
                themeList.incrementCurrentIndex()
            themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain)
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            event.accepted = true
            switcher.applyTheme(switcher.themes[themeList.currentIndex % switcher.themes.length])
        } else if (event.key === Qt.Key_Escape) {
            event.accepted = true
            Qt.quit()
        }
        }
    }

}
