import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        screen: modelData
        required property var modelData
        visible: !powerMenu.isOpen && root.isMonitorEnabled(modelData)

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 60
        exclusiveZone: 60
        exclusionMode: ExclusionMode.Normal
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top

        margins { left: 10; right: 10; top: 5; bottom: 0 }

        // Background with opacity
        Rectangle {
            anchors.fill: parent
            color: theme.background
            radius: root.barRadius
            opacity: root.barOpacity
            border.color: theme.muted
            border.width: root.barBorderThickness
        }

        // Modules (no opacity)
        Item {
            anchors.fill: parent

            // Left modules
            Row {
                id: leftModules
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                padding: 10
                spacing: 10

                ArchLogo {
                    height: 42
                    width: 42
                }

                Workspaces {}
            }

            // Center modules
            Row {
                anchors.centerIn: parent
                height: parent.height
                padding: 10
                spacing: 10
            }

            // Right modules
            Row {
                id: rightModules
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                padding: 10
                spacing: 10

                Clock {}

                PowerButton {
                    screen: bar.screen
                }
            }
        }
    }
}
