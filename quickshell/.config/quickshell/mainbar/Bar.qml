// ═══════════════════════════════════════════════════════════════════════════════
// Bar - Main Status Bar
// ═══════════════════════════════════════════════════════════════════════════════
// The top bar containing: Arch logo, workspaces, Bluetooth, system resources,
// weather, recorder, notifications, volume, clock, and power button.
// Displayed on configured monitor(s) via barSettings.barMonitor.
//
// Required properties (passed from shell.qml):
//   theme, audio, bt, weather, stats, calendar
//   Various popup open/close signals
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io


Variants {
    model: barSettings.popupScreens()

        PanelWindow {
            id:     barWindow
            screen: modelData
            required property var modelData
            property bool settingsPopupOpen: false

            anchors {
                top:    barSettings.barPosition === "top"
                bottom: barSettings.barPosition === "bottom"
                left:   true
                right:  true
            }

            implicitHeight: 60
            color:          "transparent"
            exclusiveZone:  implicitHeight
            exclusionMode:  ExclusionMode.Normal

            margins { left: 10; right: 10; top: 10; bottom: 10 }

            Process {
                id: bluemanProc
                command: ["blueman-manager"]
                running: false
            }

        Rectangle {
            id:           barBackground
            anchors.fill: parent
            color:        "transparent"
            radius: barSettings.barRadius
            visible:      barSettings.loaded

            Rectangle {
                anchors.fill: parent
                color:        theme.background
                opacity:      barSettings.barOpacity
                radius: barSettings.barRadius
                border { color: theme.color2; width: barSettings.borderThickness }
            }

            RowLayout {
                anchors {
                    fill:         parent
                    leftMargin:   10
                    rightMargin:  10
                    topMargin:    10
                    bottomMargin: 10
                }
                spacing: 10

                // ── Arch Logo //
                Rectangle {
                    id:     archBtn
                    width:  40
                    height: 40
                    radius: barSettings.barRadius
                    color:  "transparent"
                    border { width: barSettings.borderThickness; color: hovered ? theme.muted : theme.color2 }

                    property bool hovered: false
                    property string archLogoPath: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/arch.png"
                    property int archLogoVersion: 0

                    FileView {
                        id: archLogoWatcher
                        path: Quickshell.env("HOME") + "/.config/quickshell/assets/arch.png"
                        watchChanges: true
                        onFileChanged: archBtn.archLogoVersion++
                    }

                    Image {
                        anchors.centerIn:  parent
                        width:             30
                        height:            30
                        source:            archBtn.archLogoPath + "?v=" + archBtn.archLogoVersion
                        smooth:            true
                        mipmap:            true
                        fillMode:          Image.PreserveAspectFit
                        sourceSize.width:  64
                        sourceSize.height: 65
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:    archBtn.hovered = true
                        onExited:     archBtn.hovered = false
                        onClicked:    { root.keybindsPopupOpen = !root.keybindsPopupOpen }
                    }
                }

                // ── Workspaces ────────────────────────────────────────────
                Rectangle {
                    id:     workspaceContainer
                    radius: barSettings.barRadius
                    color:  "transparent"
                    border { color: theme.color4; width: barSettings.borderThickness }

                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth:    workspaceRow.implicitWidth + 20
                    implicitHeight:   workspaceRow.implicitHeight + 15

                    Row {
                        id:               workspaceRow
                        spacing:          5
                        anchors.centerIn: parent

                        // ── Regular Workspaces (dynamic) ──────────────────
                        Repeater {
                            model: {
                                let maxId = 5
                                for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                                    const ws = Hyprland.workspaces.get(i)
                                    if (ws.id > maxId) maxId = ws.id
                                }
                                if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > maxId)
                                    maxId = Hyprland.focusedWorkspace.id
                                return maxId
                            }

                            Rectangle {
                                required property int index
                                property int workspaceId: index + 1
                                width:  barSettings.workspaceStyle === "dots" ? 25 : 25
                                height: barSettings.workspaceStyle === "dots" ? 10 : 25
                                radius: barSettings.workspaceStyle === "dots" ? 5 : barSettings.barRadius

                                property bool isActive: Hyprland.focusedWorkspace
                                    && Hyprland.focusedWorkspace.id === workspaceId

                                property bool hasWindows: {
                                    for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                                        const ws = Hyprland.workspaces.get(i)
                                        if (ws.id === workspaceId && ws.windowCount > 0)
                                            return true
                                    }
                                    return false
                                }

                                color:        isActive ? theme.color2 : (barSettings.workspaceStyle === "dots" ? (hasWindows ? Qt.darker(theme.background, 1.25) : theme.muted) : (hasWindows ? Qt.darker(theme.background, 1.25) : "transparent"))

                                Text {
                                    anchors.centerIn: parent
                                    visible:          barSettings.workspaceStyle !== "dots"
                                    text:             parent.workspaceId.toString()
                                    color:            parent.isActive ? theme.background : (parent.hasWindows ? theme.color4 : theme.muted)
                                    font.pixelSize:   14
                                    font.bold:        true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked: {
                                        if (Hyprland.usingLua) {
                                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.workspaceId + " })")
                                        } else {
                                            Hyprland.dispatch("workspace " + parent.workspaceId)
                                        }
                                    }
                                }
                            }
                        }

                    }
                }

                // ── Sidebar Trigger ───────────────────────────────────────
                Rectangle {
                    id:     sideBtn
                    width:  40
                    height: 40
                    radius: barSettings.barRadius
                    color:  "transparent"
                    border { width: barSettings.borderThickness; color: hovered ? theme.muted : theme.color4 }

                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text:           "󰀙"
                        font.pixelSize: 18
                        color:          sideBtn.hovered ? theme.foreground : theme.color4
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.sideWidgetOpen = !root.sideWidgetOpen
                        onContainsMouseChanged: {
                            sideBtn.hovered = containsMouse
                        }
                    }
                }

                // ── Settings ────────────────────────────────────────────
                Rectangle {
                    id:     settingsBtn
                    width:  40
                    height: 40
                    radius: barSettings.barRadius
                    color:  "transparent"
                    border { width: barSettings.borderThickness; color: hovered ? theme.muted : theme.color5 }

                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text:           "󰒓"
                        font.pixelSize: 18
                        color:          settingsBtn.hovered ? theme.foreground : theme.color5
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.settingsPopupOpen = !root.settingsPopupOpen
                        onContainsMouseChanged: {
                            settingsBtn.hovered = containsMouse
                        }
                    }
                }

                // ── Center Spacer ─────────────────────────────────────────
                Item { Layout.fillWidth: true }

                // ── Themes //──
                Rectangle {
                    id:     themesBtn
                    width:  40
                    height: 40
                    radius: barSettings.barRadius
                    color:  "transparent"
                    border { width: barSettings.borderThickness; color: hovered ? theme.muted : theme.color6 }

                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text:           "󰏘"
                        font.pixelSize: 18
                        color:          themesBtn.hovered ? theme.foreground : theme.color6
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.themesPopupOpen = !root.themesPopupOpen
                        onContainsMouseChanged: {
                            themesBtn.hovered = containsMouse
                        }
                    }
                }

                // ── Updates ──────────────────────────────────────────────
                Rectangle {
                    id:     updatesBtn
                    implicitWidth:  updatesRow.implicitWidth + 20
                    implicitHeight: 40
                    radius: barSettings.barRadius
                    color:  "transparent"
                    border { width: barSettings.borderThickness; color: updatesBtn.hovered ? theme.muted : (updates.updatesAvailable ? theme.color3 : theme.color4) }

                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false

                    Row {
                        id:               updatesRow
                        anchors.centerIn: parent
                        spacing:          6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           updates.updateIcon()
                            font.pixelSize: 14
                            color:          updatesBtn.hovered ? theme.foreground : updates.updateColor()
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           String(updates.updateCount)
                            font.pixelSize: 14
                            font.bold:      true
                            font.family:    "JetBrains Mono Nerd Font Mono"
                            color:          updates.updatesAvailable ? theme.color3 : theme.muted
                        }
                    }

                    MouseArea {
                        anchors.fill:     parent
                        hoverEnabled:     true
                        cursorShape:      Qt.PointingHandCursor
                        acceptedButtons:  Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                root.archUpdatePopupOpen = !root.archUpdatePopupOpen
                            } else {
                                updates.launchUpdate()
                            }
                        }

                        onContainsMouseChanged: {
                            updatesBtn.hovered = containsMouse
                        }
                    }
                }

                //─
                Recorder {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    Layout.alignment: Qt.AlignVCenter
                }

                // ── Notifications ─────────────────────────────────────────
                Item {
                    id:     notifButton
                    implicitWidth:  40
                    implicitHeight: 40

                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false

                    Rectangle {
                        id:           notifRect
                        anchors.fill: parent
                        color:        "transparent"
                        radius: barSettings.barRadius
                        border {
                            width: barSettings.borderThickness
                            color: notifButton.hovered ? theme.muted
                                 : notifs.hasUnread ? theme.color1
                                 : theme.color4
                        }

                        Text {
                            anchors.centerIn: parent
                            text:           notifs.notifIcon()
                            font.pixelSize: 18
                            color:          notifButton.hovered ? theme.foreground : notifs.notifColor()
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Rectangle {
                            visible: notifs.trackedCount > 0
                            width:   16
                            height:  16
                            radius:  8
                            color:   theme.color1
                            anchors.top:    parent.top
                            anchors.right: parent.right
                            anchors.topMargin:   -4
                            anchors.rightMargin: -4

                            Text {
                                anchors.centerIn: parent
                                text:             notifs.trackedCount > 9 ? "9+" : String(notifs.trackedCount)
                                color:            theme.background
                                font.pixelSize:   9
                                font.bold:        true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill:     parent
                        hoverEnabled:     true
                        cursorShape:      Qt.PointingHandCursor
                        acceptedButtons:  Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                notifs.clearAll()
                            } else {
                                root.notificationsPopupOpen = !root.notificationsPopupOpen
                            }
                        }

                        onContainsMouseChanged: {
                            notifButton.hovered = containsMouse
                        }
                    }
                }

                // ── Volume (Pipewire) ─────────────────────────────────────
                Item {
                    id:     volumeButton
                    implicitWidth:  74
                    implicitHeight: 40

                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id:           volumeRect
                        anchors.fill: parent
                        color:        "transparent"
                        radius: barSettings.barRadius
                        property bool hovered: false
                        border {
                            width: barSettings.borderThickness
                            color: hovered ? theme.muted : (audio.volumeMuted ? theme.color1 : theme.color4)
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:           audio.volumeIcon()
                                font.pixelSize: 18
                                color:          volumeRect.hovered ? theme.foreground : (audio.volumeMuted ? theme.color1 : theme.color2)
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:           Math.round(audio.volumeLevel * 100) + "%"
                                font.pixelSize: 14
                                font.bold:      true
                                font.family:    "JetBrains Mono Nerd Font Mono"
                                color:          theme.muted
                            }
                        }
                    }

                    MouseArea {
                        id:               volumeArea
                        anchors.fill:     parent
                        hoverEnabled:     true
                        cursorShape:      Qt.PointingHandCursor
                        acceptedButtons:  Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                audio.toggleMute()
                            } else {
                                root.volumePopupOpen = !root.volumePopupOpen
                            }
                        }

                        onWheel: wheel => {
                            const step  = 0.05
                            const delta = wheel.angleDelta.y > 0 ? step : -step
                            audio.setVolume(audio.volumeLevel + delta)
                        }

                        onContainsMouseChanged: {
                            volumeRect.hovered = containsMouse
                        }
                    }
                }

                // ── Clock //────
                Item {
                    id:     clockBtn
                    implicitWidth:  clockLabel.implicitWidth + 16
                    implicitHeight: 40
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        id:               clockLabel
                        anchors.centerIn: parent
                        color:            theme.muted
                        font.pixelSize:   14
                        font.bold:        true
                        font.family:      "JetBrains Mono Nerd Font Mono"
                        text:             root.clockTime

                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.calendarPopupOpen = !root.calendarPopupOpen
                        onContainsMouseChanged: {
                            clockLabel.color = containsMouse ? theme.color1 : theme.muted
                        }
                    }
                }

                // ── Power Button ──────────────────────────────────────────
                Rectangle {
                    width:            40
                    height:           40
                    radius: barSettings.barRadius
                    color:            root.powerMenuOpen ? theme.color1 : "transparent"
                    opacity:          powerBtnMouse.containsMouse ? 0.6 : 1.0
                    border { color: theme.color1; width: barSettings.borderThickness }
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text:             "\udb81\udc26"
                        color:            root.powerMenuOpen ? theme.background : theme.color1
                        font.pixelSize:   20
                    }

                        MouseArea {
                            id:               powerBtnMouse
                            anchors.fill:     parent
                            hoverEnabled:     true
                            cursorShape:      Qt.PointingHandCursor
                            onClicked:        root.togglePowerMenu()
                        }

                }
            }
        }

        // ── Salaat Widget (centered on screen, above bar) ─────────────
        Rectangle {
            id:     salaatBtn
            width:  200
            height: 40
            radius: barSettings.barRadius
            color:  "transparent"
            border { width: barSettings.borderThickness; color: hovered ? theme.muted : theme.color3 }
            clip:   true
            z: 10
            visible: barSettings.loaded

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter:   parent.verticalCenter

            property bool hovered: false

            Text {
                anchors.centerIn: parent
                text:             salaat._displayText || "Loading..."
                font.pixelSize:   14
                font.bold:        true
                font.family:      "JetBrains Mono Nerd Font Mono"
                color:            salaatBtn.hovered ? theme.foreground : theme.muted
                Behavior on color { ColorAnimation { duration: 120 } }
                elide:            Text.ElideRight
                width:            parent.width - 16
                clip:             true
                horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.salaatPopupOpen = !root.salaatPopupOpen
                onContainsMouseChanged: {
                    salaatBtn.hovered = containsMouse
                }
            }
        }
    }
}
