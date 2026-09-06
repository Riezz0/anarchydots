import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: avatarRoot

    property string username: ""
    property string avatarPath: ""

    width: 100
    height: 100

    Rectangle {
        id: avatarBg
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.3)
        border.color: theme.color7
        border.width: rootLock.popupBorderThickness

        Image {
            id: avatarImg
            anchors.fill: parent
            source: avatarRoot.avatarPath
            fillMode: Image.PreserveAspectCrop
            visible: false
            sourceSize: Qt.size(200, 200)
        }

        OpacityMask {
            anchors.fill: parent
            source: avatarImg
            maskSource: Rectangle {
                width: avatarRoot.width
                height: avatarRoot.height
                radius: width / 2
            }
        }

        Text {
            visible: avatarImg.status !== Image.Ready
            anchors.centerIn: parent
            text: "󰀑"
            font.pixelSize: 48
            font.family: "JetBrainsMono Nerd Font"
            color: theme.foreground
        }
    }
}
