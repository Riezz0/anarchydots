import QtQuick
import QtQuick.Layouts

Rectangle {
    id: notifBox

    property var notifications: []

    width: parent ? parent.width : 280
    height: 190
    radius: rootLock.barRadius
    color: Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.1)
    border.color: Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.2)
    border.width: rootLock.popupBorderThickness
    clip: true

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        Text {
            text: "Notifications"
            font.pixelSize: 13
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            color: theme.foreground
        }

        Text {
            visible: notifBox.notifications.length === 0
            text: "No new notifications"
            font.pixelSize: 11
            font.family: "JetBrainsMono Nerd Font"
            color: theme.color7
        }

        Flickable {
            width: parent.width
            height: parent.height - 30
            contentHeight: notifList.height
            clip: true
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.DragOverBounds

            Column {
                id: notifList
                width: parent.width
                spacing: 4

                Repeater {
                    model: notifBox.notifications.length > 0 ? notifBox.notifications.length : 0
                    delegate: Rectangle {
                        width: notifList.width
                        height: 42
                        radius: rootLock.barRadius
                        color: Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.15)
                        border.color: Qt.rgba(theme.color5.r, theme.color5.g, theme.color5.b, 0.1)
                        border.width: rootLock.popupBorderThickness

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 6

                    Rectangle {
                        width: 26; height: 26; radius: 6
                        color: Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.2)
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            anchors.centerIn: parent
                            text: "󰂚"
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            color: theme.color4
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 38
                        spacing: 2
                        Text {
                            text: notifBox.notifications[index] ? notifBox.notifications[index].summary : ""
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: theme.foreground
                            width: parent.width
                            elide: Text.ElideRight
                        }
                        Text {
                            text: notifBox.notifications[index] ? notifBox.notifications[index].body : ""
                            font.pixelSize: 10
                            font.family: "JetBrainsMono Nerd Font"
                            color: theme.color7
                            width: parent.width
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                            }
                        }
                    }
                }
            }
        }
    }
}
