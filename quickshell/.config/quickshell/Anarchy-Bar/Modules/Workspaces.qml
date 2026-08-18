import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: workspaceContainer

    property int _tick: 0

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: workspaceContainer._tick++
    }

    width: workspaceRow.width + 12
    // Give the indicators more breathing room inside their bordered module.
    height: 42
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
        id: workspaceBg
        anchors.fill: parent
        radius: root.barRadius
        border.color: theme.muted
        border.width: root.moduleBorderThickness
        color: "transparent"
    }

    Row {
        id: workspaceRow
        anchors.centerIn: parent
        anchors.margins: 8
        spacing: 5

        // Extra breathing room for the first and last visible indicators.
        Item {
            width: 6
            height: 1
        }

        Repeater {
            model: 5

            Rectangle {
                required property int index
                property int workspaceId: index + 1
                width: root.workspaceIndicatorStyle === "dots" || root.workspaceIndicatorStyle === "squares" ? (isActive ? 28 : 23) : 24
                height: 24
                radius: root.barRadius

                property bool isActive: {
                    workspaceContainer._tick
                    if (typeof Hyprland === "undefined" || !Hyprland.focusedWorkspace) return false
                    return Hyprland.focusedWorkspace.id === workspaceId
                }

                property bool hasWindows: {
                    workspaceContainer._tick
                    if (typeof Hyprland === "undefined" || !Hyprland.workspaces) return false
                    for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                        const ws = Hyprland.workspaces.get(i)
                        if (ws.id === workspaceId && ws.windowCount > 0)
                            return true
                    }
                    return false
                }

                property bool hovered: false

                color: root.workspaceIndicatorStyle === "numbers" ? (isActive ? (hovered ? Qt.lighter(theme.color2, 1.2) : theme.color2) : (hasWindows ? Qt.darker(theme.background, 1.25) : "transparent")) : "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    visible: root.workspaceIndicatorStyle !== "numbers"
                    width: root.workspaceIndicatorStyle === "dots" || root.workspaceIndicatorStyle === "squares" ? (parent.isActive ? parent.width : 16) : 16
                    height: 16
                    radius: root.workspaceIndicatorStyle === "squares" ? 2 : height / 2
                    color: parent.isActive ? (parent.hovered ? Qt.lighter(theme.color2, 1.2) : theme.color2) : theme.muted
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.workspaceId.toString()
                    visible: root.workspaceIndicatorStyle === "numbers"
                    color: parent.isActive ? theme.background : (parent.hovered ? theme.foreground : (parent.hasWindows ? theme.color4 : theme.muted))
                    font.pixelSize: 12
                    font.weight: Font.DemiBold

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: {
                        if (Hyprland.usingLua) {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.workspaceId + " })")
                        } else {
                            Hyprland.dispatch("workspace " + parent.workspaceId)
                        }
                    }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Repeater {
            model: 5

            Rectangle {
                required property int index
                property int workspaceId: index + 6
                visible: hasWindows || isActive
                width: visible ? (root.workspaceIndicatorStyle === "dots" || root.workspaceIndicatorStyle === "squares" ? (isActive ? 28 : 23) : 24) : 0
                height: 24
                radius: root.barRadius

                property bool isActive: {
                    workspaceContainer._tick
                    if (typeof Hyprland === "undefined" || !Hyprland.focusedWorkspace) return false
                    return Hyprland.focusedWorkspace.id === workspaceId
                }

                property bool hasWindows: {
                    workspaceContainer._tick
                    if (typeof Hyprland === "undefined" || !Hyprland.workspaces) return false
                    for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                        const ws = Hyprland.workspaces.get(i)
                        if (ws.id === workspaceId && ws.windowCount > 0)
                            return true
                    }
                    return false
                }

                property bool hovered: false

                color: root.workspaceIndicatorStyle === "numbers" ? (isActive ? (hovered ? Qt.lighter(theme.color2, 1.2) : theme.color2) : (hasWindows ? Qt.darker(theme.background, 1.25) : "transparent")) : "transparent"

                Rectangle {
                    anchors.centerIn: parent
                    visible: root.workspaceIndicatorStyle !== "numbers"
                    width: root.workspaceIndicatorStyle === "dots" || root.workspaceIndicatorStyle === "squares" ? (parent.isActive ? parent.width : 16) : 16
                    height: 16
                    radius: root.workspaceIndicatorStyle === "squares" ? 2 : height / 2
                    color: parent.isActive ? (parent.hovered ? Qt.lighter(theme.color2, 1.2) : theme.color2) : theme.muted
                }

                Text {
                    anchors.centerIn: parent
                    text: parent.workspaceId.toString()
                    visible: root.workspaceIndicatorStyle === "numbers"
                    color: parent.isActive ? theme.background : (parent.hovered ? theme.foreground : (parent.hasWindows ? theme.color4 : theme.muted))
                    font.pixelSize: 12
                    font.weight: Font.DemiBold

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                    onClicked: {
                        if (Hyprland.usingLua) {
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.workspaceId + " })")
                        } else {
                            Hyprland.dispatch("workspace " + parent.workspaceId)
                        }
                    }
                }

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on width { NumberAnimation { duration: 200 } }
            }
        }

        Item {
            width: 6
            height: 1
        }
    }
}
