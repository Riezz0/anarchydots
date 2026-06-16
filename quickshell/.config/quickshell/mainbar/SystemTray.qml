import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu

RowLayout {
    id: systrayRoot
    spacing: 2

    Repeater {
        model: SystemTray.items

        Item {
            required property var modelData
            width: 28
            height: 28

            Image {
                id: trayIcon
                anchors.centerIn: parent
                width: 20
                height: 20
                source: modelData.icon
                smooth: true
                mipmap: true
                sourceSize.width: 20
                sourceSize.height: 20

                onStatusChanged: {
                    if (status === Image.Error) {
                        source = "image://tray/" + (modelData.id || "")
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        modelData.activate()
                    } else if (mouse.button === Qt.RightButton) {
                        modelData.requestContextMenu()
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate()
                    }
                }
            }
        }
    }

    Text {
        visible: SystemTray.items.count === 0
        text: "󰖩"
        font.pixelSize: 18
        color: theme.muted
        opacity: 0.4
    }
}

