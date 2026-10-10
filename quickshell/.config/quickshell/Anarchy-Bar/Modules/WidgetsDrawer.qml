import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: drawerWindow

    screen: widgetsDrawer.targetScreen
    visible: widgetsDrawer.isOpen
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: outsideArea }

    property var widgetApps: [
        {
            name: "Calendar",
            description: "Open the calendar",
            icon: "\u{F073}",
            kind: "calendar"
        },
        {
            name: "Clock",
            description: "Digital clock details",
            icon: "\u{F017}",
            kind: "clock"
        },
        {
            name: "Temperature",
            description: "Live CPU and GPU temperatures",
            icon: "\u{F2DB}",
            kind: "system-widgets"
        }
    ]

    MouseArea {
        id: outsideArea
        anchors.fill: parent
        onClicked: widgetsDrawer.close()
    }

    Rectangle {
        id: drawerShadow
        x: drawerPanel.x + root.widgetShadowX
        y: drawerPanel.y + root.widgetShadowY
        width: drawerPanel.width
        height: drawerPanel.height
        radius: root.widgetShadowRadius
        color: Qt.rgba(0, 0, 0, root.widgetShadowEnabled ? root.widgetShadowOpacity : 0)
    }

    Rectangle {
        id: drawerPanel
        x: Math.max(8, parent.width - width - 8)
        y: 8
        width: 340
        height: Math.max(240, parent.height - 16)
        radius: root.widgetRadius
        color: theme.background
        opacity: root.widgetOpacity
        border.color: theme.color4
        border.width: root.widgetBorderThickness

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Widgets"
                    color: theme.foreground
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: root.widgetRadius
                    color: closeHover.containsMouse ? theme.color1 : Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeHover.containsMouse ? theme.background : theme.muted
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: widgetsDrawer.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: theme.muted
                opacity: 0.4
            }

            ListView {
                id: widgetList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: drawerWindow.widgetApps

                delegate: Rectangle {
                    id: widgetEntry
                    required property var modelData
                    property bool appOpen: modelData.kind === "calendar"
                        ? calendarPopup.isOpen
                        : (modelData.kind === "clock"
                            ? clockDetailsPopup.isOpen
                            : modelData.kind === "system-widgets" && systemWidgetsPopup.isOpen)
                    width: widgetList.width
                    height: 76
                    radius: root.widgetRadius
                    color: widgetHover.containsMouse || appOpen
                        ? Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.16)
                        : Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.04)
                    border.color: appOpen ? theme.color4 : Qt.rgba(theme.muted.r, theme.muted.g, theme.muted.b, 0.5)
                    border.width: root.widgetBorderThickness

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            radius: root.widgetRadius
                            color: theme.color4

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: theme.background
                                font.pixelSize: 21
                                font.family: "JetBrainsMono Nerd Font"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: modelData.name
                                color: theme.foreground
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Text {
                                text: modelData.description
                                color: theme.muted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            text: widgetEntry.appOpen ? "Open" : "›"
                            color: widgetEntry.appOpen ? theme.color2 : theme.color4
                            font.pixelSize: widgetEntry.appOpen ? 10 : 19
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: widgetHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.kind === "calendar") {
                                if (calendarPopup.isOpen) calendarPopup.close()
                                else calendarPopup.open(widgetsDrawer.targetScreen)
                            } else if (modelData.kind === "clock") {
                                if (clockDetailsPopup.isOpen) clockDetailsPopup.close()
                                else clockDetailsPopup.open(widgetsDrawer.targetScreen)
                            } else if (modelData.kind === "system-widgets") {
                                if (systemWidgetsPopup.isOpen) systemWidgetsPopup.close()
                                else systemWidgetsPopup.open(widgetsDrawer.targetScreen)
                            } else if (modelData.path && !widgetEntry.appOpen) {
                                Quickshell.execDetached([
                                    "qs", "-p",
                                    StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "")
                                        + "/.config/quickshell/Anarchy-Bar/Q-Apps/" + modelData.path
                                ])
                            }
                            widgetsDrawer.close()
                        }
                    }
                }
            }
        }
    }
}
