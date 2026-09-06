import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: rightPanel

    property real cpuUsage: 0
    property real cpuTemp: 0
    property real ramUsage: 0
    property string ramUsed: ""
    property string ramTotal: ""
    property real gpuUsage: 0
    property real gpuTemp: 0
    property bool hasGpu: false
    property string gpuName: ""
    property real temperature: 0
    property string diskUsage: ""
    property string netRx: ""
    property string netTx: ""

    spacing: 0
    width: 340

    // Circular meters column - right side
    Column {
        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
        Layout.bottomMargin: 20
        spacing: 16

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

    // Disk card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.bottomMargin: 36
        radius: rootLock.barRadius
        color: Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.2)
        border.color: Qt.rgba(theme.color7.r, theme.color7.g, theme.color7.b, 0.12)
        border.width: rootLock.popupBorderThickness

        Row {
            anchors.centerIn: parent
            spacing: 10
            Text { text: "󰋊"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: theme.color6; anchors.verticalCenter: parent.verticalCenter }
            Text { text: rightPanel.diskUsage || "N/A"; font.pixelSize: 15; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // Network cards
    Row {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        spacing: 10

        Rectangle {
            width: (parent.width - 8) / 2
            height: parent.height
            radius: rootLock.barRadius
            color: Qt.rgba(theme.color2.r, theme.color2.g, theme.color2.b, 0.12)
            border.color: Qt.rgba(theme.color2.r, theme.color2.g, theme.color2.b, 0.2)
            border.width: rootLock.popupBorderThickness

            Row {
                anchors.centerIn: parent
                spacing: 10
                Text { text: "\u{F019}"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color2; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text { text: "Download"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: theme.color2 }
                    Text { text: rightPanel.netRx || "0 B/s"; font.pixelSize: 14; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }
                }
            }
        }

        Rectangle {
            width: (parent.width - 10) / 2
            height: parent.height
            radius: rootLock.barRadius
            color: Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.12)
            border.color: Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.2)
            border.width: rootLock.popupBorderThickness

            Row {
                anchors.centerIn: parent
                spacing: 10
                Text { text: "\u{F093}"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color4; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text { text: "Upload"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: theme.color4 }
                    Text { text: rightPanel.netTx || "0 B/s"; font.pixelSize: 14; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }
                }
            }
        }
    }
}
