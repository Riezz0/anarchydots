import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: settingsWindow

    visible: settingsPopup.isOpen
    screen: settingsPopup.targetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    focusable: settingsPopup.isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: settingsPopup.isOpen
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    property int currentTab: 0

    MouseArea {
        anchors.fill: parent
        onClicked: settingsPopup.close()
    }

    Rectangle {
        id: settingsPanel
        anchors.centerIn: parent
        width: Math.min(760, parent.width - 40)
        height: Math.min(620, parent.height - 40)
        radius: root.barRadius
        color: theme.background
        opacity: settingsPopup.isOpen ? root.popupOpacity : 0
        clip: true
        border.color: theme.muted
        border.width: root.popupBorderThickness
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: settingsPanel.width
                height: settingsPanel.height
                radius: root.barRadius
                color: "white"
            }
        }

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // App-like navigation rail.
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 190
                color: Qt.darker(theme.background, 1.12)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "󰒓"
                            font.pixelSize: 23
                            font.family: "JetBrainsMono Nerd Font"
                            color: theme.color5
                        }

                        Text {
                            text: "Settings"
                            font.pixelSize: 17
                            font.bold: true
                            color: theme.foreground
                        }
                    }

                    Text {
                        Layout.topMargin: 30
                        text: "CONFIGURATION"
                        font.pixelSize: 10
                        font.bold: true
                        color: theme.muted
                    }

                    Rectangle {
                        id: barTab
                        Layout.preferredHeight: 42
                        Layout.topMargin: 10
                        Layout.preferredWidth: hyprlandTabContent.implicitWidth + 24
                        radius: root.barRadius
                        color: settingsWindow.currentTab === 0 ? theme.color5 : (barTabHover.containsMouse ? Qt.darker(theme.background, 1.25) : "transparent")

                        RowLayout {
                            id: barTabContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "󰏘"
                                font.pixelSize: 17
                                font.family: "JetBrainsMono Nerd Font"
                                color: settingsWindow.currentTab === 0 ? theme.background : theme.color5
                            }

                            Text {
                                text: "Bar Settings"
                                font.pixelSize: 13
                                font.bold: settingsWindow.currentTab === 0
                                color: settingsWindow.currentTab === 0 ? theme.background : theme.foreground
                            }
                        }

                        MouseArea {
                            id: barTabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.currentTab = 0
                        }
                    }

                    Rectangle {
                        id: hyprlandTab
                        Layout.preferredHeight: 42
                        Layout.topMargin: 10
                        Layout.preferredWidth: hyprlandTabContent.implicitWidth + 24
                        radius: root.barRadius
                        color: settingsWindow.currentTab === 1 ? theme.color5 : (appearanceTabHover.containsMouse ? Qt.darker(theme.background, 1.25) : "transparent")

                        RowLayout {
                            id: hyprlandTabContent
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: "󰉼"
                                font.pixelSize: 17
                                font.family: "JetBrainsMono Nerd Font"
                                color: settingsWindow.currentTab === 1 ? theme.background : theme.color5
                            }

                            Text {
                                text: "Hyprland Settings"
                                font.pixelSize: 13
                                color: settingsWindow.currentTab === 1 ? theme.background : theme.foreground
                            }
                        }

                        MouseArea {
                            id: appearanceTabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsWindow.currentTab = 1
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "Anarchy-Bar"
                        font.pixelSize: 11
                        color: theme.muted
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                color: theme.background

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 26
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 3

                            Text {
                                text: settingsWindow.currentTab === 0 ? "Bar Settings" : "Hyprland Settings"
                                font.pixelSize: 22
                                font.bold: true
                                color: theme.foreground
                            }

                            Text {
                                text: settingsWindow.currentTab === 0 ? "Customize the shape and placement of your bar." : "More customization options are coming soon."
                                font.pixelSize: 12
                                color: theme.muted
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: root.barRadius
                            color: closeArea.containsMouse ? theme.color1 : Qt.darker(theme.background, 1.2)

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 13
                                color: closeArea.containsMouse ? theme.background : theme.foreground
                            }

                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsPopup.close()
                            }
                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.topMargin: 20
                        Layout.bottomMargin: 18
                        color: theme.muted
                        opacity: 0.45
                    }

                    Flickable {
                        Layout.fillWidth: true
                        clip: true
                        contentWidth: width
                        contentHeight: settingsContent.implicitHeight
                        visible: settingsWindow.currentTab === 0
                        Layout.fillHeight: settingsWindow.currentTab === 0
                        Layout.preferredHeight: settingsWindow.currentTab === 0 ? -1 : 0

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: settingsContent
                            width: parent.width
                            spacing: 20

                            SettingSlider {
                                label: "Bar Radius"
                                valueText: root.barRadius.toString()
                                minimumText: "0"
                                maximumText: "50"
                                from: 0
                                to: 50
                                value: root.barRadius
                                onMoved: root.barRadius = Math.round(value)
                            }

                            SettingSlider {
                                label: "Bar Opacity"
                                valueText: Math.round(root.barOpacity * 100) + "%"
                                minimumText: "0%"
                                maximumText: "100%"
                                from: 0
                                to: 1
                                stepSize: 0.05
                                value: root.barOpacity
                                onMoved: root.barOpacity = Math.round(value * 100) / 100
                            }

                            SettingSlider {
                                label: "Popup Opacity"
                                valueText: Math.round(root.popupOpacity * 100) + "%"
                                minimumText: "0%"
                                maximumText: "100%"
                                from: 0
                                to: 1
                                stepSize: 0.05
                                value: root.popupOpacity
                                onMoved: root.popupOpacity = Math.round(value * 100) / 100
                            }

                            SettingSlider {
                                label: "Bar Border"
                                valueText: root.barBorderThickness + "px"
                                minimumText: "0"
                                maximumText: "4"
                                from: 0
                                to: 4
                                value: root.barBorderThickness
                                onMoved: root.barBorderThickness = Math.round(value)
                            }

                            SettingSlider {
                                label: "Module Border"
                                valueText: root.moduleBorderThickness + "px"
                                minimumText: "0"
                                maximumText: "4"
                                from: 0
                                to: 4
                                value: root.moduleBorderThickness
                                onMoved: root.moduleBorderThickness = Math.round(value)
                            }

                            SettingSlider {
                                label: "Popup Border"
                                valueText: root.popupBorderThickness + "px"
                                minimumText: "0"
                                maximumText: "4"
                                from: 0
                                to: 4
                                value: root.popupBorderThickness
                                onMoved: root.popupBorderThickness = Math.round(value)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Monitors"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: theme.color5
                                }

                                Repeater {
                                    model: Quickshell.screens

                                    Rectangle {
                                        id: monitorRow
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        radius: root.barRadius
                                        color: monitorHover.containsMouse ? Qt.darker(theme.background, 1.2) : "transparent"

                                        property var monitor: modelData
                                        property bool isEnabled: root.barMonitors.length === 0 || root.barMonitors.indexOf(monitor.name) !== -1

                                        RowLayout {
                                            anchors.fill: parent
                                            spacing: 10

                                            Rectangle {
                                                Layout.alignment: Qt.AlignVCenter
                                                Layout.preferredWidth: 18
                                                Layout.preferredHeight: 18
                                                radius: 4
                                                border.color: theme.muted
                                                border.width: 1
                                                color: monitorRow.isEnabled ? theme.color5 : "transparent"

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "✓"
                                                    color: theme.background
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    visible: monitorRow.isEnabled
                                                }
                                            }

                                            Text {
                                                text: monitorRow.monitor.name
                                                font.pixelSize: 12
                                                color: theme.foreground
                                            }

                                            Item { Layout.fillWidth: true }
                                        }

                                        MouseArea {
                                            id: monitorHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleMonitor(monitorRow.monitor)
                                        }
                                    }
                                }

                                Text {
                                    text: root.barMonitors.length === 0 ? "All monitors" : root.barMonitors.length + " monitor(s) selected"
                                    font.pixelSize: 11
                                    color: theme.muted
                                }
                            }
                        }
                    }

                    Flickable {
                        id: hyprlandSettingsScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: settingsWindow.currentTab === 1
                        Layout.preferredHeight: settingsWindow.currentTab === 1 ? -1 : 0
                        visible: settingsWindow.currentTab === 1
                        clip: true
                        contentWidth: width
                        contentHeight: hyprlandSettingsContent.implicitHeight

                        ColumnLayout {
                            id: hyprlandSettingsContent
                            width: hyprlandSettingsScroll.width
                            spacing: 10

                        Text {
                            text: "Hyprland Window Appearance"
                            font.pixelSize: 14
                            font.bold: true
                            color: theme.foreground
                        }
                        Text {
                            text: "Configure borders, opacity, corners, and workspace indicators."
                            font.pixelSize: 12
                            color: theme.muted
                        }

                        Text {
                            Layout.topMargin: 12
                            text: "Workspace Indicator Style"
                            font.pixelSize: 14
                            font.bold: true
                            color: theme.foreground
                        }

                        Text {
                            text: "Choose how workspaces appear in the bar."
                            font.pixelSize: 12
                            color: theme.muted
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 10
                            spacing: 10

                            Repeater {
                                model: ["numbers", "dots", "squares"]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    radius: root.barRadius
                                    color: root.workspaceIndicatorStyle === modelData ? theme.color5 : (indicatorHover.containsMouse ? Qt.darker(theme.background, 1.2) : "transparent")
                                    border.color: root.workspaceIndicatorStyle === modelData ? theme.color5 : theme.muted
                                    border.width: root.moduleBorderThickness

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData === "numbers" ? "Numbers" : (modelData === "dots" ? "Dots" : "Squares")
                                        font.pixelSize: 13
                                        color: root.workspaceIndicatorStyle === modelData ? theme.background : theme.foreground
                                    }

                                    MouseArea {
                                        id: indicatorHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.workspaceIndicatorStyle = modelData
                                    }
                                }
                            }
                        }

                        SettingSlider {
                            label: "Hyprland Border"
                            valueText: root.hyprlandBorderThickness + "px"
                            minimumText: "0px"
                            maximumText: "7px"
                            from: 0
                            to: 7
                            value: root.hyprlandBorderThickness
                            onMoved: root.hyprlandBorderThickness = Math.round(value)
                        }

                        SettingSlider {
                            label: "Gaps In"
                            valueText: root.hyprlandGapIn + "px"
                            minimumText: "0px"
                            maximumText: "20px"
                            from: 0
                            to: 20
                            value: root.hyprlandGapIn
                            onMoved: root.hyprlandGapIn = Math.round(value)
                        }

                        SettingSlider {
                            label: "Gaps Out"
                            valueText: root.hyprlandGapOut + "px"
                            minimumText: "0px"
                            maximumText: "20px"
                            from: 0
                            to: 20
                            value: root.hyprlandGapOut
                            onMoved: root.hyprlandGapOut = Math.round(value)
                        }

                        SettingSlider {
                            label: "Active Opacity"
                            valueText: Math.round(root.hyprlandActiveOpacity * 100) + "%"
                            minimumText: "0%"
                            maximumText: "100%"
                            from: 0
                            to: 1
                            stepSize: 0.05
                            value: root.hyprlandActiveOpacity
                            onMoved: root.hyprlandActiveOpacity = Math.round(value * 100) / 100
                        }

                        SettingSlider {
                            label: "Inactive Opacity"
                            valueText: Math.round(root.hyprlandInactiveOpacity * 100) + "%"
                            minimumText: "0%"
                            maximumText: "100%"
                            from: 0
                            to: 1
                            stepSize: 0.05
                            value: root.hyprlandInactiveOpacity
                            onMoved: root.hyprlandInactiveOpacity = Math.round(value * 100) / 100
                        }

                        SettingSlider {
                            label: "Window Rounding"
                            valueText: root.hyprlandRounding + "px"
                            minimumText: "0px"
                            from: 0
                            maximumText: "50px"
                            to: 50
                            value: root.hyprlandRounding
                            onMoved: root.hyprlandRounding = Math.round(value)
                        }

                        SettingSlider {
                            label: "Rounding Power"
                            valueText: root.hyprlandRoundingPower.toString()
                            minimumText: "0"
                            maximumText: "50"
                            from: 0
                            to: 50
                            value: root.hyprlandRoundingPower
                            onMoved: root.hyprlandRoundingPower = Math.round(value)
                        }

                        Text {
                            Layout.topMargin: 8
                            text: "Blur"
                            font.pixelSize: 14
                            font.bold: true
                            color: theme.foreground
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: ["Enabled", "Disabled"]

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    radius: root.barRadius
                                    property bool selected: root.hyprlandBlurEnabled === (modelData === "Enabled")
                                    color: selected ? theme.color5 : (blurChoiceHover.containsMouse ? Qt.darker(theme.background, 1.2) : "transparent")
                                    border.color: selected ? theme.color5 : theme.muted
                                    border.width: root.moduleBorderThickness

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 13
                                        color: parent.selected ? theme.background : theme.foreground
                                    }

                                    MouseArea {
                                        id: blurChoiceHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.hyprlandBlurEnabled = modelData === "Enabled"
                                    }
                                }
                            }
                        }

                        SettingSlider {
                            label: "Blur Passes"
                            valueText: root.hyprlandBlurPasses.toString()
                            minimumText: "0"
                            maximumText: "10"
                            from: 0
                            to: 10
                            value: root.hyprlandBlurPasses
                            onMoved: root.hyprlandBlurPasses = Math.round(value)
                        }

                        SettingSlider {
                            label: "Blur Size"
                            valueText: root.hyprlandBlurSize.toString()
                            minimumText: "0"
                            maximumText: "50"
                            from: 0
                            to: 50
                            value: root.hyprlandBlurSize
                            onMoved: root.hyprlandBlurSize = Math.round(value)
                        }

                        SettingSlider {
                            label: "Blur Vibrancy"
                            valueText: Math.round(root.hyprlandBlurVibrancy * 100) + "%"
                            minimumText: "0%"
                            maximumText: "100%"
                            from: 0
                            to: 1
                            stepSize: 0.05
                            value: root.hyprlandBlurVibrancy
                            onMoved: root.hyprlandBlurVibrancy = Math.round(value * 100) / 100
                        }

                    }

                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.barRadius
            color: "transparent"
            border.color: theme.muted
            border.width: root.popupBorderThickness
            z: 10
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: settingsPopup.close()
    }

    component SettingSlider: ColumnLayout {
        id: sliderRoot
        property string label
        property string valueText
        property string minimumText
        property string maximumText
        property real from: 0
        property real to: 1
        property real stepSize: 1
        property real value: 0
        signal moved(real value)

        Layout.fillWidth: true
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Text { text: sliderRoot.label; font.pixelSize: 13; color: theme.foreground }
            Item { Layout.fillWidth: true }
            Text { text: sliderRoot.valueText; font.pixelSize: 12; color: theme.muted }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 9
            Text { text: sliderRoot.minimumText; font.pixelSize: 10; color: theme.muted }

            Slider {
                id: slider
                Layout.fillWidth: true
                from: sliderRoot.from
                to: sliderRoot.to
                stepSize: sliderRoot.stepSize
                value: sliderRoot.value
                onMoved: sliderRoot.moved(value)

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: 4
                    radius: 2
                    color: Qt.darker(theme.muted, 1.2)
                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: theme.color5
                    }
                }

                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                    color: slider.pressed ? Qt.lighter(theme.color5, 1.2) : theme.color5
                    border.color: theme.background
                    border.width: 2
                }
            }

            Text { text: sliderRoot.maximumText; font.pixelSize: 10; color: theme.muted }
        }
    }
}
