import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Rectangle {
    id: clockContainer

    width: 50
    // Match the workspace module's vertical breathing room.
    height: 42
    radius: root.widgetRadius
    border.color: theme.muted
    border.width: 0
    color: "transparent"

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
        color: theme.muted
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: clockHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Loader {
        id: clockTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: clockHover.containsMouse
        property real tooltipAnchorX: clockContainer.anchorX
        onLoaded: {
            item.hostWindow = clockContainer.hostWindow
            item.title = "Clock"
            item.details = "Calendar and clock details are in the Widgets drawer."
        }
        Binding { target: clockTooltip.item; property: "shown"; value: clockTooltip.tooltipShown; when: clockTooltip.item !== null }
        Binding { target: clockTooltip.item; property: "anchorX"; value: clockTooltip.tooltipAnchorX; when: clockTooltip.item !== null }
    }

    PanelWindow {
        id: clockPopup
        screen: clockContainer.hostWindow ? clockContainer.hostWindow.screen : null
        visible: clockDetailsPopup.isOpen
            && clockDetailsPopup.targetScreen === (clockContainer.hostWindow ? clockContainer.hostWindow.screen : null)
        color: "transparent"
        focusable: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { item: clockPanel }

        Rectangle {
            x: clockPanel.x + root.widgetShadowX
            y: clockPanel.y + root.widgetShadowY
            width: 360
            height: clockPanel.height
            radius: root.widgetShadowRadius
            color: Qt.rgba(0, 0, 0, root.widgetShadowEnabled ? root.widgetShadowOpacity : 0)
        }

        Rectangle {
            id: clockPanel
            x: Math.max(0, Math.min(root.clockPopupX >= 0 ? root.clockPopupX : 0, Math.max(0, parent.width - width)))
            y: Math.max(0, Math.min(
                root.clockPopupY >= 0
                    ? root.clockPopupY
                    : (root.barPosition === "top" ? 70 : Math.max(0, parent.height - height - 70)),
                Math.max(0, parent.height - height)
            ))
            width: 360
            height: 170
            radius: root.widgetRadius
            color: theme.background
            opacity: root.widgetOpacity
            border.color: theme.color2
            border.width: root.widgetBorderThickness

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 42
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

            MouseArea {
                anchors.fill: parent
                cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: clockPanel
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: Math.max(0, clockPopup.width - clockPanel.width)
                drag.minimumY: 0
                drag.maximumY: Math.max(0, clockPopup.height - clockPanel.height)
                onReleased: {
                    root.clockPopupX = clockPanel.x
                    root.clockPopupY = clockPanel.y
                    root.saveSettings()
                }
            }

            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 7
                anchors.leftMargin: 12
                anchors.rightMargin: 9
                z: 2

                Text {
                    text: "Clock Details"
                    color: theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: root.widgetRadius
                    color: clockCloseHover.containsMouse
                        ? theme.color1
                        : Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.08)
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: clockCloseHover.containsMouse ? theme.background : theme.muted
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: clockCloseHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clockDetailsPopup.close()
                    }
                }
            }
        }
    }
}
