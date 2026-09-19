import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: tray

    property var hostWindow: null
    property real anchorX: 0
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

    function resolveMenuIcon(icon) {
        var value = String(icon || "")
        if (value === "" || value.indexOf("://") !== -1 || value.indexOf("/") !== -1)
            return value
        return Quickshell.iconPath(value, true)
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

    Loader {
        id: trayTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: trayToggleMouse.containsMouse
        property real tooltipAnchorX: tray.anchorX
        onLoaded: {
            item.hostWindow = tray.hostWindow
            item.title = "System Tray"
            item.details = "LEFT CLICK  Show / hide tray icons"
        }
        Binding { target: trayTooltip.item; property: "shown"; value: trayTooltip.tooltipShown; when: trayTooltip.item !== null }
        Binding { target: trayTooltip.item; property: "anchorX"; value: trayTooltip.tooltipAnchorX; when: trayTooltip.item !== null }
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
                                id: menuEntry
                                required property var modelData
                                property string resolvedIcon: tray.resolveMenuIcon(modelData.icon)
                                property real requiredWidth: modelData.isSeparator ? 0 : menuLabel.implicitWidth + 30
                            width: menuColumn.width
                            height: modelData.isSeparator ? 6 : 32
                            radius: root.barRadius
                            color: menuEntryMouse.containsMouse && !modelData.isSeparator
                                ? theme.color3 : "transparent"

                                IconImage {
                                id: menuIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                source: resolvedIcon
                                asynchronous: true
                                mipmap: true
                                    visible: false
                                }

                                Process {
                                    id: menuIconLookup
                                    running: modelData.icon !== ""
                                    command: ["bash", "-c",
                                        "icon=\"$1\"; case \"$icon\" in *://*|/*) exit 0;; esac; " +
                                        "for root in \"$HOME/.local/share/icons\" \"$HOME/.icons\" /usr/local/share/icons /usr/share/icons; do " +
                                        "[ -d \"$root\" ] || continue; " +
                                        "file=$(find -L \"$root\" -type f \\\( -iname \"$icon.svg\" -o -iname \"$icon.png\" -o -iname \"$icon.xpm\" \\\) -print -quit 2>/dev/null); " +
                                        "[ -n \"$file\" ] && printf 'file://%s' \"$file\" && exit 0; done",
                                        "icon", modelData.icon]
                                    stdout: StdioCollector {
                                        onStreamFinished: {
                                            var fallback = this.text.trim()
                                            if (fallback !== "") menuEntry.resolvedIcon = fallback
                                        }
                                    }
                                }

                            Text {
                                anchors.centerIn: menuIcon
                                visible: false
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
                                color: menuEntryMouse.containsMouse ? theme.background : theme.muted
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.hasChildren ? ">" : ""
                                color: menuEntryMouse.containsMouse ? theme.background : theme.muted
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: menuEntryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !modelData.isSeparator && modelData.enabled
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.hasChildren) {
                                        submenuAnchor.open()
                                        return
                                    }
                                    modelData.triggered()
                                    tray.closeMenu()
                                }
                            }

                            QsMenuAnchor {
                                id: submenuAnchor
                                menu: modelData.hasChildren ? modelData.menu : null
                                anchor.item: menuEntry
                                anchor.edges: Edges.Right
                                anchor.gravity: Edges.Left
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
