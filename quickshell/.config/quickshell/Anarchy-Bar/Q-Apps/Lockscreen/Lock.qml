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
    property int barRadius: 10
    property int popupBorderThickness: 2
    property var notifData: []

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
        unlockDelay.start()
    }

    Timer { id: unlockDelay; interval: 300; onTriggered: { locked = false; isUnlocking = false } }

    Connections {
        target: auth
        function onAuthSucceeded() { rootLock.unlock() }
        function onAuthFailed() { auth.cancel() }
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

            Rectangle {
                anchors.fill: parent
                color: theme.background
                opacity: 1.0
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

                onPasswordSubmitted: password => auth.startAuth(password)
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

            Rectangle {
                z: 100
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 16
                width: 36; height: 36; radius: 18
                color: closeArea.containsMouse ? Qt.rgba(theme.color7.r, theme.color7.g, theme.color7.b, 0.3) : Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.3)
                Text { anchors.centerIn: parent; text: "󰅖"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }
                MouseArea { id: closeArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: rootLock.locked = false }
            }

            Component.onCompleted: { if (isPrimary) introAnim.start() }
        }
    }
}
