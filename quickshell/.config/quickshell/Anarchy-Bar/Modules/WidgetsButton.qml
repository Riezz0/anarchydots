import QtQuick

Item {
    id: widgetsButton

    property var hostWindow: null
    property real anchorX: 0

    width: 42
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        border.color: widgetsButtonHover.containsMouse || widgetsDrawer.isOpen ? theme.color4 : theme.muted
        border.width: root.moduleBorderThickness
        color: widgetsButtonHover.containsMouse || widgetsDrawer.isOpen ? theme.color4 : "transparent"

        Text {
            anchors.centerIn: parent
            text: "\u{F0E6F}"
            font.pixelSize: 20
            font.family: "JetBrainsMono Nerd Font"
            color: widgetsButtonHover.containsMouse || widgetsDrawer.isOpen ? theme.background : theme.muted
        }
    }

    MouseArea {
        id: widgetsButtonHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (widgetsDrawer.isOpen) widgetsDrawer.close()
            else widgetsDrawer.open(widgetsButton.hostWindow ? widgetsButton.hostWindow.screen : null)
        }
    }

    Loader {
        id: widgetsTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: widgetsButtonHover.containsMouse
        property real tooltipAnchorX: widgetsButton.anchorX
        onLoaded: {
            item.hostWindow = widgetsButton.hostWindow
            item.title = "Widgets"
            item.details = "LEFT CLICK  Open the widgets drawer"
        }
        Binding { target: widgetsTooltip.item; property: "shown"; value: widgetsTooltip.tooltipShown; when: widgetsTooltip.item !== null }
        Binding { target: widgetsTooltip.item; property: "anchorX"; value: widgetsTooltip.tooltipAnchorX; when: widgetsTooltip.item !== null }
    }

}
