import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: infoPopupWindow

    visible: panelVisible
    screen: powerMenu.targetScreen

    property bool panelVisible: false

    anchors { top: true; bottom: true; left: true; right: true }

    color: "transparent"
    focusable: infoPopup.isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: infoPopup.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property int hwTab: 0

    Connections {
        target: infoPopup
        function onIsOpenChanged() {
            if (infoPopup.isOpen) panelVisible = true
            else hideTimer.start()
        }
    }

    Timer { id: hideTimer; interval: 300; onTriggered: if (!infoPopup.isOpen) panelVisible = false }

    MouseArea {
        anchors.fill: parent
        onClicked: infoPopup.close()
        opacity: infoPopup.isOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Rectangle {
        id: infoPanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        anchors.rightMargin: infoPopup.isOpen ? 10 : -(width + 20)
        width: 400
        radius: root.barRadius
        color: theme.background
        opacity: infoPopup.isOpen ? root.popupOpacity : 0
        clip: true
        border.color: theme.muted
        border.width: root.popupBorderThickness
        layer.enabled: true
        layer.effect: OpacityMask { maskSource: Rectangle { width: infoPanel.width; height: infoPanel.height; radius: root.barRadius; color: "white" } }

        Behavior on anchors.rightMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

        Flickable {
            anchors.fill: parent
            anchors.margins: 20
            clip: true
            contentHeight: popupCol.implicitHeight
            contentWidth: width
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: popupCol
                width: parent.width
                spacing: 0

                // Close
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 28; height: 28; radius: root.barRadius
                        color: closeH.containsMouse ? theme.color1 : Qt.darker(theme.background, 1.2)
                        Text { anchors.centerIn: parent; text: "\u2715"; font.pixelSize: 11; color: closeH.containsMouse ? theme.background : theme.foreground }
                        MouseArea { id: closeH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: infoPopup.close() }
                    }
                }

                // Weather card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: root.barRadius
                    color: Qt.darker(theme.background, 1.08)
                    border.color: theme.muted; border.width: root.popupBorderThickness

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 16; spacing: 12

                        Text { text: infoWidget.weatherIcon || "\u{F0590}"; font.pixelSize: 22; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }

                        ColumnLayout { spacing: 2
                            Text { text: infoWidget.loaded ? infoWidget.condition : "Loading..."; font.pixelSize: 15; font.bold: true; color: theme.foreground }
                            Text { text: infoWidget.loaded ? infoWidget.city + ", " + infoWidget.country : ""; font.pixelSize: 11; color: theme.muted }
                        }

                        Item { Layout.fillWidth: true }

                        Text { text: infoWidget.loaded ? infoWidget.tempC + "\u00B0C" : "--"; font.pixelSize: 28; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.foreground; Layout.alignment: Qt.AlignVCenter }
                    }
                }

                // Weather details
                Row {
                    Layout.fillWidth: true; Layout.bottomMargin: 16
                    layoutDirection: Qt.LeftToRight

                    Column {
                        width: parent.width / 3
                        spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{F0539}"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color4 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: infoWidget.loaded ? infoWidget.tempC + "\u00B0C" : "--"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.foreground }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Feels"; font.pixelSize: 10; color: theme.muted }
                    }

                    Column {
                        width: parent.width / 3
                        spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{F05AE}"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color4 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: infoWidget.loaded ? infoWidget.windSpeed + " km/h" : "--"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.foreground }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: infoWidget.windDir; font.pixelSize: 10; color: theme.muted }
                    }

                    Column {
                        width: parent.width / 3
                        spacing: 2
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u{F058E}"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: theme.color4 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: infoWidget.humidity + "%"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.foreground }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Humidity"; font.pixelSize: 10; color: theme.muted }
                    }
                }

                // Divider
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.topMargin: 16; Layout.bottomMargin: 16; color: theme.muted; opacity: 0.45 }

                // Hardware Monitor
                Text { text: "Hardware Monitor"; font.pixelSize: 16; font.bold: true; color: theme.foreground; Layout.bottomMargin: 12 }

                // Tabs
                RowLayout {
                    Layout.fillWidth: true; Layout.bottomMargin: 16; spacing: 8
                    Repeater {
                        model: ["CPU", "RAM", "GPU", "Disk"]
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 32; radius: root.barRadius
                            color: hwTab === index ? theme.color4 : "transparent"
                            border.color: hwTab === index ? theme.color4 : theme.muted; border.width: root.popupBorderThickness
                            Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 12; font.bold: hwTab === index; color: hwTab === index ? theme.background : theme.foreground }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: hwTab = index }
                        }
                    }
                }

                // CPU / GPU view: circular gauge
                Item {
                    id: gaugeItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    visible: hwTab === 0 || hwTab === 2

                    property real gaugeTemp: hwTab === 0 ? infoWidget.cpuTemp : infoWidget.gpuTemp

                    property color gaugeColor: {
                        if (gaugeTemp >= 80) return theme.color1
                        if (gaugeTemp >= 60) return theme.color3
                        return theme.color2
                    }

                    Canvas {
                        id: gaugeCanvas
                        anchors.centerIn: parent
                        width: 180; height: 180

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var cx = width / 2, cy = height / 2, r = 70, lw = 8

                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.strokeStyle = Qt.darker(theme.background, 1.5)
                            ctx.lineWidth = lw
                            ctx.lineCap = "round"
                            ctx.stroke()

                            var frac = Math.min(Math.max(gaugeItem.gaugeTemp / 100, 0), 1)
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac)
                            ctx.strokeStyle = gaugeItem.gaugeColor
                            ctx.lineWidth = lw
                            ctx.lineCap = "round"
                            ctx.stroke()

                            for (var i = 0; i < 12; i++) {
                                var tickAngle = (i / 12) * Math.PI * 2 - Math.PI / 2
                                var innerR = r - lw / 2 - 3
                                var outerR = r - lw / 2 - 7
                                ctx.beginPath()
                                ctx.moveTo(cx + Math.cos(tickAngle) * innerR, cy + Math.sin(tickAngle) * innerR)
                                ctx.lineTo(cx + Math.cos(tickAngle) * outerR, cy + Math.sin(tickAngle) * outerR)
                                ctx.strokeStyle = theme.muted
                                ctx.lineWidth = 1
                                ctx.stroke()
                            }
                        }

                        Connections {
                            target: gaugeItem
                            function onGaugeTempChanged() { gaugeCanvas.requestPaint() }
                        }
                    }

                    Column {
                        anchors.centerIn: parent; spacing: 2; z: 1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: gaugeItem.gaugeTemp + "\u00B0C"
                            font.pixelSize: 28; font.family: "JetBrainsMono Nerd Font"; font.bold: true
                            color: gaugeItem.gaugeColor
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: hwTab === 0
                                ? infoWidget.cpuUsage + "% Usage"
                                : (infoWidget.gpuUsage > 0 ? infoWidget.gpuUsage + "% Usage" : infoWidget.gpuName)
                            font.pixelSize: 12; color: theme.muted
                        }
                    }
                }

                // RAM view
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    visible: hwTab === 1

                    Canvas {
                        id: ramGauge
                        anchors.centerIn: parent
                        width: 180; height: 180

                        property color gaugeColor: {
                            if (infoWidget.ramUsage >= 80) return theme.color1
                            if (infoWidget.ramUsage >= 60) return theme.color3
                            return theme.color2
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var cx = width / 2, cy = height / 2, r = 70, lw = 8

                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.strokeStyle = Qt.darker(theme.background, 1.5)
                            ctx.lineWidth = lw
                            ctx.lineCap = "round"
                            ctx.stroke()

                            var frac = infoWidget.ramUsage / 100
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac)
                            ctx.strokeStyle = gaugeColor
                            ctx.lineWidth = lw
                            ctx.lineCap = "round"
                            ctx.stroke()

                            for (var i = 0; i < 12; i++) {
                                var tickAngle = (i / 12) * Math.PI * 2 - Math.PI / 2
                                var innerR = r - lw / 2 - 3
                                var outerR = r - lw / 2 - 7
                                ctx.beginPath()
                                ctx.moveTo(cx + Math.cos(tickAngle) * innerR, cy + Math.sin(tickAngle) * innerR)
                                ctx.lineTo(cx + Math.cos(tickAngle) * outerR, cy + Math.sin(tickAngle) * outerR)
                                ctx.strokeStyle = theme.muted
                                ctx.lineWidth = 1
                                ctx.stroke()
                            }
                        }

                        Connections {
                            target: infoWidget
                            function onRamUsageChanged() { ramGauge.requestPaint() }
                        }
                    }

                    Column {
                        anchors.centerIn: parent; spacing: 2; z: 1
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: infoWidget.ramUsage + "%"; font.pixelSize: 28; font.family: "JetBrainsMono Nerd Font"; font.bold: true; color: theme.foreground }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(infoWidget.ramUsed) + "G / " + Math.round(infoWidget.ramTotal) + "G"; font.pixelSize: 12; color: theme.muted }
                    }
                }

                // Disk view
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: hwTab === 3
                    spacing: 6

                    Repeater {
                        model: infoWidget.disks

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 44; radius: root.barRadius
                            color: Qt.darker(theme.background, 1.08)
                                    border.color: modelData.mounted ? theme.muted : Qt.darker(theme.muted, 1.3); border.width: root.popupBorderThickness

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8

                                Text { text: "\u{F0A0A}"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; color: modelData.mounted ? theme.color4 : theme.muted }

                                ColumnLayout { spacing: 1
                                    Text { text: "/dev/" + modelData.name; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: theme.foreground }
                                    Text { text: modelData.mount + (modelData.fstype.length > 0 ? " (" + modelData.fstype + ")" : ""); font.pixelSize: 10; color: modelData.mounted ? theme.muted : theme.color1 }
                                }

                                Item { Layout.fillWidth: true }

                                Text { text: modelData.size; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: theme.muted }
                            }
                        }
                    }

                    Text { visible: infoWidget.disks.length === 0; text: "No disks found"; font.pixelSize: 12; color: theme.muted; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20 }
                }

                // Refresh
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 36; Layout.topMargin: 16; radius: root.barRadius
                    color: refreshHover.containsMouse ? Qt.darker(theme.color4, 1.3) : theme.color4
                    Text { anchors.centerIn: parent; text: "Refresh"; font.pixelSize: 12; font.bold: true; color: theme.background }
                    MouseArea { id: refreshHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: infoWidget.refreshWeather() }
                }
            }
        }

        Rectangle { anchors.fill: parent; radius: root.barRadius; color: "transparent"; border.color: theme.muted; border.width: root.popupBorderThickness; z: 10 }
    }

    Item { anchors.fill: parent; focus: infoPopup.isOpen; Keys.onEscapePressed: infoPopup.close() }
}
