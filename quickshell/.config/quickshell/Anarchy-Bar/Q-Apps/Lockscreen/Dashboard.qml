import QtQuick

Item {
    id: dashboard

    property real revealProgress: 1
    property real wingsReveal: 1
    property real centerReveal: 1
    property bool isOpen: true

    property alias leftPanel: leftPanelInstance
    property alias rightPanel: rightPanelInstance

    property string username: rootLock.currentUsername
    property string avatarPath: rootLock.currentAvatar
    property int batteryCapacity: 0
    property string batteryIcon: ""
    property color batteryColor: theme.color2
    property string kbLayout: "US"
    property string salaatScrollText: ""
    property bool salaatReady: false

    signal passwordSubmitted(string password)

    function forcePasswordFocus() { pwdInput.forceActiveFocus() }

    Timer {
        id: focusTimer
        interval: 400
        onTriggered: dashboard.forcePasswordFocus()
    }

    anchors.fill: parent

    // Center column - weather above clock, perfectly centered
    Column {
        anchors.centerIn: parent
        spacing: 16
        opacity: dashboard.centerReveal
        visible: dashboard.revealProgress > 0

        // Clock
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Text {
                id: timeText
                text: {
                    var d = new Date()
                    return (d.getHours() < 10 ? "0" : "") + d.getHours() + ":" + (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
                }
                font.pixelSize: 64
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: theme.foreground
                anchors.horizontalCenter: parent.horizontalCenter

                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: {
                        var d = new Date()
                        timeText.text = (d.getHours() < 10 ? "0" : "") + d.getHours() + ":" + (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
                    }
                }
            }

            Text {
                text: {
                    var d = new Date()
                    var days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                    var months = ["January","February","March","April","May","June","July","August","September","October","November","December"]
                    return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
                }
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font"
                color: theme.color7
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Avatar
        UserAvatar {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 100; height: 100
            username: dashboard.username
            avatarPath: dashboard.avatarPath
        }

        // Username
        Text {
            text: dashboard.username
            font.pixelSize: 18
            font.family: "JetBrainsMono Nerd Font"
            color: theme.foreground
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Password
        Item {
            width: 320; height: 52
            anchors.horizontalCenter: parent.horizontalCenter

            PasswordInput {
                id: pwdInput
                anchors.centerIn: parent
                width: 320
                onAccepted: password => dashboard.passwordSubmitted(password)
            }
        }

        // KB + Battery pills
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Rectangle {
                width: 44; height: 22; radius: rootLock.barRadius / 2
                color: Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.5)
                Text { anchors.centerIn: parent; text: dashboard.kbLayout; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.color7 }
            }

            Rectangle {
                width: 56; height: 22; radius: rootLock.barRadius / 2
                color: Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.5)
                visible: dashboard.batteryCapacity > 0
                Row {
                    anchors.centerIn: parent; spacing: 3
                    Text { text: dashboard.batteryIcon; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: dashboard.batteryColor }
                    Text { text: dashboard.batteryCapacity + "%"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.color7 }
                }
            }
        }
    }

    // Hidden - data only
    LeftPanel {
        id: leftPanelInstance
        visible: false
        width: 0
        height: 0
    }

    // Notifications - top-left corner
    NotificationBox {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 40
        anchors.topMargin: 40
        width: 280
        opacity: dashboard.wingsReveal
        visible: dashboard.revealProgress > 0
        notifications: rootLock.notifData
    }

    // Weather - bottom-left corner
    WeatherCard {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 40
        anchors.bottomMargin: 40
        width: 280
        opacity: dashboard.wingsReveal
        visible: dashboard.revealProgress > 0
        city: leftPanel.city
        temp: leftPanel.temp
        feelsLike: leftPanel.feelsLike
        condition: leftPanel.condition
        icon: leftPanel.icon
    }

    // Hidden - data only
    RightPanel {
        id: rightPanelInstance
        visible: false
        width: 0
        height: 0
    }

    // Meters - pinned to right edge
    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 60
        spacing: 16
        opacity: dashboard.wingsReveal
        visible: dashboard.revealProgress > 0

        CircularMeter {
            anchors.horizontalCenter: parent.horizontalCenter
            label: "CPU"
            value: Math.round(rightPanel.cpuTemp) + "°"
            subText: Math.round(rightPanel.cpuUsage) + "%"
            progress: rightPanel.cpuTemp
            maxValue: 100
            meterColor: rightPanel.cpuTemp >= 80 ? theme.color1 : (rightPanel.cpuTemp >= 60 ? theme.color3 : theme.color4)
            width: 95
            height: 115
        }

        CircularMeter {
            anchors.horizontalCenter: parent.horizontalCenter
            label: "RAM"
            value: Math.round(rightPanel.ramUsage) + "%"
            subText: rightPanel.ramUsed
            progress: rightPanel.ramUsage
            maxValue: 100
            meterColor: rightPanel.ramUsage >= 80 ? theme.color1 : (rightPanel.ramUsage >= 60 ? theme.color3 : theme.color5)
            width: 95
            height: 115
        }

        CircularMeter {
            anchors.horizontalCenter: parent.horizontalCenter
            label: "GPU"
            value: rightPanel.hasGpu ? Math.round(rightPanel.gpuTemp) + "°" : "N/A"
            subText: rightPanel.hasGpu ? Math.round(rightPanel.gpuUsage) + "%" : ""
            progress: rightPanel.gpuTemp
            maxValue: 100
            meterColor: rightPanel.gpuTemp >= 80 ? theme.color1 : (rightPanel.gpuTemp >= 60 ? theme.color3 : theme.color2)
            width: 95
            height: 115
        }
    }

    // Prayer Times + Network - below center
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        spacing: 16
        opacity: dashboard.wingsReveal
        visible: dashboard.revealProgress > 0

        Rectangle {
            width: 300; height: 44
            radius: rootLock.barRadius
            color: Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.12)
            border.color: Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.2)
            border.width: rootLock.popupBorderThickness
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            Item {
                anchors.centerIn: parent
                width: 280
                height: 20
                clip: true

                Text {
                    id: scrollText
                    text: dashboard.salaatReady ? dashboard.salaatScrollText + "     " + dashboard.salaatScrollText : "Loading..."
                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.foreground
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                }

                Timer {
                    interval: 33
                    running: dashboard.salaatReady && scrollText.contentWidth > parent.width
                    repeat: true
                    onTriggered: {
                        scrollText.x -= 1
                        if (scrollText.x < -scrollText.contentWidth / 2) {
                            scrollText.x = 0
                        }
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Rectangle {
                width: 95; height: 64
                radius: rootLock.barRadius
                color: Qt.rgba(theme.color2.r, theme.color2.g, theme.color2.b, 0.12)
                border.color: Qt.rgba(theme.color2.r, theme.color2.g, theme.color2.b, 0.2)
                border.width: rootLock.popupBorderThickness

                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: "\u{F019}"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: theme.color2; anchors.verticalCenter: parent.verticalCenter }
                    Column { anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Text { text: "Down"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.color2 }
                        Text { text: rightPanel.netRx || "0 B/s"; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }
                    }
                }
            }

            Rectangle {
                width: 95; height: 64
                radius: rootLock.barRadius
                color: Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.12)
                border.color: Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.2)
                border.width: rootLock.popupBorderThickness

                Row {
                    anchors.centerIn: parent; spacing: 6
                    Text { text: "\u{F093}"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: theme.color4; anchors.verticalCenter: parent.verticalCenter }
                    Column { anchors.verticalCenter: parent.verticalCenter; spacing: 2
                        Text { text: "Up"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.color4 }
                        Text { text: rightPanel.netTx || "0 B/s"; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: openAnim
        running: false
        NumberAnimation { target: dashboard; property: "revealProgress"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: dashboard; property: "centerReveal"; from: 0; to: 1; duration: 220; easing.type: Easing.OutBack }
        }
        PauseAnimation { duration: 50 }
        NumberAnimation { target: dashboard; property: "wingsReveal"; from: 0; to: 1; duration: 250; easing.type: Easing.OutBack }
    }

    SequentialAnimation {
        id: closeAnim
        running: false
        NumberAnimation { target: dashboard; property: "wingsReveal"; from: 1; to: 0; duration: 120; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: dashboard; property: "centerReveal"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: dashboard; property: "revealProgress"; from: 1; to: 0; duration: 200; easing.type: Easing.InCubic }
        }
    }

    function openDashboard() {
        isOpen = true
        closeAnim.stop()
        openAnim.start()
        focusTimer.start()
    }

    function closeDashboard() {
        isOpen = false
        openAnim.stop()
        closeAnim.start()
    }
}
