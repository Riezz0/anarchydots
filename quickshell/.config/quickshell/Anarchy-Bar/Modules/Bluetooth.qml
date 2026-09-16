import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: bluetoothRoot

    property var hostWindow: null
    property real anchorX: 0
    property bool powered: false
    property int connected: 0
    property color stateColor: {
        if (!powered) return theme.muted
        if (connected > 0) return theme.color4
        return theme.color4
    }

    width: 42
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        border.color: theme.muted
        border.width: root.moduleBorderThickness
        color: bluetoothHover.containsMouse ? bluetoothRoot.stateColor : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{F00AF}"
            font.pixelSize: 20
            font.family: "JetBrainsMono Nerd Font"
            color: bluetoothHover.containsMouse ? theme.background : bluetoothRoot.stateColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: bluetoothRoot.connected > 0 ? bluetoothRoot.connected + "" : "Off"
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
            color: bluetoothHover.containsMouse ? theme.background : theme.muted
        }
    }

    MouseArea {
        id: bluetoothHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: bluemanProcess.running = true
    }

    Loader {
        id: bluetoothTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: bluetoothHover.containsMouse
        property real tooltipAnchorX: bluetoothRoot.anchorX
        onLoaded: {
            item.hostWindow = bluetoothRoot.hostWindow
            item.title = "Bluetooth"
            item.details = "LEFT CLICK  Open Bluetooth manager"
        }
        Binding { target: bluetoothTooltip.item; property: "shown"; value: bluetoothTooltip.tooltipShown; when: bluetoothTooltip.item !== null }
        Binding { target: bluetoothTooltip.item; property: "anchorX"; value: bluetoothTooltip.tooltipAnchorX; when: bluetoothTooltip.item !== null }
    }

    Process {
        id: bluemanProcess
        command: ["blueman-manager"]
        running: false
    }

    Process {
        id: bluetoothStatusProcess
        command: ["bash", "-c", "powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print $2; exit}'); connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l); echo \"${powered:-no} $connected\""]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var values = line.trim().split(/\s+/)
                bluetoothRoot.powered = values.length > 0 && values[0] === "yes"
                bluetoothRoot.connected = values.length > 1 ? Math.max(0, parseInt(values[1])) : 0
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: bluetoothStatusProcess.running = true
    }

    Component.onCompleted: bluetoothStatusProcess.running = true
}
