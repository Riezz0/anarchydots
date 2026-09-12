import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtCore
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Window {
    id: player

    property string cursorMonitor: ""
    property int currentIndex: -1
    property bool minimized: false
    property bool fullscreen: false
    property bool videoFullscreen: false
    property bool dialogOpen: false
    property bool seeking: false
    property string notice: ""
    property color background: "#1e1e2e"
    property color foreground: "#cdd6f4"
    property color muted: "#7f849c"
    property color accent: "#89b4fa"
    property color accent2: "#a6e3a1"
    property color accent3: "#cba6f7"
    property var visualizerColors: [
        "#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#94e2d5", "#89b4fa", "#cba6f7",
        "#eba0ac", "#f2cdcd", "#f5c2e7", "#74c7ec", "#b4befe", "#f5e0dc", "#bac2de"
    ]
    property color surface: "#313244"
    property color surfaceAlt: "#45475a"
    property color border: "#585b70"
    property real volumeLevel: 0.8
    property real visualizerPhase: 0
    property int speedIndex: 1
    property int qPlayerRadius: 2
    property int qPlayerButtonRadius: 2
    property int widgetRadius: 10
    property int widgetBorderThickness: 0
    property real widgetOpacity: 1.0
    readonly property var speedOptions: [0.75, 1.0, 1.25, 1.5, 2.0]

    visible: cursorMonitor.length > 0 && !minimized
    x: {
        var target = monitorForCursor()
        return target ? target.x + Math.max(0, (target.width - width) / 2) : 0
    }
    y: {
        var target = monitorForCursor()
        return target ? target.y + Math.max(0, (target.height - height) / 2) : 0
    }
    width: 1180
    height: 720
    title: "Q-Player"
    flags: Qt.Window | Qt.FramelessWindowHint
        | (!dialogOpen ? Qt.WindowStaysOnTopHint : 0)
    color: player.background

    function minimize() {
        minimized = true
        visible = false
        if (!cursorProcess.running)
            cursorProcess.running = true
    }

    function restore() {
        minimized = false
        visible = true
        raise()
        requestActivate()
    }

    function toggleFullscreen() {
        if (currentIndex >= 0 && playlist.get(currentIndex).video) {
            toggleVideoFullscreen()
            return
        }
        fullscreen = !fullscreen
        if (fullscreen)
            showFullScreen()
        else
            showNormal()
    }

    function toggleVideoFullscreen() {
        if (currentIndex < 0 || !playlist.get(currentIndex).video)
            return
        videoFullscreen = !videoFullscreen
        fullscreen = videoFullscreen
        if (videoFullscreen)
            showFullScreen()
        else
            showNormal()
    }

    function stopPlayback() {
        mediaPlayer.stop()
        mediaPlayer.position = 0
        if (videoFullscreen) {
            videoFullscreen = false
            fullscreen = false
            showNormal()
        }
        notice = "Stopped"
    }

    function hasCurrentVideo() {
        return currentIndex >= 0 && playlist.get(currentIndex).video
    }

    function monitorForCursor() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === cursorMonitor)
                return Quickshell.screens[i]
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function applyWalColors() {
        try {
            var data = JSON.parse(walColors.text())
            background = data.special.background
            foreground = data.special.foreground
            muted = data.colors.color8
            accent = data.colors.color4
            accent2 = data.colors.color2
            accent3 = data.colors.color5
            visualizerColors = [
                data.colors.color1, data.colors.color2, data.colors.color3,
                data.colors.color4, data.colors.color5, data.colors.color6,
                data.colors.color7, data.colors.color9, data.colors.color10,
                data.colors.color11, data.colors.color12, data.colors.color13,
                data.colors.color14, data.colors.color15
            ]
            surface = data.colors.color0
            surfaceAlt = data.colors.color8
            border = data.colors.color4
        } catch (e) {
            console.warn("Q-Player: failed to parse pywal colors:", e)
        }
    }

    function cleanTitle(url) {
        var path = url.toString().replace(/^file:\/\//, "")
        var name = path.substring(path.lastIndexOf("/") + 1)
        return decodeURIComponent(name).replace(/\.[^.]+$/, "")
    }

    function applyPlayerSettings() {
        try {
            var data = JSON.parse(playerSettings.text())
            if (data.qPlayerButtonRadius !== undefined)
                qPlayerButtonRadius = data.qPlayerButtonRadius
            if (data.widgetRadius !== undefined)
                widgetRadius = data.widgetRadius
            if (data.widgetBorderThickness !== undefined)
                widgetBorderThickness = data.widgetBorderThickness
            if (data.widgetOpacity !== undefined)
                widgetOpacity = data.widgetOpacity
        } catch (e) {}
    }

    function isVideo(url) {
        return /\.(mp4|mkv|webm|avi|mov|m4v|mpeg|mpg|ogv)$/i.test(url.toString())
    }

    function addFiles(files) {
        for (var i = 0; i < files.length; i++) {
            var url = files[i].toString()
            if (url === "" || !/^file:/i.test(url))
                url = "file://" + url
            playlist.append({ url: url, title: cleanTitle(url), video: isVideo(url) })
        }
        if (currentIndex < 0 && playlist.count > 0)
            playAt(0)
    }

    function playAt(index) {
        if (index < 0 || index >= playlist.count)
            return
        currentIndex = index
        mediaPlayer.source = playlist.get(index).url
        mediaPlayer.play()
    }

    function playNext() {
        if (playlist.count === 0)
            return
        playAt((currentIndex + 1) % playlist.count)
    }

    function playPrevious() {
        if (playlist.count === 0)
            return
        if (mediaPlayer.position > 4000) {
            mediaPlayer.position = 0
            return
        }
        playAt((currentIndex - 1 + playlist.count) % playlist.count)
    }

    function togglePlay() {
        if (mediaPlayer.playbackState === MediaPlayer.PlayingState)
            mediaPlayer.pause()
        else if (mediaPlayer.source !== "")
            mediaPlayer.play()
        else if (playlist.count > 0)
            playAt(0)
    }

    function formatTime(milliseconds) {
        var seconds = Math.max(0, Math.floor(milliseconds / 1000))
        var minutes = Math.floor(seconds / 60)
        seconds = seconds % 60
        return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
    }

    ListModel { id: playlist }

    FileView {
        id: walColors
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"
        watchChanges: true
        onLoaded: player.applyWalColors()
        onFileChanged: player.applyWalColors()
    }

    FileView {
        id: playerSettings
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"
        watchChanges: true
        onLoaded: player.applyPlayerSettings()
        onFileChanged: player.applyPlayerSettings()
        onTextChanged: player.applyPlayerSettings()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: walColors.reload()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: playerSettings.reload()
    }

    Process {
        id: cursorProcess
        command: ["bash", "-c", "bash ~/.config/quickshell/Anarchy-Bar/Scripts/detect-cursor-monitor.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: player.cursorMonitor = text.trim()
        }
    }

    Timer {
        interval: 1000
        running: player.minimized
        repeat: true
        onTriggered: {
            if (!cursorProcess.running)
                cursorProcess.running = true
        }
    }

    AudioOutput {
        id: audioOutput
        volume: player.volumeLevel
    }

    MediaPlayer {
        id: mediaPlayer
        audioOutput: audioOutput
        videoOutput: player.videoFullscreen ? fullscreenVideoOutput
            : (player.minimized && player.hasCurrentVideo() ? miniVideoOutput : normalVideoOutput)
        playbackRate: player.speedOptions[player.speedIndex]

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.InvalidMedia) {
                player.notice = "This file could not be played"
            } else if (mediaStatus === MediaPlayer.EndOfMedia) {
                player.playNext()
            } else if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                player.notice = ""
            }
        }
        onErrorOccurred: function(error, errorString) {
            if (error !== MediaPlayer.NoError)
                player.notice = errorString || "Playback error"
        }
    }

    Timer {
        interval: 75
        running: player.currentIndex >= 0 && !player.hasCurrentVideo()
            && mediaPlayer.playbackState === MediaPlayer.PlayingState
        repeat: true
        onTriggered: player.visualizerPhase += 0.18
    }

    PanelWindow {
        id: miniBar
        screen: player.monitorForCursor()
        visible: player.minimized && player.cursorMonitor.length > 0
        anchors { bottom: true; left: true }
        margins {
            bottom: 12
            left: 14
        }
        implicitWidth: player.hasCurrentVideo() ? 320 : 330
        implicitHeight: player.hasCurrentVideo() ? 180 : 48
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top

        Rectangle {
            anchors.fill: parent
            radius: player.widgetRadius
            color: Qt.rgba(player.background.r, player.background.g, player.background.b, player.widgetOpacity)
            border.color: player.border
            border.width: player.widgetBorderThickness
            clip: true

            VideoOutput {
                id: miniVideoOutput
                anchors.fill: parent
                visible: player.hasCurrentVideo()
                fillMode: VideoOutput.PreserveAspectCrop
                opacity: player.widgetOpacity
            }

            Rectangle {
                anchors.fill: parent
                visible: player.hasCurrentVideo()
                color: Qt.rgba(player.background.r, player.background.g, player.background.b, 0.78)
                anchors.topMargin: parent.height - 36
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8
                visible: !player.hasCurrentVideo()
                z: 1
                Item {
                    Layout.preferredWidth: 84
                    Layout.fillHeight: true
                    Row {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        spacing: 3
                        Repeater {
                            model: 12
                            Rectangle {
                                required property int index
                                width: 4
                                height: 7 + Math.abs(Math.sin(player.visualizerPhase + index * 0.58)) * 22
                                anchors.bottom: parent.bottom
                                radius: player.qPlayerRadius
                                color: player.visualizerColors[index % player.visualizerColors.length]
                            }
                        }
                    }
                }
                Item {
                    id: audioTitleViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    property real scrollOffset: 0
                    property bool needsScroll: false

                    Text {
                        id: audioTitleMeasure
                        visible: false
                        text: player.currentIndex >= 0 ? playlist.get(player.currentIndex).title : "Q-Player"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        onImplicitWidthChanged: {
                            audioTitleViewport.needsScroll = implicitWidth > audioTitleViewport.width
                            audioTitleViewport.scrollOffset = 0
                        }
                    }

                    Text {
                        anchors.fill: parent
                        visible: !audioTitleViewport.needsScroll
                        text: audioTitleMeasure.text
                        color: player.foreground
                        font: audioTitleMeasure.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Item {
                        anchors.fill: parent
                        visible: audioTitleViewport.needsScroll
                        clip: true
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: -audioTitleViewport.scrollOffset
                            spacing: 0
                            Repeater {
                                model: 2
                                Text {
                                    text: audioTitleMeasure.text
                                    color: player.foreground
                                    font: audioTitleMeasure.font
                                }
                            }
                        }
                    }

                    Timer {
                        interval: 30
                        repeat: true
                        running: audioTitleViewport.needsScroll
                        onTriggered: {
                            audioTitleViewport.scrollOffset += 1
                            if (audioTitleViewport.scrollOffset >= audioTitleMeasure.implicitWidth)
                                audioTitleViewport.scrollOffset = 0
                        }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: player.qPlayerButtonRadius
                    color: player.accent
                    Item {
                        anchors.centerIn: parent
                        width: 12
                        height: 14
                        visible: mediaPlayer.playbackState === MediaPlayer.PlayingState
                        Rectangle { x: 0; width: 3; height: parent.height; color: player.background }
                        Rectangle { x: 9; width: 3; height: parent.height; color: player.background }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
                        text: ">"
                        color: player.background
                        font.bold: true
                    }
                    MouseArea { anchors.fill: parent; onClicked: player.togglePlay() }
                }
                Button {
                    text: "OPEN"
                    onClicked: player.restore()
                    contentItem: Text { text: "OPEN"; color: player.accent; font.bold: true; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { color: "transparent" }
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                height: 36
                spacing: 8
                visible: player.hasCurrentVideo()
                z: 2
                Item {
                    id: videoTitleViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    property real scrollOffset: 0
                    property bool needsScroll: false

                    Text {
                        id: videoTitleMeasure
                        visible: false
                        text: player.currentIndex >= 0 ? playlist.get(player.currentIndex).title : "Q-Player"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        onImplicitWidthChanged: {
                            videoTitleViewport.needsScroll = implicitWidth > videoTitleViewport.width
                            videoTitleViewport.scrollOffset = 0
                        }
                    }

                    Text {
                        anchors.fill: parent
                        visible: !videoTitleViewport.needsScroll
                        text: videoTitleMeasure.text
                        color: player.foreground
                        font: videoTitleMeasure.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Item {
                        anchors.fill: parent
                        visible: videoTitleViewport.needsScroll
                        clip: true
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            x: -videoTitleViewport.scrollOffset
                            spacing: 0
                            Repeater {
                                model: 2
                                Text {
                                    text: videoTitleMeasure.text
                                    color: player.foreground
                                    font: videoTitleMeasure.font
                                }
                            }
                        }
                    }

                    Timer {
                        interval: 30
                        repeat: true
                        running: videoTitleViewport.needsScroll
                        onTriggered: {
                            videoTitleViewport.scrollOffset += 1
                            if (videoTitleViewport.scrollOffset >= videoTitleMeasure.implicitWidth)
                                videoTitleViewport.scrollOffset = 0
                        }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: player.qPlayerButtonRadius
                    color: player.accent
                    Item {
                        anchors.centerIn: parent
                        width: 12
                        height: 14
                        visible: mediaPlayer.playbackState === MediaPlayer.PlayingState
                        Rectangle { x: 0; width: 3; height: parent.height; color: player.background }
                        Rectangle { x: 9; width: 3; height: parent.height; color: player.background }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: mediaPlayer.playbackState !== MediaPlayer.PlayingState
                        text: ">"
                        color: player.background
                        font.bold: true
                    }
                    MouseArea { anchors.fill: parent; onClicked: player.togglePlay() }
                }
                Button {
                    text: "OPEN"
                    onClicked: player.restore()
                    contentItem: Text { text: "OPEN"; color: player.accent; font.bold: true; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { color: "transparent" }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Add media to Q-Player"
        fileMode: FileDialog.OpenFiles
        modality: Qt.ApplicationModal
        nameFilters: ["Media files (*.mp3 *.wav *.flac *.ogg *.m4a *.aac *.mp4 *.mkv *.webm *.avi *.mov)", "All files (*)"]
        onVisibleChanged: player.dialogOpen = visible
        onAccepted: player.addFiles(selectedFiles)
    }

    Rectangle {
        id: windowCard
        anchors.fill: parent
        radius: 0
        color: player.background
        gradient: Gradient {
            GradientStop { position: 0.0; color: player.background }
            GradientStop { position: 0.58; color: player.surface }
            GradientStop { position: 1.0; color: Qt.darker(player.background, 1.08) }
        }
        border.color: Qt.rgba(player.border.r, player.border.g, player.border.b, 0.8)
        border.width: 0
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
        Text {
                        text: "Q-PLAYER"
                        color: player.accent3
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Text {
                        text: playlist.count + " item" + (playlist.count === 1 ? "" : "s") + " in queue"
                        color: player.muted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }

                Button {
                    text: "+  Add media"
                    onClicked: fileDialog.open()
                    contentItem: Text { text: "+  Add media"; color: player.background; font.bold: true; font.family: "JetBrainsMono Nerd Font"; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { radius: player.qPlayerButtonRadius; color: player.accent }
                }
                Button {
                    text: "MIN"
                    onClicked: player.minimize()
                    contentItem: Text { text: "MIN"; color: player.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { radius: player.qPlayerButtonRadius; color: player.surface }
                }
                Button {
                    text: player.fullscreen ? "WINDOW" : "FULL"
                    onClicked: player.toggleFullscreen()
                    contentItem: Text { text: player.fullscreen ? "WINDOW" : "FULL"; color: player.fullscreen ? player.background : player.accent2; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { radius: player.qPlayerButtonRadius; color: player.fullscreen ? player.accent2 : player.surface }
                }
                Button {
                    text: "Close"
                    onClicked: Qt.quit()
                    contentItem: Text { text: "Close"; color: player.foreground; font.family: "JetBrainsMono Nerd Font"; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { radius: player.qPlayerButtonRadius; color: player.surface }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 420
                    radius: player.qPlayerRadius
                    color: player.surface
                    border.color: player.border
                    border.width: 0
                    clip: true

                    VideoOutput {
                        id: normalVideoOutput
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectFit
                        visible: player.currentIndex >= 0 && playlist.get(player.currentIndex).video && !player.videoFullscreen
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: !normalVideoOutput.visible && !player.videoFullscreen
                        color: player.surface

                        Column {
                            anchors.centerIn: parent
                            spacing: 15
                            Text {
                                width: parent.parent.width
                                text: player.currentIndex >= 0 ? "AUDIO" : "Q"
                                color: player.accent
                                font.pixelSize: player.currentIndex >= 0 ? 30 : 54
                                font.family: "JetBrainsMono Nerd Font"
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Row {
                                width: Math.min(700, parent.parent.width - 80)
                                height: 110
                                spacing: 4
                                visible: player.currentIndex >= 0 && !player.hasCurrentVideo()
                                anchors.horizontalCenter: parent.horizontalCenter
                                Repeater {
                                    model: 64
                                    Rectangle {
                                        required property int index
                                        width: 7
                                        height: 16 + Math.abs(Math.sin(player.visualizerPhase + index * 0.58)) * 94
                                        anchors.bottom: parent.bottom
                                        radius: player.qPlayerRadius
                                        color: player.visualizerColors[index % player.visualizerColors.length]
                                    }
                                }
                            }
                            Item {
                                id: mainTitleViewport
                                width: Math.min(520, parent.parent.width - 80)
                                height: 30
                                anchors.horizontalCenter: parent.horizontalCenter
                                clip: true
                                property real scrollOffset: 0
                                property bool needsScroll: false
                                onWidthChanged: {
                                    needsScroll = mainTitleMeasure.implicitWidth > width
                                    scrollOffset = 0
                                }
                                Text {
                                    id: mainTitleMeasure
                                    visible: false
                                    text: player.currentIndex >= 0 ? playlist.get(player.currentIndex).title : "Drop audio or video here"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    onImplicitWidthChanged: {
                                        mainTitleViewport.needsScroll = implicitWidth > mainTitleViewport.width
                                        mainTitleViewport.scrollOffset = 0
                                    }
                                }
                                Text {
                                    anchors.fill: parent
                                    visible: !mainTitleViewport.needsScroll
                                    text: mainTitleMeasure.text
                                    color: player.foreground
                                    font: mainTitleMeasure.font
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                                Item {
                                    anchors.fill: parent
                                    visible: mainTitleViewport.needsScroll
                                    clip: true
                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: -mainTitleViewport.scrollOffset
                                        spacing: 0
                                        Repeater {
                                            model: 2
                                            Text {
                                                text: mainTitleMeasure.text
                                                color: player.foreground
                                                font: mainTitleMeasure.font
                                            }
                                        }
                                    }
                                }
                                Timer {
                                    interval: 30
                                    repeat: true
                                    running: mainTitleViewport.needsScroll
                                    onTriggered: {
                                        mainTitleViewport.scrollOffset += 1
                                        if (mainTitleViewport.scrollOffset >= mainTitleMeasure.implicitWidth)
                                            mainTitleViewport.scrollOffset = 0
                                    }
                                }
                            }
                            Text {
                                width: parent.parent.width
                                text: player.currentIndex >= 0 ? "Audio playback" : "or use Add media"
                                color: player.muted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        onDropped: function(drop) {
                            if (drop.urls.length > 0)
                                player.addFiles(drop.urls)
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    radius: player.qPlayerRadius
                    color: Qt.rgba(player.surface.r, player.surface.g, player.surface.b, 0.72)
                    border.color: Qt.rgba(player.accent2.r, player.accent2.g, player.accent2.b, 0.72)
                    border.width: 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 9
                        RowLayout {
                            Layout.fillWidth: true
                             Text { text: "QUEUE"; color: player.accent2; font.bold: true; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "Clear"
                                visible: playlist.count > 0
                                onClicked: { playlist.clear(); player.currentIndex = -1; mediaPlayer.stop() }
                                background: Rectangle { color: "transparent" }
                                contentItem: Text { text: "Clear"; color: player.muted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        ListView {
                            id: queueList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: playlist
                            delegate: Rectangle {
                                required property int index
                                required property string title
                                required property bool video
                                width: queueList.width
                                height: 48
                                radius: player.qPlayerRadius
                                color: index === player.currentIndex ? Qt.rgba(player.accent.r, player.accent.g, player.accent.b, 0.22) : "transparent"
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 7
                                    spacing: 8
                                    Text { text: video ? "VIDEO" : "AUDIO"; color: video ? player.accent2 : player.accent; font.pixelSize: 9; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
                                    Text { Layout.fillWidth: true; text: title; color: player.foreground; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight }
                                    Text { text: "x"; color: player.muted; font.pixelSize: 14 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: player.playAt(index)
                                }
                                MouseArea {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 32
                                    onClicked: {
                                        if (index === player.currentIndex) {
                                            mediaPlayer.stop()
                                            player.currentIndex = -1
                                        } else if (index < player.currentIndex) {
                                            player.currentIndex--
                                        }
                                        playlist.remove(index)
                                    }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: playlist.count === 0
                                text: "Your queue is empty"
                                color: player.muted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text { text: player.formatTime(mediaPlayer.position); color: player.muted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, mediaPlayer.duration)
                    value: mediaPlayer.position
                    onMoved: if (mediaPlayer.duration > 0) mediaPlayer.position = value
                    background: Rectangle { x: progressSlider.leftPadding; y: progressSlider.topPadding + progressSlider.availableHeight / 2 - 2; width: progressSlider.availableWidth; height: 4; radius: player.qPlayerRadius; color: player.surfaceAlt }
                    handle: Rectangle { x: progressSlider.leftPadding + progressSlider.visualPosition * progressSlider.availableWidth - width / 2; y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2; width: 13; height: 13; radius: player.qPlayerRadius; color: player.accent }
                }
                Text { text: player.formatTime(mediaPlayer.duration); color: player.muted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Button {
                    text: "|<"
                    onClicked: player.playPrevious()
                    background: Rectangle { color: "transparent" }
                    contentItem: Text { text: "|<"; color: player.foreground; font.bold: true; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter }
                }
                Button {
                    implicitWidth: 40
                    implicitHeight: 40
                    padding: 0
                    text: mediaPlayer.playbackState === MediaPlayer.PlayingState ? "||" : ">"
                    onClicked: player.togglePlay()
                    background: Rectangle { radius: player.qPlayerButtonRadius; color: player.accent }
                    contentItem: Text { anchors.fill: parent; text: mediaPlayer.playbackState === MediaPlayer.PlayingState ? "||" : ">"; color: player.background; font.bold: true; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    text: ">|"
                    onClicked: player.playNext()
                    background: Rectangle { color: "transparent" }
                    contentItem: Text { text: ">|"; color: player.foreground; font.bold: true; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter }
                }
                Button {
                    text: "STOP"
                    onClicked: player.stopPlayback()
                    contentItem: Text { text: "STOP"; color: player.background; font.bold: true; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter }
                    background: Rectangle { radius: player.qPlayerButtonRadius; color: player.accent2 }
                }
                Text { Layout.fillWidth: true; text: player.notice; color: player.accent2; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; elide: Text.ElideRight }
                Rectangle {
                    implicitWidth: 74
                    implicitHeight: 30
                    radius: player.qPlayerButtonRadius
                    color: player.surface
                    border.color: player.border
                        border.width: 0
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: player.speedOptions[player.speedIndex].toFixed(2) + "x"
                        color: player.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: "v"
                        color: player.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: player.speedIndex = (player.speedIndex + 1) % player.speedOptions.length
                    }
                }
                Rectangle {
                    implicitWidth: 118
                    implicitHeight: 30
                    color: "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "VOL"
                        color: player.muted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Rectangle {
                        id: volumeTrack
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        radius: player.qPlayerRadius
                        color: player.surfaceAlt
                        Rectangle {
                            width: parent.width * player.volumeLevel
                            height: parent.height
                            radius: player.qPlayerRadius
                            color: player.accent
                        }
                        Rectangle {
                            x: parent.width * player.volumeLevel - width / 2
                            y: -4
                            width: 12
                            height: 12
                            radius: player.qPlayerRadius
                            color: player.foreground
                            border.color: player.accent
                            border.width: 0
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.leftMargin: 26
                        cursorShape: Qt.PointingHandCursor
                        onPressed: player.volumeLevel = Math.max(0, Math.min(1, mouse.x / width))
                        onPositionChanged: if (pressed) player.volumeLevel = Math.max(0, Math.min(1, mouse.x / width))
                    }
                }
            }
        }

        Rectangle {
            id: fullscreenVideoSurface
            anchors.fill: parent
            visible: player.videoFullscreen
            z: 100
            color: "#000000"

            VideoOutput {
                id: fullscreenVideoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                onDoubleClicked: player.toggleVideoFullscreen()
            }
        }

        Keys.onSpacePressed: player.togglePlay()
        Keys.onLeftPressed: player.playPrevious()
        Keys.onRightPressed: player.playNext()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_F) {
                player.toggleFullscreen()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                if (player.fullscreen) {
                    player.fullscreen = false
                    player.videoFullscreen = false
                    player.showNormal()
                } else {
                    Qt.quit()
                }
                event.accepted = true
            }
        }
        Component.onCompleted: forceActiveFocus()
    }
}
