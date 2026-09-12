import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        screen: modelData
        required property var modelData
        property bool qAppsOpen: false
        visible: !powerMenu.isOpen && !keybindsPopup.isOpen && root.isMonitorEnabled(modelData)

        anchors {
            top: root.barPosition === "top"
            bottom: root.barPosition === "bottom"
            left: true
            right: true
        }

        implicitHeight: 60
        exclusiveZone: 60
        exclusionMode: ExclusionMode.Normal
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top

        margins {
            left: 10
            right: 10
            top: root.barPosition === "top" ? 5 : 0
            bottom: root.barPosition === "bottom" ? 5 : 0
        }

        Rectangle {
            anchors.fill: parent
            color: theme.background
            radius: root.barRadius
            opacity: root.barOpacity
            border.color: theme.color2
            border.width: root.barBorderThickness
        }

        Item {
            anchors.fill: parent

            Row {
                id: rightModules
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                spacing: 10

                ArchLogo {
                    height: 42
                    width: 42
                }

                Workspaces {}

                Volume {}

                MouseBattery {}

                Bluetooth {}
            }

            // Center: Salaat marquee
            Rectangle {
                id: salaatMarquee
                anchors.centerIn: parent
                width: Math.min(180, parent.width / 4)
                height: 42
                radius: root.barRadius
                color: salaatHover.containsMouse ? Qt.darker(theme.background, 1.25) : "transparent"
                clip: true

                property real scrollOffset: 0
                property bool needsScroll: false

                Text {
                    id: measureText
                    visible: false
                    text: salaat.loaded ? salaat.scrollText : ""
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    onImplicitWidthChanged: {
                        salaatMarquee.needsScroll = implicitWidth > salaatMarquee.width
                        salaatMarquee.scrollOffset = 0
                        if (salaatMarquee.needsScroll) scrollTimer.start()
                        else scrollTimer.stop()
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !salaatMarquee.needsScroll
                    text: salaat.loaded ? salaat.scrollText.substring(0, 30) : "Loading..."
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                    color: theme.muted
                }

                Item {
                    anchors.fill: parent
                    visible: salaatMarquee.needsScroll
                    clip: true

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: -salaatMarquee.scrollOffset
                        spacing: 0

                        Repeater {
                            model: 2
                            Text {
                                text: salaat.scrollText
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                                color: theme.muted
                            }
                        }
                    }
                }

                Timer {
                    id: scrollTimer
                    interval: 30
                    repeat: true
                    running: false
                    onTriggered: {
                        if (salaatMarquee.needsScroll) {
                            salaatMarquee.scrollOffset += 1
                            if (salaatMarquee.scrollOffset >= measureText.implicitWidth)
                                salaatMarquee.scrollOffset = 0
                        }
                    }
                }

                MouseArea {
                    id: salaatHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: salaatPopup.isOpen ? salaatPopup.close() : salaatPopup.open()
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 10

                InfoWidget {
                    id: infoWidget
                    onQAppsRequested: bar.qAppsOpen = true
                }

                SystemTray {
                    id: systemTray
                    trayWindow: bar
                    menuX: bar.width - rightModules.width + systemTray.x
                }

                Rectangle {
                    implicitWidth: 42; implicitHeight: 42
                    radius: root.barRadius
                    color: "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: notifs.notifIcon()
                            font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font"
                            color: notifs.notifColor()
                        }

                        Text {
                            text: notifs.trackedCount > 0 ? notifs.trackedCount.toString() : ""
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: true
                            color: theme.color1
                            visible: notifs.trackedCount > 0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: false
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (notificationsPopup.isOpen) notificationsPopup.close()
                            else notificationsPopup.open()
                        }
                    }
                }

                Rectangle {
                    implicitWidth: updatesRow.implicitWidth + 20
                    implicitHeight: 42
                    radius: root.barRadius
                    border.color: theme.muted
                    border.width: root.moduleBorderThickness
                    color: updatesBtnHover.containsMouse ? theme.color3 : "transparent"

                    property bool hovered: false

                    Row {
                        id: updatesRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: updates.updateIcon()
                            font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font"
                            color: updatesBtnHover.containsMouse ? theme.background : updates.updateColor()
                        }

                        Text {
                            text: String(updates.updateCount)
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            font.bold: updates.updatesAvailable
                            color: updatesBtnHover.containsMouse ? theme.background : theme.muted
                            visible: updates.updateCount > 0
                        }
                    }

                    MouseArea {
                        id: updatesBtnHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: updatesPopup.open()
                    }
                }

                Clock {
                    hostWindow: bar
                    anchorX: rightModules.x + x
                }

                PowerButton {
                    screen: bar.screen
                }
            }
        }

        PanelWindow {
            id: qAppsDrawer
            screen: modelData
            visible: bar.qAppsOpen
            focusable: bar.qAppsOpen
            anchors {
                top: root.barPosition === "top"
                bottom: root.barPosition === "bottom"
                right: true
            }
            margins {
                top: root.barPosition === "top" ? 70 : 0
                bottom: root.barPosition === "bottom" ? 70 : 0
                right: 10
            }
            implicitWidth: 320
            implicitHeight: 190
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: bar.qAppsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            property bool playerHover: false
            property bool closeHover: false

            Process {
                id: qPlayerLaunch
                running: false
                command: ["bash", "-lc", "qs -p ~/.config/quickshell/Anarchy-Bar/Q-Apps/Q-Player"]
            }

            Rectangle {
                x: 5
                y: 5
                width: parent.width
                height: parent.height
                radius: root.widgetShadowRadius
                color: Qt.rgba(0, 0, 0, root.widgetShadowOpacity * 0.7)
            }

            Rectangle {
                anchors.fill: parent
                radius: root.widgetRadius
                clip: true
                opacity: root.widgetOpacity
                border.color: theme.color4
                border.width: root.widgetBorderThickness
                gradient: Gradient {
                    GradientStop { position: 0.0; color: theme.background }
                    GradientStop { position: 1.0; color: Qt.darker(theme.background, 1.18) }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: "Q-Apps Launcher"
                            color: theme.color4
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: root.widgetRadius
                            color: qAppsDrawer.closeHover ? theme.color1 : Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.08)
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: qAppsDrawer.closeHover = true
                                onExited: qAppsDrawer.closeHover = false
                                onClicked: bar.qAppsOpen = false
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "x"
                                color: qAppsDrawer.closeHover ? theme.background : theme.muted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: root.widgetRadius
                        color: bar.qAppsOpen && qAppsDrawer.playerHover
                            ? Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.24)
                            : Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.06)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 11

                            Rectangle {
                                Layout.preferredWidth: 46
                                Layout.preferredHeight: 46
                                radius: root.widgetRadius
                                color: theme.color4
                                Text {
                                    anchors.centerIn: parent
                                    text: "\u{F008}"
                                    color: theme.background
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 25
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: "Q-PLAYER"
                                    color: theme.foreground
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                Text {
                                    text: "Audio and video"
                                    color: theme.muted
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                }
                            }
                            Text {
                                text: ">"
                                color: theme.color4
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: qAppsDrawer.playerHover = true
                            onExited: qAppsDrawer.playerHover = false
                            onClicked: {
                                qPlayerLaunch.running = false
                                qPlayerLaunch.running = true
                                bar.qAppsOpen = false
                            }
                        }
                    }
                }
            }
        }
    }
}
