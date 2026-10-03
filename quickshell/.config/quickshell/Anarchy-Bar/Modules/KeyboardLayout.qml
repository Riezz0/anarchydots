import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: keyboardLayoutRoot

    property var hostWindow: null
    property real anchorX: 0
    property string layout: "US"

    width: 42
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        border.color: theme.muted
        border.width: root.moduleBorderThickness
        color: layoutHover.containsMouse ? theme.color3 : "transparent"
    }

    Row {
        anchors.centerIn: parent

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: keyboardLayoutRoot.layout
            font.pixelSize: 13
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
            color: layoutHover.containsMouse ? theme.background : theme.muted
        }
    }

    MouseArea {
        id: layoutHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }

    Loader {
        id: keyboardLayoutTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: layoutHover.containsMouse
        property real tooltipAnchorX: keyboardLayoutRoot.anchorX
        property string tooltipDetails: "Active layout: " + keyboardLayoutRoot.layout
        onLoaded: {
            item.hostWindow = keyboardLayoutRoot.hostWindow
            item.title = "Keyboard Layout"
        }
        Binding { target: keyboardLayoutTooltip.item; property: "shown"; value: keyboardLayoutTooltip.tooltipShown; when: keyboardLayoutTooltip.item !== null }
        Binding { target: keyboardLayoutTooltip.item; property: "anchorX"; value: keyboardLayoutTooltip.tooltipAnchorX; when: keyboardLayoutTooltip.item !== null }
        Binding { target: keyboardLayoutTooltip.item; property: "details"; value: keyboardLayoutTooltip.tooltipDetails; when: keyboardLayoutTooltip.item !== null }
    }

    Process {
        id: layoutProcess
        command: ["bash", "-c", "hyprctl devices -j 2>/dev/null | python3 -c 'import json, sys; d=json.load(sys.stdin); k=next((x for x in d.get(\"keyboards\", []) if x.get(\"main\")), d.get(\"keyboards\", [{}])[0]); layouts=k.get(\"layout\", \"us\").split(\",\"); i=k.get(\"active_layout_index\", 0); n=layouts[i] if i < len(layouts) else layouts[0]; print(\"en\" if n == \"us\" else n)' 2>/dev/null || echo en"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var value = line.trim()
                if (value.length > 0)
                    keyboardLayoutRoot.layout = value
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: if (!layoutProcess.running) layoutProcess.running = true
    }

    Component.onCompleted: layoutProcess.running = true
}
