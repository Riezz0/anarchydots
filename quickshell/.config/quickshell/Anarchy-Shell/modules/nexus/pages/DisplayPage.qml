pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var activeBrightness: Brightness.getMonitor("active") ?? Brightness.monitors[0] ?? null

    title: Tr.tr("Display")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Displays
        SectionHeader {
            first: true
            text: Tr.tr("Displays")
        }

        ItemList {
            id: monitorList

            first: true
            last: true
            showList: true
            placeholderIcon: "monitor"
            placeholderText: Tr.tr("No displays detected")

            model: ScriptModel {
                values: [...Quickshell.screens].sort((a, b) => a.name.localeCompare(b.name))
            }

            delegate: StyledRect {
                id: monitorItem

                required property ShellScreen modelData
                required property int index

                readonly property var hyprMonitor: Hypr.monitorFor(modelData)
                readonly property var ipc: hyprMonitor?.lastIpcObject ?? null
                readonly property bool isFocused: hyprMonitor?.focused ?? false

                anchors.left: monitorList.list.contentItem.left
                anchors.right: monitorList.list.contentItem.right
                implicitHeight: monitorLayout.implicitHeight + monitorLayout.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                color: "transparent"

                StateLayer {
                    radius: Tokens.rounding.extraSmall
                    onClicked: {
                        root.nState.selectedMonitorName = monitorItem.modelData.name;
                        root.nState.openSubPage(1); // Monitor detail sub-page
                    }
                }

                RowLayout {
                    id: monitorLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: monitorIcon.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: monitorItem.isFocused ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            id: monitorIcon

                            anchors.centerIn: parent
                            text: "monitor"
                            color: monitorItem.isFocused ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.medium
                            fill: monitorItem.isFocused ? 1 : 0
                            animate: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: monitorItem.modelData.model && monitorItem.modelData.model.length > 0 ? monitorItem.modelData.model : monitorItem.modelData.name
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                const w = monitorItem.hyprMonitor?.width ?? monitorItem.modelData.width;
                                const h = monitorItem.hyprMonitor?.height ?? monitorItem.modelData.height;
                                const rate = Math.round(monitorItem.ipc?.refreshRate ?? 60);
                                const scale = Math.round((monitorItem.hyprMonitor?.scale ?? monitorItem.ipc?.scale ?? 1) * 100);
                                const res = `${w} × ${h}`;
                                let sub = `${res} @ ${rate} Hz • ${scale}%`;
                                if (monitorItem.isFocused)
                                    sub += ` • ${Tr.trCtx("Focused", "display state")}`;
                                return sub;
                            }
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            animate: true
                        }
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter
                        icon: "settings"
                        type: IconButton.Text
                        padding: Tokens.padding.small
                        inactiveOnColour: monitorItem.isFocused ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        label.fill: 0
                        onClicked: {
                            root.nState.selectedMonitorName = monitorItem.modelData.name;
                            root.nState.openSubPage(1); // Monitor detail sub-page
                        }
                    }
                }
            }
        }

        // Brightness
        SectionHeader {
            text: Tr.tr("Brightness")
        }

        SliderRow {
            first: true
            last: true
            icon: "brightness_auto"
            label: Tr.trCtx("Brightness", "display brightness")
            valueLabel: Strings.percentOne(value)
            value: root.activeBrightness?.brightness ?? 0
            enabled: root.activeBrightness != null
            onMoved: v => root.activeBrightness?.setBrightness(v)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            visible: root.activeBrightness != null && Brightness.monitors.length > 1
            text: Tr.tr("Adjust brightness for each display in its settings")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        // On-screen display
        SectionHeader {
            text: Tr.tr("On-screen display")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Show overlay")
            subtext: Tr.tr("Show brightness and volume popups on screen")
            checked: GlobalConfig.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show brightness")
            subtext: Tr.tr("Show the brightness overlay when changing brightness")
            checked: GlobalConfig.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        StepperRow {
            last: true
            label: Tr.tr("Auto-hide")
            // TRANSLATORS: ms is the millisecond unit, leave it untranslated
            subtext: Tr.tr("Time before the overlay hides (ms)")
            value: GlobalConfig.osd.hideDelay
            from: 500
            to: 5000
            stepSize: 500
            onMoved: v => GlobalConfig.osd.hideDelay = Math.round(v)
        }

        // Night light
        SectionHeader {
            text: Tr.tr("Night light")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Night light")
            subtext: Tr.tr("Reduce blue light for better sleep")
            checked: NightLight.enabled
            onToggled: NightLight.enabled = checked
        }

        StepperRow {
            last: true
            label: Tr.tr("Temperature")
            subtext: Tr.tr("Colour temperature in Kelvin (K)")
            value: NightLight.temperature
            from: 1000
            to: 6500
            stepSize: 100
            enabled: NightLight.enabled
            onMoved: v => NightLight.setTemperature(Math.round(v))
        }

    }
}
