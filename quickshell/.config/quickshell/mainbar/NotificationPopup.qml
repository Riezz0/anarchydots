// ═══════════════════════════════════════════════════════════════════════════════
// NotificationPopup - Floating Notification Toast Overlay
// ═══════════════════════════════════════════════════════════════════════════════
// Displays floating notification toasts at the top center of the screen.
// Each notification auto-dismisses after a timeout based on urgency level.
//
// Required: notifs (Notifications module) from shell.qml
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: popupRoot

    property var toastList: []
    property int count: toastList.length

    function dismissNotif(nid) {
        notifs.dismissNotif(nid)
        popupRoot.toastList = popupRoot.toastList.filter(n => n.id !== nid)
    }

    Connections {
        target: notifs

        function onNotificationReceived(appName, summary, body, urgency, timeout, actions) {
            if (notifs.dndEnabled) return

            const notifData = {
                id:       Date.now() + Math.random(),
                appName:  appName,
                summary:  summary,
                body:     body,
                urgency:  urgency,
                actions:  actions || [],
                expireTimeout: timeout > 0 ? timeout : (urgency === 1 ? 10000 : 5000)
            }

            let arr = popupRoot.toastList.slice()
            arr.push(notifData)
            popupRoot.toastList = arr
        }
    }

    Variants {
        model: [Quickshell.screens[1]]

        PanelWindow {
            screen:  modelData
            visible: popupRoot.count > 0
            required property var modelData

            anchors { top: true; bottom: true; left: true; right: true }

            color:     "transparent"
            focusable: false

            WlrLayershell.layer: WlrLayer.Overlay

            Column {
                id:               toastColumn
                anchors.top:      parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10
                spacing:          10
                width:            500

                Repeater {
                    model: popupRoot.toastList

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width:    toastColumn.width
                        implicitHeight: toastCol.implicitHeight + 32
                        height:   implicitHeight
                        radius:   5
                        color:    theme.background
                        opacity:  0.95
                        border {
                            width: 2
                            color: modelData.urgency === 1 ? theme.color1
                                 : modelData.urgency === 0 ? Qt.darker(theme.color4, 0.7)
                                 : theme.color2
                        }

                        Timer {
                            interval: modelData.expireTimeout
                            running:  true
                            repeat:   false
                            onTriggered: popupRoot.dismissNotif(modelData.id)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    popupRoot.dismissNotif(modelData.id)
                        }

                    ColumnLayout {
                        id:    toastCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text:             modelData.appName || "Notification"
                                        color:            theme.muted
                                        font.pixelSize:   13
                                        font.bold:        true
                                        font.family:      "JetBrains Mono Nerd Font Mono"
                                        elide:            Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text:             modelData.summary
                                        color:            theme.foreground
                                        font.pixelSize:   15
                                        font.bold:        true
                                        elide:            Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    width:  8
                                    height: 8
                                    radius: 4
                                    color:  modelData.urgency === 1 ? theme.color1
                                          : modelData.urgency === 0 ? theme.color3
                                          : theme.color2
                                }
                            }

                            Text {
                                visible:          modelData.body && modelData.body.length > 0
                                text:             modelData.body || ""
                                color:            theme.muted
                                font.pixelSize:   14
                                wrapMode:         Text.Wrap
                                maximumLineCount: 3
                                elide:            Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
