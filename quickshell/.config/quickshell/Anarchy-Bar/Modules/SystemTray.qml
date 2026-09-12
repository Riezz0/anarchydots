import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: tray

    implicitHeight: 42
    property real menuX: 0
    property var activeMenu: null
    property bool expanded: false

    implicitWidth: trayToggle.width + (expanded ? trayRow.implicitWidth + 2 : 0)

    function openMenu(item) {
        if (!item.hasMenu) return
        activeMenu = item.menu
    }

    function closeMenu() {
        activeMenu = null
    }

    Rectangle {
        id: trayToggle
        width: 26
        height: 42
        radius: root.barRadius
        color: trayToggleMouse.containsMouse ? theme.color3 : "transparent"

        Text {
            anchors.centerIn: parent
            text: tray.expanded ? "<" : ">"
            color: trayToggleMouse.containsMouse ? theme.background : theme.muted
            font.pixelSize: 18
            font.bold: true
        }

        MouseArea {
            id: trayToggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tray.expanded = !tray.expanded
        }
    }

    Row {
        id: trayRow
        x: trayToggle.width + 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        visible: tray.expanded

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayItem
                required property var modelData

                width: 32
                height: 42
                radius: root.barRadius
                color: "transparent"

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: modelData.icon
                    sourceSize.width: width
                    sourceSize.height: height
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    anchors.centerIn: parent
                    visible: trayIcon.status === Image.Error || trayIcon.source === ""
                    text: modelData.title ? modelData.title.charAt(0).toUpperCase() : "?"
                    color: theme.muted
                    font.pixelSize: 15
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onPressed: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            tray.openMenu(modelData)
                        }
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        } else if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                            modelData.activate()
                        } else if (mouse.button === Qt.LeftButton && modelData.hasMenu) {
                            tray.openMenu(modelData)
                        }
                    }
                }
            }
        }
    }

    property var trayWindow: null

    QsMenuOpener {
        id: menuOpener
        menu: tray.activeMenu
    }

    PopupWindow {
        id: trayMenu
        visible: tray.activeMenu !== null
        grabFocus: true
        color: "transparent"
        property real calculatedWidth: 250
        implicitWidth: calculatedWidth
        implicitHeight: Math.min(menuColumn.implicitHeight + 12, 420)

        function updateWidth() {
            var widest = 250
            for (var i = 0; i < menuRepeater.count; i++) {
                var entry = menuRepeater.itemAt(i)
                if (entry) widest = Math.max(widest, entry.requiredWidth)
            }
            calculatedWidth = Math.min(widest, 600)
        }

        anchor.window: tray.trayWindow
        anchor.rect.x: tray.menuX
        anchor.rect.y: root.barPosition === "top" ? tray.trayWindow.height : 0

        onVisibleChanged: {
            if (!visible && tray.activeMenu !== null)
                tray.closeMenu()
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: root.barRadius
            color: theme.background
            border.color: theme.color2
            border.width: root.moduleBorderThickness

            Flickable {
                id: menuFlick
                anchors.fill: parent
                anchors.margins: 6
                contentWidth: width
                contentHeight: menuColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: menuColumn
                    width: menuFlick.width
                    spacing: 2

                    Repeater {
                        id: menuRepeater
                        model: menuOpener.children

                        delegate: Rectangle {
                            required property var modelData
                            property real requiredWidth: modelData.isSeparator ? 0 : menuLabel.implicitWidth + 70
                            width: menuColumn.width
                            height: modelData.isSeparator ? 6 : 32
                            radius: root.barRadius
                            color: menuEntryMouse.containsMouse && !modelData.isSeparator
                                ? theme.color3 : "transparent"

                            Image {
                                id: menuIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                source: modelData.icon
                                sourceSize.width: width
                                sourceSize.height: height
                                visible: source !== ""
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.centerIn: menuIcon
                                visible: menuIcon.status === Image.Error || menuIcon.source === ""
                                text: modelData.text ? modelData.text.charAt(0).toUpperCase() : "?"
                                color: theme.muted
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                id: menuLabel
                                anchors.left: menuIcon.visible ? menuIcon.right : parent.left
                                anchors.leftMargin: menuIcon.visible ? 8 : 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.text
                                color: modelData.enabled ? theme.muted : theme.muted
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.hasChildren ? ">" : ""
                                color: theme.muted
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: menuEntryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !modelData.isSeparator && modelData.enabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.hasChildren) return
                                    modelData.triggered()
                                    tray.closeMenu()
                                }
                            }

                            Component.onCompleted: trayMenu.updateWidth()
                            Component.onDestruction: trayMenu.updateWidth()
                        }

                        onCountChanged: trayMenu.updateWidth()
                    }
                }
            }
        }
    }
}
