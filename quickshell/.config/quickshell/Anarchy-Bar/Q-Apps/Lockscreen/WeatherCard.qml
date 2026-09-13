import QtQuick

Rectangle {
    id: weatherCard

    property string city: ""
    property real temp: 0
    property real feelsLike: 0
    property string condition: ""
    property string icon: ""

    width: parent ? parent.width : 280
    height: 130
    radius: rootLock.barRadius
    color: theme.background
    border.color: theme.color4
    border.width: rootLock.popupBorderThickness

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Row {
            spacing: 8
            Text {
                text: weatherCard.icon
                font.pixelSize: 36
                font.family: "JetBrainsMono Nerd Font"
                color: theme.color4
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                text: weatherCard.city
                font.pixelSize: 16
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.foreground
                }
                Text {
                    text: weatherCard.condition
                    font.pixelSize: 11
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.color7
                }
            }
        }

        Row {
            spacing: 12
            Text {
                text: Math.round(weatherCard.temp) + "°C"
                font.pixelSize: 36
                font.bold: true
                font.family: "JetBrainsMono Nerd Font"
                color: theme.foreground
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "Feels like " + Math.round(weatherCard.feelsLike) + "°C"
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
                color: theme.color7
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
