import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: centerPanel

    property string username: ""
    property string avatarPath: ""
    property int batteryCapacity: 0
    property string batteryIcon: ""
    property color batteryColor: theme.color2
    property string kbLayout: "US"

    signal passwordSubmitted(string password)

    function forcePasswordFocus() { pwdInput.textInput.forceActiveFocus() }

    spacing: 14
    width: 380

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 260
        Layout.preferredHeight: 100
        radius: rootLock.barRadius
        color: Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.85)
        border.color: theme.color5
        border.width: rootLock.popupBorderThickness

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                id: timeText
                text: {
                    var d = new Date()
                    return (d.getHours() < 10 ? "0" : "") + d.getHours() + ":" + (d.getMinutes() < 10 ? "0" : "") + d.getMinutes()
                }
                font.pixelSize: 52
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
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                color: theme.color7
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    UserAvatar {
        Layout.alignment: Qt.AlignHCenter
        width: 100; height: 100
        username: centerPanel.username
        avatarPath: centerPanel.avatarPath
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: centerPanel.username
        font.pixelSize: 18
        font.family: "JetBrainsMono Nerd Font"
        color: theme.foreground
    }

    Item {
        Layout.fillWidth: true
        height: 48

        PasswordInput {
            id: pwdInput
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            onAccepted: password => centerPanel.passwordSubmitted(password)
        }
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        Rectangle {
            width: 44; height: 22; radius: rootLock.barRadius / 2
            color: theme.background
            border.color: theme.color8
            border.width: rootLock.popupBorderThickness
            Text { anchors.centerIn: parent; text: centerPanel.kbLayout; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.foreground }
        }

        Rectangle {
            width: 56; height: 22; radius: rootLock.barRadius / 2
            color: theme.background
            border.color: theme.color8
            border.width: rootLock.popupBorderThickness
            visible: centerPanel.batteryCapacity > 0
            Row {
                anchors.centerIn: parent; spacing: 3
                Text { text: centerPanel.batteryIcon; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: centerPanel.batteryColor }
                Text { text: centerPanel.batteryCapacity + "%"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.color7 }
            }
        }
    }
}
