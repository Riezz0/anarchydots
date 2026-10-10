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
        visible: !powerMenu.isOpen && !keybindsPopup.isOpen && !root.themeSwitcherOpen && root.isMonitorEnabled(modelData)

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
                     hostWindow: bar
                     anchorX: rightModules.x + x + width / 2
                 }

                  Workspaces {
                      hostWindow: bar
                      anchorX: rightModules.x + x + width / 2
                  }

                  Volume {
                     hostWindow: bar
                     anchorX: rightModules.x + x + width / 2
                 }

                 MouseBattery {
                     hostWindow: bar
                     anchorX: rightModules.x + x + width / 2
                 }

                 Bluetooth {
                     hostWindow: bar
                     anchorX: rightModules.x + x + width / 2
                 }

                 Loader {
                     id: scratchpadLoader
                     source: "ScratchpadIndicators.qml"
                     property real scratchpadAnchorX: rightModules.x + x + width / 2
                     height: 42
                     anchors.verticalCenter: parent.verticalCenter
                     onLoaded: {
                         item.hostWindow = bar
                     }
                     Binding { target: scratchpadLoader.item; property: "anchorX"; value: scratchpadLoader.scratchpadAnchorX; when: scratchpadLoader.item !== null }
                 }
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

                Loader {
                    id: salaatTooltip
                    source: "BarTooltip.qml"
                    property bool tooltipShown: salaatHover.containsMouse
                    property real tooltipAnchorX: salaatMarquee.x + salaatMarquee.width / 2
                    onLoaded: {
                        item.hostWindow = bar
                        item.title = "Prayer Times"
                        item.details = "LEFT CLICK  Open prayer details"
                    }
                    Binding { target: salaatTooltip.item; property: "shown"; value: salaatTooltip.tooltipShown; when: salaatTooltip.item !== null }
                    Binding { target: salaatTooltip.item; property: "anchorX"; value: salaatTooltip.tooltipAnchorX; when: salaatTooltip.item !== null }
                }
            }

            Row {
                id: statusModules
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 10

                  KeyboardLayout {
                      hostWindow: bar
                      anchorX: statusModules.x + x + width / 2
                  }

                  WidgetsButton {
                      hostWindow: bar
                      anchorX: statusModules.x + x + width / 2
                  }

                  Rectangle {
                     id: notifButton
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
                         id: notifHover
                         anchors.fill: parent
                         hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (notificationsPopup.isOpen) notificationsPopup.close()
                            else notificationsPopup.open()
                         }
                     }

                     Loader {
                         id: notificationTooltip
                         source: "BarTooltip.qml"
                         property bool tooltipShown: notifHover.containsMouse
                         property real tooltipAnchorX: statusModules.x + notifButton.x + notifButton.width / 2
                         onLoaded: {
                             item.hostWindow = bar
                             item.title = "Notifications"
                             item.details = "LEFT CLICK  Open notifications"
                         }
                         Binding { target: notificationTooltip.item; property: "shown"; value: notificationTooltip.tooltipShown; when: notificationTooltip.item !== null }
                         Binding { target: notificationTooltip.item; property: "anchorX"; value: notificationTooltip.tooltipAnchorX; when: notificationTooltip.item !== null }
                     }
                 }

                 Rectangle {
                     id: updatesButton
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

                     Loader {
                         id: updatesTooltip
                         source: "BarTooltip.qml"
                         property bool tooltipShown: updatesBtnHover.containsMouse
                         property real tooltipAnchorX: statusModules.x + updatesButton.x + updatesButton.width / 2
                         onLoaded: {
                             item.hostWindow = bar
                             item.title = "System Updates"
                             item.details = "LEFT CLICK  Open updates\nAutomatically checks periodically"
                         }
                         Binding { target: updatesTooltip.item; property: "shown"; value: updatesTooltip.tooltipShown; when: updatesTooltip.item !== null }
                         Binding { target: updatesTooltip.item; property: "anchorX"; value: updatesTooltip.tooltipAnchorX; when: updatesTooltip.item !== null }
                     }
                 }

                 Clock {
                     hostWindow: bar
                     anchorX: parent.x + x + width / 2
                 }

                 PowerButton {
                     screen: bar.screen
                     hostWindow: bar
                     anchorX: parent.x + x + width / 2
                 }
            }
        }

    }
}
