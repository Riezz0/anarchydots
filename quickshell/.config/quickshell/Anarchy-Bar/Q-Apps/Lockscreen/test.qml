import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

ApplicationWindow {
    id: testWindow
    width: 1920
    height: 1080
    visible: true
    title: "Lockscreen Test"
    color: "transparent"

    Theme { id: theme }

    property int barRadius: 10
    property int popupBorderThickness: 2
    property string lockscreenWallpaper: ""
    property bool lockscreenShowPassword: false
    property bool locked: true
    property string currentUsername: "user"
    property string currentAvatar: ""
    property var notifData: []

    property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)

    function expandPath(path) {
        if (path.startsWith("~")) return homeDir + path.substring(1)
        return path
    }

    Auth { id: auth }

    UserAvatar {
        visible: false
        Component.onCompleted: {}
    }

    Battery { id: battery }
    SystemStats { id: stats }
    WeatherService { id: weather }
    KbLayout { id: kbLayout }
    Salaat { id: salaat }

    Process {
        id: userProc
        command: ["whoami"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var name = line.trim()
                if (name.length > 0) testWindow.currentUsername = name
            }
        }
        Component.onCompleted: running = true
    }

    Connections {
        target: auth
        function onAuthSucceeded() {
            testWindow.locked = false
            testWindow.title = "Unlocked!"
            closeTimer.start()
        }
        function onAuthFailed() {
            testWindow.title = "Wrong password - try again"
        }
    }

    Timer {
        id: closeTimer
        interval: 1500
        onTriggered: {
            testWindow.locked = true
            testWindow.title = "Lockscreen Test"
        }
    }

    Rectangle {
        anchors.fill: parent
        color: theme.background

        Image {
            anchors.fill: parent
            source: testWindow.lockscreenWallpaper !== "" ? testWindow.expandPath(testWindow.lockscreenWallpaper) : ""
            fillMode: Image.PreserveAspectCrop
            visible: testWindow.lockscreenWallpaper !== ""
        }

        Dashboard {
            id: dashboard
            anchors.fill: parent
            visible: testWindow.locked

            Component.onCompleted: {
                leftPanel.city = Qt.binding(function() { return weather.city })
                leftPanel.temp = Qt.binding(function() { return weather.temp })
                leftPanel.feelsLike = Qt.binding(function() { return weather.feelsLike })
                leftPanel.condition = Qt.binding(function() { return weather.condition })
                leftPanel.icon = Qt.binding(function() { return weather.icon })
                leftPanel.cpuUsage = Qt.binding(function() { return stats.cpuUsage })
                leftPanel.ramUsage = Qt.binding(function() { return stats.ramUsage })
                leftPanel.ramUsed = Qt.binding(function() { return stats.ramUsed })
                leftPanel.ramTotal = Qt.binding(function() { return stats.ramTotal })
                leftPanel.temperature = Qt.binding(function() { return stats.temperature })
                leftPanel.diskUsage = Qt.binding(function() { return stats.diskUsage })
                leftPanel.netRx = Qt.binding(function() { return stats.netRx })
                leftPanel.netTx = Qt.binding(function() { return stats.netTx })

                dashboard.username = Qt.binding(function() { return testWindow.currentUsername })
                dashboard.avatarPath = Qt.binding(function() { return testWindow.currentAvatar })
                dashboard.kbLayout = Qt.binding(function() { return kbLayout.layout })
                dashboard.batteryCapacity = Qt.binding(function() { return battery.capacity })
                dashboard.batteryIcon = Qt.binding(function() { return battery.icon })
                dashboard.batteryColor = Qt.binding(function() { return battery.dynamicColor })

                dashboard.salaatScrollText = Qt.binding(function() { return salaat.scrollText })
                dashboard.salaatReady = Qt.binding(function() { return salaat.loaded })

                rightPanel.cpuUsage = Qt.binding(function() { return stats.cpuUsage })
                rightPanel.cpuTemp = Qt.binding(function() { return stats.cpuTemp })
                rightPanel.ramUsage = Qt.binding(function() { return stats.ramUsage })
                rightPanel.ramUsed = Qt.binding(function() { return stats.ramUsed })
                rightPanel.ramTotal = Qt.binding(function() { return stats.ramTotal })
                rightPanel.gpuUsage = Qt.binding(function() { return stats.gpuUsage })
                rightPanel.gpuTemp = Qt.binding(function() { return stats.gpuTemp })
                rightPanel.hasGpu = Qt.binding(function() { return stats.hasGpu })
                rightPanel.gpuName = Qt.binding(function() { return stats.gpuName })
                rightPanel.temperature = Qt.binding(function() { return stats.temperature })
                rightPanel.diskUsage = Qt.binding(function() { return stats.diskUsage })
                rightPanel.netRx = Qt.binding(function() { return stats.netRx })
                rightPanel.netTx = Qt.binding(function() { return stats.netTx })
                leftPanel.notifications = Qt.binding(function() { return testWindow.notifData })

                dashboard.forcePasswordFocus()
            }

            onPasswordSubmitted: password => {
                auth.currentText = password
                auth.tryUnlock()
            }
        }

        Text {
            anchors.centerIn: parent
            text: "TEST MODE - Screen unlocks on correct password"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            color: theme.color7
            visible: !testWindow.locked
        }
    }

    // X close button - always on top
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 20
        width: 36; height: 36; radius: 18
        color: closeArea.containsMouse ? theme.color1 : Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.3)
        border.color: theme.color8
        border.width: 1
        z: 1000

        Text {
            anchors.centerIn: parent
            text: "X"
            font.pixelSize: 14
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
            color: theme.foreground
        }

        MouseArea {
            id: closeArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Qt.quit()
        }
    }

    FileView {
        id: settingsFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (text().length > 0) {
                try {
                    var data = JSON.parse(text())
                    if (data.lockscreenRadius !== undefined) testWindow.barRadius = data.lockscreenRadius
                    if (data.lockscreenBorderThickness !== undefined) testWindow.popupBorderThickness = data.lockscreenBorderThickness
                    if (data.lockscreenWallpaper !== undefined) testWindow.lockscreenWallpaper = data.lockscreenWallpaper
                    if (data.lockscreenShowPassword !== undefined) testWindow.lockscreenShowPassword = data.lockscreenShowPassword
                } catch (e) {}
            }
        }
    }
}
