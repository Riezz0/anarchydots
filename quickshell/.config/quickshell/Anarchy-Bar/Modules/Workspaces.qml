import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: workspaceRow

    spacing: 5
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
        model: 5

        Rectangle {
            required property int index
            property int workspaceId: index + 1
            width: 28
            height: 28
            radius: 6

            property bool isActive: Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === workspaceId

            property bool hasWindows: {
                for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                    const ws = Hyprland.workspaces.get(i)
                    if (ws.id === workspaceId && ws.windowCount > 0)
                        return true
                }
                return false
            }

            property bool hovered: false

            color: isActive ? (hovered ? Qt.lighter(theme.color2, 1.2) : theme.color2) : (hasWindows ? Qt.darker(theme.background, 1.25) : "transparent")

            Text {
                anchors.centerIn: parent
                text: parent.workspaceId.toString()
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
            width: visible ? 28 : 0
            height: 28
            radius: 6

            property bool isActive: Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === workspaceId

            property bool hasWindows: {
                for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                    const ws = Hyprland.workspaces.get(i)
                    if (ws.id === workspaceId && ws.windowCount > 0)
                        return true
                }
                return false
            }

            property bool hovered: false

            color: isActive ? (hovered ? Qt.lighter(theme.color2, 1.2) : theme.color2) : (hasWindows ? Qt.darker(theme.background, 1.25) : "transparent")

            Text {
                anchors.centerIn: parent
                text: parent.workspaceId.toString()
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
}
