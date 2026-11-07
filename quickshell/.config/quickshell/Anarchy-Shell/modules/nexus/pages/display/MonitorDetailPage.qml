pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property string monitorName: nState.selectedMonitorName
    readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === root.monitorName) ?? null
    readonly property HyprlandMonitor hyprMonitor: root.screen ? Hypr.monitorFor(root.screen) : null
    readonly property var ipc: root.hyprMonitor?.lastIpcObject ?? null
    readonly property var brightnessMonitor: root.screen ? Brightness.getMonitorForScreen(root.screen) : null

    readonly property real currentScale: root.hyprMonitor?.scale ?? root.ipc?.scale ?? 1
    readonly property int currentTransform: root.ipc?.transform ?? 0
    readonly property string currentMode: {
        const w = root.hyprMonitor?.width ?? root.ipc?.width ?? root.screen?.width;
        const h = root.hyprMonitor?.height ?? root.ipc?.height ?? root.screen?.height;
        const r = root.ipc?.refreshRate;
        if (w && h && r)
            return `${w}x${h}@${r.toFixed(2)}Hz`;
        return "preferred";
    }
    readonly property int posX: root.hyprMonitor?.x ?? root.ipc?.x ?? 0
    readonly property int posY: root.hyprMonitor?.y ?? root.ipc?.y ?? 0
    readonly property int displayWidth: root.hyprMonitor?.width ?? root.ipc?.width ?? root.screen?.width ?? 0
    readonly property int displayHeight: root.hyprMonitor?.height ?? root.ipc?.height ?? root.screen?.height ?? 0

    // Orientation options, ordered to match Hyprland transforms (0 landscape, 1 portrait, 2 reverse landscape, 3 reverse portrait)
    readonly property list<MenuItem> orientationItems: [
        MenuItem {
            text: Tr.trCtx("Landscape", "display orientation")
        },
        MenuItem {
            text: Tr.trCtx("Portrait", "display orientation")
        },
        MenuItem {
            text: Tr.trCtx("Reverse landscape", "display orientation")
        },
        MenuItem {
            text: Tr.trCtx("Reverse portrait", "display orientation")
        }
    ]

    function applyMonitor(mode: string, scale: real, transform: int): void {
        if (!root.monitorName)
            return;
        const m = mode && mode.length > 0 ? mode : "preferred";
        const s = scale > 0 ? scale.toFixed(2) : "1";
        let cmd = `keyword monitor ${root.monitorName},${m},${root.posX}x${root.posY},${s}`;
        if (transform != null)
            cmd += `, transform, ${transform}`;
        Hypr.dispatch(cmd);
    }

    function resetMonitor(): void {
        if (!root.monitorName)
            return;
        Hypr.dispatch(`keyword monitor ${root.monitorName},preferred,auto,1`);
    }

    function disableMonitor(): void {
        if (!root.monitorName)
            return;
        Hypr.dispatch(`keyword monitor ${root.monitorName},disable`);
    }

    onScreenChanged: {
        if (!screen && monitorName.length > 0)
            nState.closeSubPage();
    }

    title: root.screen?.model?.length > 0 ? root.screen.model : (root.monitorName || Tr.tr("Display"))
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.medium
            text: Tr.tr("Changes apply instantly. Edit hyprmon.lua to make them permanent.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        // Actions
        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.large - parent.spacing
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: Math.round(root.cappedWidth * 0.7)
            spacing: Tokens.spacing.small

            ButtonBase {
                id: resetBtn

                fillWidth: true
                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3secondaryContainer
                inactiveOnColour: Colours.palette.m3onSecondaryContainer

                implicitWidth: resetLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: resetLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: root.resetMonitor()

                ColumnLayout {
                    id: resetLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "restart_alt"
                        color: resetBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.trCtx("Reset", "button")
                        color: resetBtn.onColour
                    }
                }
            }

            ButtonBase {
                id: disableBtn

                fillWidth: true
                shapeMorph: true
                isRound: true
                inactiveColour: Colours.palette.m3errorContainer
                inactiveOnColour: Colours.palette.m3onErrorContainer

                implicitWidth: disableLayout.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: disableLayout.implicitHeight + Tokens.padding.medium * 2

                onClicked: root.disableMonitor()

                ColumnLayout {
                    id: disableLayout

                    anchors.centerIn: parent
                    spacing: 0

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "monitor_off"
                        color: disableBtn.onColour
                        fontStyle: Tokens.font.icon.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.trCtx("Disable", "button")
                        color: disableBtn.onColour
                    }
                }
            }
        }

        // Information
        SectionHeader {
            first: true
            text: Tr.tr("Information")
        }

        InfoRow {
            first: true
            icon: "monitor"
            label: Tr.trCtx("Output", "display name")
            value: root.monitorName || Tr.trCtx("Unknown", "unknown display")
        }

        InfoRow {
            icon: "speaker_notes"
            label: Tr.trCtx("Model", "display model name")
            value: root.screen?.model || "—"
        }

        InfoRow {
            icon: "aspect_ratio"
            label: Tr.tr("Resolution")
            value: root.displayWidth > 0 ? `${root.displayWidth} × ${root.displayHeight}` : "—"
        }

        InfoRow {
            icon: "speed"
            label: Tr.tr("Refresh rate")
            // TRANSLATORS: %1 = refresh rate in hertz, Hz is a unit, leave it untranslated
            value: root.ipc?.refreshRate ? Tr.tr("%1 Hz").arg(Math.round(root.ipc.refreshRate)) : "—"
        }

        InfoRow {
            icon: "pin"
            label: Tr.tr("Position")
            value: `${root.posX}x${root.posY}`
        }

        InfoRow {
            last: true
            icon: "fullscreen"
            label: Tr.trCtx("Scale", "display scaling")
            value: `${Math.round(root.currentScale * 100)}%`
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
            value: root.brightnessMonitor?.brightness ?? 0
            enabled: root.brightnessMonitor != null
            onMoved: v => root.brightnessMonitor?.setBrightness(v)
        }

        // Display settings
        SectionHeader {
            text: Tr.tr("Display settings")
        }

        Variants {
            id: modeVariants

            model: root.ipc?.availableModes ?? []

            MenuItem {
                required property string modelData

                text: modelData
            }
        }

        SelectRow {
            first: true
            label: Tr.tr("Resolution")
            subtext: Tr.tr("Pixel size and refresh rate")
            menuItems: [preferredModeItem, ...modeVariants.instances]
            active: menuItems.find(i => i.text === root.currentMode) ?? preferredModeItem
            fallbackText: root.currentMode || Tr.trCtx("Preferred", "display resolution")
            fallbackIcon: "monitor"
            onSelected: item => root.applyMonitor(item === preferredModeItem ? "preferred" : item.text, root.currentScale, root.currentTransform)

            MenuItem {
                id: preferredModeItem

                text: Tr.trCtx("Preferred", "display resolution")
            }
        }

        StepperRow {
            label: Tr.trCtx("Scale", "display scaling")
            subtext: Tr.tr("Text and UI size on this display")
            value: Math.round(root.currentScale * 100)
            from: 50
            to: 300
            stepSize: 25
            onMoved: v => root.applyMonitor(root.currentMode, v / 100, root.currentTransform)
        }

        SelectRow {
            last: true
            label: Tr.tr("Orientation")
            subtext: Tr.tr("How the display is rotated")
            menuOnTop: true
            menuItems: root.orientationItems
            active: root.orientationItems[root.currentTransform] ?? root.orientationItems[0]
            onSelected: item => root.applyMonitor(root.currentMode, root.currentScale, root.orientationItems.indexOf(item))
        }
    }
}
