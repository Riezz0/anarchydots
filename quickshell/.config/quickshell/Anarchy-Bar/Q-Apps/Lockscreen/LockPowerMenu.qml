import QtQuick

Rectangle {
    id: lockPowerMenu

    property bool showMenu: false

    signal suspend()
    signal reboot()
    signal powerOff()
    signal cancel()

    width: 280
    height: showMenu ? 180 : 44
    radius: rootLock.barRadius
    color: Qt.rgba(theme.color1.r, theme.color1.g, theme.color1.b, 0.15)
    border.color: Qt.rgba(theme.color1.r, theme.color1.g, theme.color1.b, 0.25)
    border.width: rootLock.popupBorderThickness

    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // Collapsed state - just the power icon
    Rectangle {
        id: powerBtn
        width: 32; height: 32; radius: 16
        anchors.centerIn: parent
        color: powerBtnMouse.containsMouse ? Qt.rgba(theme.color1.r, theme.color1.g, theme.color1.b, 0.3) : Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.3)
        visible: !lockPowerMenu.showMenu

        Text {
            anchors.centerIn: parent
            text: "󰐥"
            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
            color: theme.color1
        }

        MouseArea {
            id: powerBtnMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: lockPowerMenu.showMenu = true
        }
    }

    // Expanded state
    Item {
        anchors.fill: parent
        anchors.margins: 12
        visible: lockPowerMenu.showMenu

        Column {
            anchors.fill: parent
            spacing: 8

            Text {
                text: "Power"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: theme.foreground
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: 72; height: 52; radius: rootLock.barRadius
                    color: suspMouse.containsMouse ? Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.3) : Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.12)
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "󰤄"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color5; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Suspend"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.color7; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    MouseArea { id: suspMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: lockPowerMenu.suspend() }
                }

                Rectangle {
                    width: 72; height: 52; radius: rootLock.barRadius
                    color: rebootMouse.containsMouse ? Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.3) : Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.12)
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "󰑐"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color4; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Reboot"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.color7; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    MouseArea { id: rebootMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: lockPowerMenu.reboot() }
                }

                Rectangle {
                    width: 72; height: 52; radius: rootLock.barRadius
                    color: offMouse.containsMouse ? Qt.rgba(theme.color1.r, theme.color1.g, theme.color1.b, 0.3) : Qt.rgba(theme.color1.r, theme.color1.g, theme.color1.b, 0.12)
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "󰐥"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color1; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Power Off"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.color7; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    MouseArea { id: offMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: lockPowerMenu.powerOff() }
                }
            }

            Rectangle {
                width: 60; height: 22; radius: rootLock.barRadius
                color: cancelMouse.containsMouse ? Qt.rgba(theme.color7.r, theme.color7.g, theme.color7.b, 0.2) : Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.3)
                anchors.horizontalCenter: parent.horizontalCenter
                Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: theme.color7 }
                MouseArea { id: cancelMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { lockPowerMenu.showMenu = false; lockPowerMenu.cancel() } }
            }
        }
    }
}
