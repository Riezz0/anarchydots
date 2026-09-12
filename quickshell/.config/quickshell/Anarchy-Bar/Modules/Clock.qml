import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: clockContainer

    width: 50
    // Match the workspace module's vertical breathing room.
    height: 42
    radius: root.widgetRadius
    border.color: theme.muted
    border.width: 0
    color: clockHover.containsMouse ? theme.color1 : "transparent"

    property string currentTime: Qt.formatDateTime(new Date(), "hh:mm")
    property string currentHours: Qt.formatDateTime(new Date(), "hh")
    property string currentMinutes: Qt.formatDateTime(new Date(), "mm")
    property string currentSeconds: Qt.formatDateTime(new Date(), "ss")
    property var hostWindow: null
    property real anchorX: 0

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = new Date()
            clockContainer.currentTime = Qt.formatDateTime(now, "hh:mm")
            clockContainer.currentHours = Qt.formatDateTime(now, "hh")
            clockContainer.currentMinutes = Qt.formatDateTime(now, "mm")
            clockContainer.currentSeconds = Qt.formatDateTime(now, "ss")
        }
    }

    component ClockBox: Rectangle {
        required property string value
        required property string label

        width: 86
        height: 86
        radius: root.widgetRadius
        color: theme.color0
        border.color: theme.color2
        border.width: root.widgetBorderThickness

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 5
            text: parent.value
            color: theme.foreground
            font.pixelSize: 42
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 7
            text: parent.label
            color: theme.muted
            font.pixelSize: 11
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width
        text: clockContainer.currentTime
        color: clockHover.containsMouse ? theme.background : theme.muted
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: clockHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                clockPopupOpen = !clockPopupOpen
            } else {
                calendarPopup.isOpen ? calendarPopup.close() : calendarPopup.open()
            }
        }
    }

    property bool clockPopupOpen: false

    PopupWindow {
        id: clockPopup
        visible: clockContainer.clockPopupOpen
        color: "transparent"
        implicitWidth: 360 + Math.max(root.widgetShadowX, 0) + 2
        implicitHeight: 122 + Math.max(root.widgetShadowY, 0) + 2

        anchor.window: clockContainer.hostWindow
        anchor.rect.x: 0
        anchor.rect.y: root.barPosition === "top" ? clockContainer.hostWindow.height + 10 : 0

        Rectangle {
            x: root.widgetShadowX
            y: root.widgetShadowY
            width: 360
            height: 122
            radius: root.widgetShadowRadius
            color: Qt.rgba(0, 0, 0, root.widgetShadowEnabled ? root.widgetShadowOpacity : 0)
        }

        Rectangle {
            width: 360
            height: 122
            radius: root.widgetRadius
            color: theme.background
            opacity: root.widgetOpacity
            border.color: theme.color2
            border.width: root.widgetBorderThickness

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Item {
                    width: 86
                    height: 86
                    ClockBox {
                        anchors.fill: parent
                        value: clockContainer.currentHours
                        label: "Hours"
                    }
                }

                Item {
                    width: 30
                    height: 86

                    Column {
                        anchors.top: parent.top
                        anchors.topMargin: 23
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 9

                        Repeater {
                            model: 2

                            delegate: Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: theme.foreground
                            }
                        }
                    }
                }

                Item {
                    width: 86
                    height: 86
                    ClockBox {
                        anchors.fill: parent
                        value: clockContainer.currentMinutes
                        label: "Minutes"
                    }
                }

                Item {
                    width: 30
                    height: 86

                    Column {
                        anchors.top: parent.top
                        anchors.topMargin: 23
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 9

                        Repeater {
                            model: 2

                            delegate: Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: theme.foreground
                            }
                        }
                    }
                }

                Item {
                    width: 86
                    height: 86
                    ClockBox {
                        anchors.fill: parent
                        value: clockContainer.currentSeconds
                        label: "Seconds"
                    }
                }
            }

        }
    }
}
