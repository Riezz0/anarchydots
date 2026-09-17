import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: scratchpadContainer

    property var hostWindow: null
    property real anchorX: 0
    property var scratchpads: [
        { name: "nautipad", className: "org.gnome.Nautilus", icon: "\u{F07C}", tooltip: "File Explorer" },
        { name: "termpad", className: "termpad", icon: "\u{F489}", tooltip: "Terminal" },
        { name: "vimpad", className: "vimpad", icon: "\u{E62B}", tooltip: "Neovim" },
        { name: "codepad", className: "codepad", icon: "\u{E70C}", tooltip: "VSS Code" },
        { name: "osdpad", className: "ARKB", icon: "\u{F11C}", tooltip: "Arabic Keyboard Layout" }
    ]
    property var scratchpadClients: []
    property string activeScratchpadClass: ""
    property var hoveredScratchpad: null
    property real hoveredScratchpadX: 0

    function refreshScratchpads() {
        if (scratchpadProc.running)
            return false
        scratchpadProc.buffer = ""
        scratchpadProc.running = true
        return true
    }

    function scratchpadClient(name) {
        for (var i = 0; i < scratchpadClients.length; ++i) {
            if (scratchpadClients[i].name === name)
                return scratchpadClients[i]
        }
        return null
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: {
            if (scratchpadContainer.refreshScratchpads()) {
                activeScratchpadProc.buffer = ""
                activeScratchpadProc.running = true
            }
        }
    }

    Process {
        id: scratchpadProc
        command: ["hyprctl", "clients", "-j"]
        running: true
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => scratchpadProc.buffer += data
        }

        onRunningChanged: {
            if (running || scratchpadProc.buffer.length === 0)
                return

            try {
                var clients = JSON.parse(scratchpadProc.buffer)
                var pads = []
                for (var i = 0; i < clients.length; ++i) {
                    var client = clients[i]
                    for (var j = 0; j < scratchpadContainer.scratchpads.length; ++j) {
                        var pad = scratchpadContainer.scratchpads[j]
                        if (client.class === pad.className) {
                            pads.push({
                                name: pad.name,
                                workspace: client.workspace ? client.workspace.name : "",
                                visible: client.visible === true
                            })
                            break
                        }
                    }
                }
                scratchpadContainer.scratchpadClients = pads
            } catch (error) {
                console.warn("Anarchy-Bar: failed to read Hyprscratch clients:", error)
            }
            scratchpadProc.buffer = ""
        }
    }

    PopupWindow {
        visible: scratchpadContainer.hoveredScratchpad !== null && scratchpadContainer.hostWindow !== null
        color: "transparent"
        implicitWidth: scratchpadTooltipColumn.implicitWidth + 24
        implicitHeight: scratchpadTooltipColumn.implicitHeight + 18

        anchor.window: scratchpadContainer.hostWindow
        anchor.rect.x: scratchpadContainer.hoveredScratchpadX - implicitWidth / 2
        anchor.rect.y: root.barPosition === "top" ? scratchpadContainer.hostWindow.height + 7 : -implicitHeight - 7

        Rectangle {
            anchors.fill: parent
            radius: root.barRadius
            color: Qt.darker(theme.background, 1.12)
            opacity: root.barOpacity
            border.width: root.barBorderThickness
            border.color: theme.color4

            Column {
                id: scratchpadTooltipColumn
                anchors.centerIn: parent
                spacing: 3

                Text {
                    id: scratchpadTooltipLabel
                    text: scratchpadContainer.hoveredScratchpad ? scratchpadContainer.hoveredScratchpad.tooltip.toUpperCase() : ""
                    color: theme.foreground
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: "LEFT CLICK  TOGGLE"
                    color: theme.muted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                }
            }
        }
    }

    Process {
        id: scratchpadToggleProc
        running: false
    }

    Process {
        id: activeScratchpadProc
        command: ["hyprctl", "activewindow", "-j"]
        running: false
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => activeScratchpadProc.buffer += data
        }

        onRunningChanged: {
            if (running || activeScratchpadProc.buffer.length === 0)
                return

            try {
                var client = JSON.parse(activeScratchpadProc.buffer)
                scratchpadContainer.activeScratchpadClass = client.class || ""
            } catch (error) {
                scratchpadContainer.activeScratchpadClass = ""
            }
            activeScratchpadProc.buffer = ""
        }
    }

    visible: scratchpadClients.length > 0
    implicitWidth: visible ? scratchpadRow.width + 12 : 0
    width: implicitWidth
    height: 42
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        border.color: theme.muted
        border.width: root.moduleBorderThickness
        color: "transparent"
    }

    Row {
        id: scratchpadRow
        anchors.centerIn: parent
        spacing: 11

        Item { width: 6; height: 1 }

        Repeater {
            model: scratchpadContainer.scratchpads

            Rectangle {
                id: scratchpadIndicator
                required property var modelData
                property var client: scratchpadContainer.scratchpadClient(modelData.name)
                property bool spawned: client !== null
                property bool isActive: spawned && scratchpadContainer.activeScratchpadClass === modelData.className
                property bool hovered: false

                visible: spawned
                width: visible ? 24 : 0
                height: 24
                radius: root.barRadius
                color: "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.DemiBold
                    color: parent.isActive ? (parent.hovered ? Qt.lighter(theme.color5, 1.2) : theme.color5) : theme.muted
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: {
                        parent.hovered = true
                        scratchpadContainer.hoveredScratchpad = modelData
                        scratchpadContainer.hoveredScratchpadX = scratchpadContainer.anchorX + scratchpadIndicator.x + scratchpadIndicator.width / 2 - scratchpadRow.width / 2
                    }
                    onExited: {
                        parent.hovered = false
                        scratchpadContainer.hoveredScratchpad = null
                    }
                    onClicked: {
                        scratchpadToggleProc.command = ["hyprscratch", "toggle", modelData.name]
                        scratchpadToggleProc.running = true
                    }
                }

            }
        }

        Item { width: 6; height: 1 }
    }
}
