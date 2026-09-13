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
        color: theme.background
        border.color: theme.color4
        border.width: rootLock.popupBorderThickness

        Image {
            id: avatarImg
            anchors.centerIn: parent
            width: parent.width - 4
            height: parent.height - 4
            source: avatarRoot.avatarPath
            fillMode: Image.PreserveAspectCrop
            visible: false
            sourceSize: Qt.size(200, 200)
        }

        OpacityMask {
            anchors.fill: avatarImg
            source: avatarImg
            maskSource: Rectangle {
                width: avatarImg.width
                height: avatarImg.height
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
