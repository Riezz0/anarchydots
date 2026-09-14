import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: rootLock

    property bool locked: true
    property bool isUnlocking: false
    property string currentUsername: "user"
    property string currentAvatar: ""
    property int barRadius
    property int popupBorderThickness
    property var notifData: []
    property string wallpaperPath: ""
    property string statusMessage: ""
    property color statusColor: theme.color2
    property bool showPassword: false

    Auth { id: auth }
    Battery { id: battery }
    SystemStats { id: stats }
    WeatherService { id: weather }
    KbLayout { id: kbLayout }
    Salaat { id: salaat }

    IpcHandler {
        target: "lock"
        function activate(): void { rootLock.lock() }
    }

    Process { id: powerProc; running: false }

    Process {
        id: userProc
        command: ["whoami"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var name = line.trim()
                if (name.length > 0) rootLock.currentUsername = name
            }
        }
        Component.onCompleted: running = true
    }

    Process {
        id: avatarProc
        command: ["bash", "-c", "ls ~/.face 2>/dev/null || ls /var/lib/AccountsService/icons/$(whoami) 2>/dev/null || echo ''"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var path = line.trim()
                if (path.length > 0) rootLock.currentAvatar = path
            }
        }
        Component.onCompleted: running = true
    }

    function lock() {
        if (locked) return
        isUnlocking = false
        stats.cpuUsage = 0
        stats.ramUsage = 0
        locked = true
    }

    function unlock() {
        isUnlocking = true
        rootLock.statusMessage = "Unlocked"
        rootLock.statusColor = theme.color2
        statusTimer.restart()
        unlockDelay.start()
    }

    Timer { id: unlockDelay; interval: 300; onTriggered: { locked = false; isUnlocking = false } }

    Timer {
        id: statusTimer
        interval: 1000
        onTriggered: rootLock.statusMessage = ""
    }

    Connections {
        target: auth
        function onAuthSucceeded() {
            rootLock.statusMessage = "Unlocked"
            rootLock.statusColor = theme.color2
            statusTimer.restart()
            rootLock.unlock()
        }
        function onAuthFailed() {
            rootLock.statusMessage = "Wrong password"
            rootLock.statusColor = theme.color1
            statusTimer.restart()
            dashboard.resetPassword()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: lockScreen
            required property var modelData
            screen: modelData
            visible: rootLock.locked
            property bool isPrimary: modelData === Quickshell.screens[0]

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            focusable: true
            exclusiveZone: -1

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "lockscreen"

            // Wallpaper background
            Image {
                id: wallpaperImage
                anchors.fill: parent
                source: rootLock.wallpaperPath.startsWith("file://")
                    ? rootLock.wallpaperPath
                    : (rootLock.wallpaperPath !== "" ? "file://" + rootLock.wallpaperPath : "")
                fillMode: Image.PreserveAspectCrop
                visible: rootLock.wallpaperPath !== ""
            }

            // Fallback solid color background
            Rectangle {
                anchors.fill: parent
                color: theme.background
                visible: rootLock.wallpaperPath === ""
            }

            IntroAnimation {
                id: introAnim
                z: 10
                onIntroFinished: { if (lockScreen.isPrimary) dashboard.openDashboard() }
            }

            Dashboard {
                id: dashboard
                z: 20

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

                    dashboard.username = Qt.binding(function() { return rootLock.currentUsername })
                    dashboard.avatarPath = Qt.binding(function() { return rootLock.currentAvatar })
                    dashboard.kbLayout = Qt.binding(function() { return kbLayout.layout })
                    dashboard.batteryCapacity = Qt.binding(function() { return battery.capacity })
                    dashboard.batteryIcon = Qt.binding(function() { return battery.icon })
                    dashboard.batteryColor = Qt.binding(function() { return battery.dynamicColor })

                    dashboard.salaatScrollText = Qt.binding(function() { return salaat.scrollText })
                    dashboard.salaatReady = Qt.binding(function() { return salaat.loaded })
                    dashboard.showPassword = Qt.binding(function() { return rootLock.showPassword })

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
                    leftPanel.notifications = Qt.binding(function() { return rootLock.notifData })

                    dashboard.forcePasswordFocus()
                }

                onPasswordSubmitted: password => {
                    auth.currentText = password
                    auth.tryUnlock()
                }
            }

            LockPowerMenu {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 40
                z: 25
                onSuspend: { rootLock.locked = false; powerProc.command = ["systemctl", "suspend"]; powerProc.running = true }
                onReboot: { rootLock.locked = false; powerProc.command = ["systemctl", "reboot"]; powerProc.running = true }
                onPowerOff: { rootLock.locked = false; powerProc.command = ["systemctl", "poweroff"]; powerProc.running = true }
            }

            // X close button - test mode
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 20
                width: 36; height: 36; radius: 18
                color: testCloseArea.containsMouse ? theme.color1 : Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.3)
                border.color: theme.color8
                border.width: 1
                z: 100

                Text {
                    anchors.centerIn: parent
                    text: "X"
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    color: theme.foreground
                }

                MouseArea {
                    id: testCloseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: rootLock.locked = false
                }
            }

            // Status message banner
            Rectangle {
                visible: rootLock.statusMessage !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 300
                width: statusText.width + 40
                height: 36
                radius: rootLock.barRadius
                color: rootLock.statusColor
                opacity: 0.9

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: rootLock.statusMessage
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    color: theme.background
                }

                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Component.onCompleted: { if (isPrimary) introAnim.start() }
        }
    }
}
