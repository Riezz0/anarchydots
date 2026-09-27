import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
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
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    // Cursor detection can fail on VMs or before Hyprland reports its outputs.
    // Keep the app usable by falling back to the first Quickshell screen.
    screen: monitorForCursor()
    visible: Quickshell.screens.length > 0
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var themes: []
    property var carouselThemes: []
    property int cardRadius: 8
    property int thumbnailBorderThickness: 0
    property string thumbnailShape: "portrait"
    readonly property bool compactThumbnails: thumbnailShape === "square" || thumbnailShape === "circle"
    readonly property bool circularThumbnails: thumbnailShape === "circle"
    readonly property int cardWidth: thumbnailShape === "landscape" ? 360 : 230
    readonly property int cardHeight: thumbnailShape === "landscape" ? 230 : 360
    readonly property string statePath: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        + "/.cache/anarchy-theme-switcher.state"
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

    function thumbnailSource(themeData) {
        var path = themeData && themeData.thumbnail ? themeData.thumbnail : ""
        if (path === "") return ""
        return path.indexOf("://") !== -1 ? path : "file://" + path
    }

    function reloadSettings() {
        try {
            var data = JSON.parse(settingsFile.text())
            if (data.barRadius !== undefined) cardRadius = data.barRadius
            if (data.barBorderThickness !== undefined) thumbnailBorderThickness = data.barBorderThickness
            if (data.themeSwitcherThumbnailShape !== undefined)
                thumbnailShape = data.themeSwitcherThumbnailShape === "rounded-square"
                    ? "square"
                    : (data.themeSwitcherThumbnailShape === "rounded"
                            || data.themeSwitcherThumbnailShape === "vertical"
                        ? "portrait"
                        : data.themeSwitcherThumbnailShape)
            else if (data.themeThumbnailsCircular === true)
                thumbnailShape = "circle"
        } catch (e) {}
    }

    FileView {
        id: settingsFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"
        watchChanges: true
        onLoaded: switcher.reloadSettings()
        onFileChanged: switcher.reloadSettings()
    }

    FileView {
        id: switcherStateFile
        path: switcher.statePath
    }

    Component.onCompleted: switcherStateFile.setText("open")
    Component.onDestruction: switcherStateFile.setText("closed")

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
            preferredHighlightBegin: width / 2 - switcher.cardWidth / 2
            preferredHighlightEnd: width / 2 + switcher.cardWidth / 2
            currentIndex: switcher.themes.length

            onMovementEnded: {
                var count = switcher.themes.length
                if (count === 0) return
                if (currentIndex < count) currentIndex += count * 2
                else if (currentIndex >= count * 4) currentIndex -= count * 2
            }

            delegate: Item {
                id: cardWrapper
                required property var modelData
                required property int index
                readonly property int thumbnailBorderWidth:
                    switcher.compactThumbnails || index === themeList.currentIndex
                    ? switcher.thumbnailBorderThickness
                    : 0
                width: switcher.cardWidth
                height: switcher.cardHeight

                Rectangle {
                    id: card
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    radius: switcher.compactThumbnails ? 0 : switcher.cardRadius
                    color: switcher.compactThumbnails
                        ? "transparent"
                        : (themeCardMouse.containsMouse && cardWrapper.index === themeList.currentIndex
                            ? Qt.rgba(switcher.secondary.r, switcher.secondary.g, switcher.secondary.b, 0.75)
                            : Qt.rgba(switcher.background.r, switcher.background.g, switcher.background.b, 0.88))
                    border.color: "transparent"
                    border.width: 0
                    scale: cardWrapper.index === themeList.currentIndex ? 1.0 : 0.86
                    Behavior on scale { NumberAnimation { duration: 180 } }

                    Image {
                        id: thumbnail
                        width: switcher.compactThumbnails
                            ? Math.max(0, Math.min(parent.width - 14, parent.height - 14) - 2 * cardWrapper.thumbnailBorderWidth)
                            : Math.max(0, parent.width - 2 * cardWrapper.thumbnailBorderWidth)
                        height: switcher.compactThumbnails
                            ? width
                            : Math.max(0, parent.height - 2 * cardWrapper.thumbnailBorderWidth)
                        anchors.centerIn: parent
                        source: switcher.thumbnailSource(cardWrapper.modelData)
                        cache: true
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    Rectangle {
                        id: maskRect
                        anchors.fill: thumbnail
                        radius: switcher.circularThumbnails
                            ? width / 2
                            : Math.min(
                                Math.max(0, switcher.cardRadius - cardWrapper.thumbnailBorderWidth),
                                width / 2
                            )
                        color: "white"
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: thumbnail
                        source: thumbnail
                        maskSource: maskRect
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: switcher.compactThumbnails
                            ? Math.min(parent.width - 14, parent.height - 14)
                            : parent.width
                        height: switcher.compactThumbnails ? width : parent.height
                        radius: switcher.circularThumbnails
                            ? width / 2
                            : Math.min(switcher.cardRadius, width / 2)
                        color: "transparent"
                        border.color: cardWrapper.index === themeList.currentIndex
                            ? switcher.secondary
                            : Qt.rgba(switcher.muted.r, switcher.muted.g, switcher.muted.b, 0.65)
                        border.width: cardWrapper.thumbnailBorderWidth
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 18
                        text: cardWrapper.modelData.name
                        color: themeCardMouse.containsMouse && cardWrapper.index === themeList.currentIndex
                            ? switcher.background
                            : switcher.foreground
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
                        cursorShape: cardWrapper.index === themeList.currentIndex
                            ? Qt.PointingHandCursor
                            : Qt.ArrowCursor
                        onClicked: {
                            if (cardWrapper.index === themeList.currentIndex)
                                switcher.applyTheme(cardWrapper.modelData)
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "Scroll or Left/Right to browse  •  Enter/click highlighted theme to apply  •  Escape to close"
            color: switcher.muted
            font.pixelSize: 12
            font.family: "JetBrainsMono Nerd Font"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        focus: true
        onWheel: event => {
            event.accepted = true
            if (event.angleDelta.y < 0) {
                if (themeList.currentIndex >= switcher.carouselThemes.length - 1)
                    themeList.currentIndex = 0
                else
                    themeList.incrementCurrentIndex()
            } else if (event.angleDelta.y > 0) {
                if (themeList.currentIndex <= 0)
                    themeList.currentIndex = switcher.carouselThemes.length - 1
                else
                    themeList.decrementCurrentIndex()
            }
            themeList.positionViewAtIndex(themeList.currentIndex, ListView.Contain)
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
