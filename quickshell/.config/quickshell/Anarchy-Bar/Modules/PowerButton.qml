import QtQuick

Rectangle {
    id: powerBtn

    property var hostWindow: null
    property real anchorX: 0
    property bool isOpen: false
    property var screen: null

    width: 42
    height: 42
    radius: root.barRadius
    color: isOpen ? theme.color1 : "transparent"

    Text {
        anchors.centerIn: parent
        text: "󰐥"
        color: powerBtn.isOpen ? theme.background : theme.color1
        font.pixelSize: 25
        font.family: "JetBrainsMono Nerd Font"
    }

    MouseArea {
        id: powerBtnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: powerBtn.opacity = 0.7
        onExited: powerBtn.opacity = 1.0
        onClicked: powerMenu.isOpen ? powerMenu.close() : powerMenu.open(powerBtn.screen)
    }

    Loader {
        id: powerTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: powerBtnMouse.containsMouse
        property real tooltipAnchorX: powerBtn.anchorX
        onLoaded: {
            item.hostWindow = powerBtn.hostWindow
            item.title = "Power"
            item.details = "LEFT CLICK  Open power menu"
        }
        Binding { target: powerTooltip.item; property: "shown"; value: powerTooltip.tooltipShown; when: powerTooltip.item !== null }
        Binding { target: powerTooltip.item; property: "anchorX"; value: powerTooltip.tooltipAnchorX; when: powerTooltip.item !== null }
    }

    Behavior on opacity { NumberAnimation { duration: 150 } }
}
