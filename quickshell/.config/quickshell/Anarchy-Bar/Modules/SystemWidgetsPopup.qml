import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: widgetsWindow
    screen: systemWidgetsPopup.targetScreen
    visible: systemWidgetsPopup.isOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region { item: widgetDragArea.drag.active ? widgetInputRegion : widgetPanel }

    Item {
        id: widgetInputRegion
        anchors.fill: parent
    }

    SystemTemperatureStats { id: stats }

    function temperatureColor(value, baseColor) {
        if (value <= 0) return theme.muted
        if (value >= 80) return theme.color1
        if (value >= 65) return theme.color3
        return baseColor
    }

    function transferToPointerScreen(mouse) {
        var pointer = widgetDragArea.mapToGlobal(mouse.x, mouse.y)
        var sourceScreen = widgetsWindow.screen
        if (!sourceScreen) return

        var globalX = root.screenX(sourceScreen) + widgetPanel.x
        var globalY = root.screenY(sourceScreen) + widgetPanel.y
        var destination = root.screenForWidgetDrag(
            pointer.x, pointer.y, globalX, globalY, widgetPanel.width, widgetPanel.height, sourceScreen
        )
        if (!destination || destination.name === sourceScreen.name) return

        var localX = Math.max(0, Math.min(globalX - root.screenX(destination), destination.width - widgetPanel.width))
        var localY = Math.max(0, Math.min(globalY - root.screenY(destination), destination.height - widgetPanel.height))
        systemWidgetsPopup.targetScreen = destination
        widgetPanel.x = localX
        widgetPanel.y = localY
        root.systemWidgetsX = localX
        root.systemWidgetsY = localY
    }

    Rectangle {
        x: widgetPanel.x + root.widgetShadowX
        y: widgetPanel.y + root.widgetShadowY
        width: widgetPanel.width
        height: widgetPanel.height
        radius: root.widgetShadowRadius
        color: Qt.rgba(0, 0, 0, root.widgetShadowEnabled ? root.widgetShadowOpacity : 0)
        z: 0
    }

    Rectangle {
        id: widgetPanel
        width: 330
        height: 230
        x: root.systemWidgetsX >= 0
            ? Math.min(root.systemWidgetsX, Math.max(0, parent.width - width))
            : (parent.width - width) / 2
        y: root.systemWidgetsY >= 0
            ? Math.min(root.systemWidgetsY, Math.max(0, parent.height - height))
            : (parent.height - height) / 2
        radius: root.widgetRadius
        color: theme.background
        opacity: root.widgetOpacity
        border.color: theme.color4
        border.width: root.widgetBorderThickness
        z: 1

        MouseArea {
            id: widgetDragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            drag.target: widgetPanel
            drag.axis: Drag.XAndYAxis
            drag.filterChildren: true
            onPositionChanged: mouse => {
                if (drag.active) widgetsWindow.transferToPointerScreen(mouse)
            }
            onReleased: mouse => {
                widgetsWindow.transferToPointerScreen(mouse)
                root.saveSystemWidgetsPosition(widgetPanel.x, widgetPanel.y)
                root.savePopupState()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Temperature"
                    color: theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "JetBrainsMono Nerd Font"
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: root.widgetRadius
                    color: closeHover.containsMouse ? theme.color1 : Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeHover.containsMouse ? theme.background : theme.muted
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: systemWidgetsPopup.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: theme.muted
                opacity: 0.4
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Item { Layout.fillWidth: true }

                SystemWidgetsMeter {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    label: "CPU"
                    value: stats.cpuTemp > 0 ? stats.cpuTemp + "°C" : "--°C"
                    subText: "TEMP"
                    progress: stats.cpuTemp
                    maxValue: 100
                    meterColor: widgetsWindow.temperatureColor(stats.cpuTemp, theme.color4)
                }

                Item { Layout.preferredWidth: 14 }

                SystemWidgetsMeter {
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    label: "GPU"
                    value: stats.gpuTemp > 0 ? stats.gpuTemp + "°C" : "--°C"
                    subText: stats.gpuTemp > 0 ? "TEMP" : "NO SENSOR"
                    progress: stats.gpuTemp
                    maxValue: 100
                    meterColor: widgetsWindow.temperatureColor(stats.gpuTemp, theme.color5)
                }

                Item { Layout.fillWidth: true }
            }

            Text {
                Layout.fillWidth: true
                text: "Live · refreshes every second"
                color: theme.muted
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

}
