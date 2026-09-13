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
    color: theme.background
    border.color: theme.color1
    border.width: rootLock.popupBorderThickness

    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    // Collapsed state - just the power icon
    Rectangle {
        id: powerBtn
        width: 32; height: 32; radius: 16
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.color8
        border.width: 1
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
                    color: theme.background
                    border.color: suspMouse.containsMouse ? theme.color7 : theme.color5
                    border.width: rootLock.popupBorderThickness
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "󰤄"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color5; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Suspend"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    MouseArea { id: suspMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: lockPowerMenu.suspend() }
                }

                Rectangle {
                    width: 72; height: 52; radius: rootLock.barRadius
                    color: theme.background
                    border.color: rebootMouse.containsMouse ? theme.color7 : theme.color4
                    border.width: rootLock.popupBorderThickness
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "󰑐"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color4; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Reboot"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    MouseArea { id: rebootMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: lockPowerMenu.reboot() }
                }

                Rectangle {
                    width: 72; height: 52; radius: rootLock.barRadius
                    color: theme.background
                    border.color: offMouse.containsMouse ? theme.color7 : theme.color1
                    border.width: rootLock.popupBorderThickness
                    Column {
                        anchors.centerIn: parent; spacing: 3
                        Text { text: "󰐥"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color1; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Power Off"; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    MouseArea { id: offMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: lockPowerMenu.powerOff() }
                }
            }

            Rectangle {
                width: 60; height: 22; radius: rootLock.barRadius
                color: theme.background
                border.color: cancelMouse.containsMouse ? theme.color7 : theme.color8
                border.width: rootLock.popupBorderThickness
                anchors.horizontalCenter: parent.horizontalCenter
                Text { anchors.centerIn: parent; text: "Cancel"; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }
                MouseArea { id: cancelMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { lockPowerMenu.showMenu = false; lockPowerMenu.cancel() } }
            }
        }
    }
}
