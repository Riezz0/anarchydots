import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: mouseBatteryRoot

    property var hostWindow: null
    property real anchorX: 0
    property int battery: -1
    property color batteryColor: {
        if (battery < 0) return theme.muted
        if (battery >= 50) return theme.color2
        if (battery >= 20) return theme.color3
        return theme.color1
    }

    width: 42
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        border.color: theme.muted
        border.width: root.moduleBorderThickness
        color: mouseBatteryHover.containsMouse ? mouseBatteryRoot.batteryColor : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{F037D}"
            font.pixelSize: 20
            font.family: "JetBrainsMono Nerd Font"
            color: mouseBatteryHover.containsMouse ? theme.background : mouseBatteryRoot.batteryColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: mouseBatteryRoot.battery >= 0 ? mouseBatteryRoot.battery + "%" : "--"
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
            color: mouseBatteryHover.containsMouse ? theme.background : theme.muted
        }
    }

    MouseArea {
        id: mouseBatteryHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: piperProcess.running = true
    }

    Loader {
        id: mouseBatteryTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: mouseBatteryHover.containsMouse
        property real tooltipAnchorX: mouseBatteryRoot.anchorX
        onLoaded: {
            item.hostWindow = mouseBatteryRoot.hostWindow
            item.title = "Mouse Battery"
            item.details = "LEFT CLICK  Open Piper"
        }
        Binding { target: mouseBatteryTooltip.item; property: "shown"; value: mouseBatteryTooltip.tooltipShown; when: mouseBatteryTooltip.item !== null }
        Binding { target: mouseBatteryTooltip.item; property: "anchorX"; value: mouseBatteryTooltip.tooltipAnchorX; when: mouseBatteryTooltip.item !== null }
    }

    Process {
        id: piperProcess
        command: ["piper"]
        running: false
    }

    Process {
        id: batteryProcess
        command: ["bash", "-c", "device=$(upower -e 2>/dev/null | grep -iE 'mouse|hidpp' | head -n 1); if [ -n \"$device\" ]; then upower -i \"$device\" 2>/dev/null | awk '/percentage:/ {gsub(\"%\", \"\", $2); print $2; exit}'; else echo -1; fi"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var value = parseInt(line.trim())
                mouseBatteryRoot.battery = isNaN(value) ? -1 : Math.max(0, Math.min(100, value))
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: batteryProcess.running = true
    }

    Component.onCompleted: batteryProcess.running = true
}
