import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    width: 400
    height: 500
    color: theme.background
    radius: 10
    border { color: theme.color2; width: 2 }

    property string currentCategory: "radius"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Rectangle {
            id: sidebar
            Layout.fillHeight: true
            Layout.preferredWidth: 120
            color: Qt.darker(theme.background, 1.1)
            radius: 10

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                Text {
                    text: "Settings"
                    color: theme.color2
                    font.bold: true
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 20
                }

                Repeater {
                    model: ["radius", "general", "appearance"]
                    delegate: Button {
                        text: modelData.toUpperCase()
                        Layout.fillWidth: true
                        flat: true
                        highlighted: root.currentCategory === modelData
                        onClicked: root.currentCategory = modelData
                    }
                }
            }
        }

        // Content Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            Loader {
                anchors.fill: parent
                anchors.margins: 20
                sourceComponent: {
                    if (root.currentCategory === "radius") return radiusSettings
                    return null
                }
            }
        }
    }

    Component {
        id: radiusSettings
        ColumnLayout {
            spacing: 20
            
            Text {
                text: "Quickshell Radius Settings"
                color: theme.color2
                font.pixelSize: 18
                font.bold: true
            }

            RowLayout {
                Text { text: "Border Radius:"; color: theme.muted }
                SpinBox {
                    id: radiusSpin
                    from: 0
                    to: 50
                    value: 5
                    onValueChanged: {
                        // Logic to apply radius to global theme would go here
                    }
                }
            }
        }
    }
}
