pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Apply a Hyprland value: persist to Anarchy-Shell's own file
    // (~/.config/anarchy-shell/hyprland.json, section "hyprland"), then let
    // patch-look.sh write it through to every theme's hyprlook + look.lua and
    // reload. Never look.lua directly — theme switches regenerate it. No
    // live dispatch: `hyprctl keyword` syntax fails on Lua-based configs.
    function applyHypr(hyprKey: string, value: var, dispatchKey: string): void {
        const home = Quickshell.env("HOME");
        const shellJson = `${home}/.config/anarchy-shell/hyprland.json`;
        patchLook.exec(["bash", "-c", `mkdir -p '${home}/.config/anarchy-shell' && jq --argjson v '${String(value)}' --arg k '${hyprKey}' '.hyprland[$k] = $v' '${shellJson}' > '${shellJson}.tmp' && mv '${shellJson}.tmp' '${shellJson}' && bash '${home}/.config/.hypr-themes/patch-look.sh' --sync-all && hyprctl reload`]);
    }

    title: Tr.tr("Wallpaper & style")

    Item {
        // Non-visual host for the look.lua patch process so it can live
        // inside the layout root without breaking the contentChild chain.
        Process {
            id: patchLook
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        ClipRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.tr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            WallpaperImpl {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: Tr.tr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "palette"
                text: Tr.tr("Colours")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3) // Colours page
            }
        }

        ToggleRow {
            first: true
            text: Tr.tr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Transparency")
            // TRANSLATORS: %1/%2 = opacity values from 0 to 1 for the base surface and layered surfaces
            subtext: Tr.tr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        SectionHeader {
            text: Tr.tr("Frame")
        }

        StepperRow {
            first: true
            label: Tr.tr("Thickness")
            subtext: Tr.tr("Border thickness around sidebars, drawers and the bar")
            value: Config.border.thickness
            from: Config.border.minThickness
            to: 60
            stepSize: 1
            onMoved: v => GlobalConfig.border.thickness = Math.round(v)
        }

        StepperRow {
            label: Tr.tr("Rounding")
            subtext: Tr.tr("Corner rounding of the shell frame")
            value: Config.border.rounding
            from: 0
            to: 80
            stepSize: 1
            onMoved: v => GlobalConfig.border.rounding = Math.round(v)
        }

        StepperRow {
            last: true
            label: Tr.tr("Smoothing")
            subtext: Tr.tr("Corner smoothing of the shell frame")
            value: Config.border.smoothing
            from: 0
            to: 80
            stepSize: 1
            onMoved: v => GlobalConfig.border.smoothing = Math.round(v)
        }

        // Hyprland — live dispatch, persisted to Anarchy-Shell's own
        // ~/.config/caelestia/shell.json ("hyprland" section). patch-look.sh
        // (run on every theme switch) prefers these values over Anarchy-Bar's
        // bar.json, so they survive theme changes.
        SectionHeader {
            text: Tr.tr("Hyprland")
        }

        StepperRow {
            first: true
            label: Tr.tr("Window rounding")
            subtext: Tr.tr("Corner rounding for tiled and floating windows")
            value: Hypr.options["decoration:rounding"] ?? 10
            from: 0
            to: 40
            stepSize: 1
            onMoved: v => root.applyHypr("rounding", v, "decoration:rounding")
        }

        StepperRow {
            label: Tr.tr("Border size")
            subtext: Tr.tr("Window border thickness")
            value: Hypr.options["general:border_size"] ?? 2
            from: 0
            to: 10
            stepSize: 1
            onMoved: v => root.applyHypr("borderSize", v, "general:border_size")
        }

        StepperRow {
            label: Tr.tr("Gaps in")
            subtext: Tr.tr("Inner window gaps")
            value: Hypr.options["general:gaps_in"] ?? 5
            from: 0
            to: 40
            stepSize: 1
            onMoved: v => root.applyHypr("gapsIn", v, "general:gaps_in")
        }

        StepperRow {
            label: Tr.tr("Gaps out")
            subtext: Tr.tr("Outer screen-edge gaps")
            value: Hypr.options["general:gaps_out"] ?? 5
            from: 0
            to: 60
            stepSize: 1
            onMoved: v => root.applyHypr("gapsOut", v, "general:gaps_out")
        }

        StepperRow {
            label: Tr.tr("Blur size")
            subtext: Tr.tr("Hyprland background blur size")
            value: Hypr.options["decoration:blur:size"] ?? 8
            from: 1
            to: 30
            stepSize: 1
            onMoved: v => root.applyHypr("blurSize", v, "decoration:blur:size")
        }

        StepperRow {
            label: Tr.tr("Blur passes")
            subtext: Tr.tr("Hyprland background blur passes")
            value: Hypr.options["decoration:blur:passes"] ?? 3
            from: 1
            to: 12
            stepSize: 1
            onMoved: v => root.applyHypr("blurPasses", v, "decoration:blur:passes")
        }

        // The opacity meters keep their own drag state — binding straight to
        // Hypr.options snapped them back to 100% until the option poll caught
        // up with the dispatch.
        SliderRow {
            id: activeOpacityRow

            property real current: Hypr.options["decoration:active_opacity"] ?? 1

            label: Tr.tr("Active opacity")
            valueLabel: Strings.percentOne(current)
            value: current
            onMoved: v => {
                current = v;
                root.applyHypr("activeOpacity", v, "decoration:active_opacity");
            }
        }

        SliderRow {
            id: inactiveOpacityRow

            property real current: Hypr.options["decoration:inactive_opacity"] ?? 1

            last: true
            label: Tr.tr("Inactive opacity")
            valueLabel: Strings.percentOne(current)
            value: current
            onMoved: v => {
                current = v;
                root.applyHypr("inactiveOpacity", v, "decoration:inactive_opacity");
            }
        }
    }
}
