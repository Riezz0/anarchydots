import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: settingsWindow

    visible: settingsPopup.isOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    focusable: settingsPopup.isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: settingsPopup.isOpen
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    property bool barExpanded: false

    MouseArea {
        anchors.fill: parent
        onClicked: settingsPopup.close()
    }

    Rectangle {
        id: settingsPanel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        width: 380
        height: Math.min(settingsOuter.implicitHeight + 32, parent.height - 20)
                radius: root.barRadius
                color: theme.background
                opacity: settingsPopup.isOpen ? 0.95 : 0
                clip: true
        border.color: theme.muted
        border.width: root.moduleBorderThickness

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: settingsOuter
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰒓"
                    font.pixelSize: 20
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.color5
                }

                Text {
                    text: "Settings"
                    font.pixelSize: 16
                    font.bold: true
                    color: theme.foreground
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 24
                    height: 24
                    radius: root.barRadius
                    color: closeArea.containsMouse ? Qt.darker(theme.muted, 1.3) : theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 12
                        color: theme.foreground
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsPopup.close()
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.muted
                opacity: 0.4
                Layout.topMargin: 12
                Layout.bottomMargin: 12
            }

            // Bar Settings Category
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 4
                color: barHover.containsMouse ? Qt.darker(theme.background, 1.2) : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: settingsWindow.barExpanded ? "▼" : "▶"
                        font.pixelSize: 10
                        color: theme.color5
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "󰏘"
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                        color: theme.color5
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "Bar Settings"
                        font.pixelSize: 13
                        font.bold: true
                        color: theme.color5
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: barHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWindow.barExpanded = !settingsWindow.barExpanded
                }
            }

            // Bar Settings Content
            ColumnLayout {
                Layout.fillWidth: true
                visible: settingsWindow.barExpanded
                spacing: 16
                Layout.topMargin: 8

                // Bar Radius
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Bar Radius"
                            font.pixelSize: 13
                            color: theme.foreground
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.barRadius.toString()
                            font.pixelSize: 12
                            color: theme.muted
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "0"
                            font.pixelSize: 10
                            color: theme.muted
                        }

                                        Slider {
                                            id: radiusSlider
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 50
                                            stepSize: 1
                            value: root.barRadius
                            onMoved: root.barRadius = Math.round(value)

                            background: Rectangle {
                                x: radiusSlider.leftPadding
                                y: radiusSlider.topPadding + radiusSlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: radiusSlider.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: Qt.darker(theme.muted, 1.2)

                                Rectangle {
                                    width: radiusSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: theme.color5
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: radiusSlider.leftPadding + radiusSlider.visualPosition * (radiusSlider.availableWidth - width)
                                y: radiusSlider.topPadding + radiusSlider.availableHeight / 2 - height / 2
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: radiusSlider.pressed ? Qt.lighter(theme.color5, 1.2) : theme.color5
                                border.color: theme.background
                                border.width: 2
                            }
                        }

                                        Text {
                                            text: "50"
                                            font.pixelSize: 10
                                            color: theme.muted
                                        }
                    }
                }

                // Bar Opacity
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Bar Opacity"
                            font.pixelSize: 13
                            color: theme.foreground
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: Math.round(root.barOpacity * 100) + "%"
                            font.pixelSize: 12
                            color: theme.muted
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "0"
                            font.pixelSize: 10
                            color: theme.muted
                        }

                                        Slider {
                                            id: opacitySlider
                                            Layout.fillWidth: true
                                            from: 0.0
                                            to: 1.0
                                            stepSize: 0.05
                            value: root.barOpacity
                            onMoved: root.barOpacity = Math.round(value * 100) / 100

                            background: Rectangle {
                                x: opacitySlider.leftPadding
                                y: opacitySlider.topPadding + opacitySlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: opacitySlider.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: Qt.darker(theme.muted, 1.2)

                                Rectangle {
                                    width: opacitySlider.visualPosition * parent.width
                                    height: parent.height
                                    color: theme.color5
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: opacitySlider.leftPadding + opacitySlider.visualPosition * (opacitySlider.availableWidth - width)
                                y: opacitySlider.topPadding + opacitySlider.availableHeight / 2 - height / 2
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: opacitySlider.pressed ? Qt.lighter(theme.color5, 1.2) : theme.color5
                                border.color: theme.background
                                border.width: 2
                            }
                        }

                        Text {
                            text: "100"
                            font.pixelSize: 10
                            color: theme.muted
                        }
                    }
                }

                // Bar Border Thickness
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Bar Border"
                            font.pixelSize: 13
                            color: theme.foreground
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.barBorderThickness + "px"
                            font.pixelSize: 12
                            color: theme.muted
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "0"
                            font.pixelSize: 10
                            color: theme.muted
                        }

                        Slider {
                            id: barBorderSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 4
                            stepSize: 1
                            value: root.barBorderThickness
                            onMoved: root.barBorderThickness = Math.round(value)

                            background: Rectangle {
                                x: barBorderSlider.leftPadding
                                y: barBorderSlider.topPadding + barBorderSlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: barBorderSlider.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: Qt.darker(theme.muted, 1.2)

                                Rectangle {
                                    width: barBorderSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: theme.color5
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: barBorderSlider.leftPadding + barBorderSlider.visualPosition * (barBorderSlider.availableWidth - width)
                                y: barBorderSlider.topPadding + barBorderSlider.availableHeight / 2 - height / 2
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: barBorderSlider.pressed ? Qt.lighter(theme.color5, 1.2) : theme.color5
                                border.color: theme.background
                                border.width: 2
                            }
                        }

                        Text {
                            text: "4"
                            font.pixelSize: 10
                            color: theme.muted
                        }
                    }
                }

                // Module Border Thickness
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Module Border"
                            font.pixelSize: 13
                            color: theme.foreground
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.moduleBorderThickness + "px"
                            font.pixelSize: 12
                            color: theme.muted
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "0"
                            font.pixelSize: 10
                            color: theme.muted
                        }

                        Slider {
                            id: moduleBorderSlider
                            Layout.fillWidth: true
                            from: 0
                            to: 4
                            stepSize: 1
                            value: root.moduleBorderThickness
                            onMoved: root.moduleBorderThickness = Math.round(value)

                            background: Rectangle {
                                x: moduleBorderSlider.leftPadding
                                y: moduleBorderSlider.topPadding + moduleBorderSlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: moduleBorderSlider.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: Qt.darker(theme.muted, 1.2)

                                Rectangle {
                                    width: moduleBorderSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: theme.color5
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: moduleBorderSlider.leftPadding + moduleBorderSlider.visualPosition * (moduleBorderSlider.availableWidth - width)
                                y: moduleBorderSlider.topPadding + moduleBorderSlider.availableHeight / 2 - height / 2
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: moduleBorderSlider.pressed ? Qt.lighter(theme.color5, 1.2) : theme.color5
                                border.color: theme.background
                                border.width: 2
                            }
                        }

                        Text {
                            text: "4"
                            font.pixelSize: 10
                            color: theme.muted
                        }
                    }
                }

                // Monitor Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Monitors"
                        font.pixelSize: 13
                        font.bold: true
                        color: theme.color5
                    }

                    Repeater {
                        model: Quickshell.screens

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 4
                            color: monitorHover.containsMouse ? Qt.darker(theme.background, 1.2) : "transparent"

                            property var monitor: modelData
                            property bool isEnabled: root.barMonitors.length === 0 || root.barMonitors.indexOf(monitor.name) !== -1

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 4
                                    border.color: theme.muted
                                    border.width: 1
                                    color: parent.parent.isEnabled ? theme.color5 : "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: theme.background
                                        font.pixelSize: 12
                                        font.bold: true
                                        visible: parent.parent.parent.isEnabled
                                    }
                                }

                                Text {
                                    text: monitor.name
                                    font.pixelSize: 12
                                    color: theme.foreground
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: monitorHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleMonitor(monitor)
                            }
                        }
                    }

                    Text {
                        text: root.barMonitors.length === 0 ? "All monitors" : root.barMonitors.length + " monitor(s) selected"
                        font.pixelSize: 11
                        color: theme.muted
                        Layout.topMargin: 4
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: settingsPopup.close()
}
