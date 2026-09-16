import QtQuick
import Quickshell

PopupWindow {
    id: tooltip

    property var hostWindow: null
    property real anchorX: 0
    property bool shown: false
    property string title: ""
    property string details: ""

    visible: shown && hostWindow !== null
    color: "transparent"
    implicitWidth: 220
    implicitHeight: tooltipColumn.implicitHeight + 18

    anchor.window: hostWindow
    anchor.rect.x: anchorX - implicitWidth / 2
    anchor.rect.y: root.barPosition === "top" ? (hostWindow ? hostWindow.height + 7 : 0) : -implicitHeight - 7

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        color: Qt.darker(theme.background, 1.12)
        opacity: root.barOpacity
        border.width: root.barBorderThickness
        border.color: theme.color4

        Column {
            id: tooltipColumn
            anchors.fill: parent
            anchors.margins: 9
            spacing: 3

            Text {
                width: parent.width
                text: tooltip.title.toUpperCase()
                color: theme.foreground
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: tooltip.details
                color: theme.muted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                lineHeight: 1.1
                wrapMode: Text.WordWrap
            }
        }
    }
}
