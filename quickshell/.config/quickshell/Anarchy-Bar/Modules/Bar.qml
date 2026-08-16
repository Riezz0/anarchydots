import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar
        screen: modelData
        required property var modelData

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 60
        exclusiveZone: 60
        exclusionMode: ExclusionMode.Normal
        color: "transparent"
        visible: !powerMenu.isOpen

        WlrLayershell.layer: WlrLayer.Top

        margins { left: 10; right: 10; top: 10; bottom: 10 }

        Rectangle {
            anchors.fill: parent
            color: theme.background

            // Left modules
            Row {
                id: leftModules
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                padding: 10
                spacing: 15

                ArchLogo {
                    height: parent.height - 20
                    width: height
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
                height: parent.height
                padding: 10
                spacing: 10

                PowerButton {
                    screen: bar.screen
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Bottom separator line
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: theme.muted
                opacity: 0.4
            }
        }
    }
}
