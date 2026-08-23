import QtQuick
import Quickshell

Rectangle {
    id: logoContainer

    width: 40
    height: 40
    radius: root.barRadius
    color: logoHover.containsMouse ? theme.color2 : "transparent"

    Text {
        anchors.centerIn: parent
        text: "\u{F08C7}"
        font.pixelSize: 30
        font.family: "JetBrainsMono Nerd Font"
        color: logoHover.containsMouse ? theme.background : theme.color2
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: logoHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: settingsPopup.isOpen ? settingsPopup.close() : settingsPopup.open()
    }
}
