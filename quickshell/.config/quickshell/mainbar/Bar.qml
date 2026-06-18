// ═══════════════════════════════════════════════════════════════════════════════
// Bar - Main Status Bar (DP-2)
// ═══════════════════════════════════════════════════════════════════════════════
// The top bar containing: Arch logo, workspaces, Bluetooth, system resources,
// weather, recorder, volume, clock, and power button.
// Displayed on DP-2 only.
//
// Required properties (passed from shell.qml):
//   theme, audio, bt, weather, stats, calendar
//   Various popup open/close signals
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Variants {
    model: Quickshell.screens.filter(screen => screen.name === "DP-2")

    PanelWindow {
        id:     barWindow
        screen: modelData
        required property var modelData

        anchors { top: true; left: true; right: true }

        implicitHeight: 60
        color:          "transparent"
        exclusiveZone:  implicitHeight
        exclusionMode:  ExclusionMode.Normal

        margins { left: 10; right: 10; top: 10; bottom: 10 }

        Rectangle {
            id:           barBackground
            anchors.fill: parent
            color:        theme.background
            opacity:      0.95
            radius: 5
            border { color: theme.color2; width: 2 }

            RowLayout {
                anchors {
                    fill:         parent
                    leftMargin:   10
                    rightMargin:  10
                    topMargin:    10
                    bottomMargin: 10
                }
                spacing: 10

                // ── Arch Logo ─────────────────────────────────────────────
                Rectangle {
                    id:     archBtn
                    width:  40
                    height: 40
                    radius: 5
                    color:  "transparent"
                    border { width: 2; color: theme.color2 }

                    property bool hovered: false

                    Image {
                        anchors.centerIn:  parent
                        width:             30
                        height:            30
                        source:            "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/arch.png"
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
                        onClicked:    { root.runCommand("bash /usr/local/bin/binds.sh") }
                    }

                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    onHoveredChanged: { border.color = hovered ? theme.muted : theme.color2 }
                }

                // ── Workspaces ────────────────────────────────────────────
                Rectangle {
                    id:     workspaceContainer
                    radius: 5
                    color:  "transparent"
                    border { color: theme.color4; width: 2 }

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
                                width:  25
                                height: 25
                                radius: 5

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

                                color:        isActive ? theme.color2 : (hasWindows ? Qt.darker(theme.background, 1.25) : "transparent")

                                Text {
                                    anchors.centerIn: parent
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

                        // ── Special Workspaces (Pyprland) ──────────────────
                        Repeater {
                            model: Hyprland.specialWorkspaces

                            Rectangle {
                                required property var modelData
                                property int workspaceId: modelData.id
                                property string workspaceName: modelData.name || ""
                                width:  30
                                height: 25
                                radius: 5

                                property bool isActive: Hyprland.focusedWorkspace
                                    && Hyprland.focusedWorkspace.id === workspaceId

                                property string specialIcon: {
                                    if (workspaceName.includes("term") || workspaceName.includes("kitty"))
                                        return ""
                                    if (workspaceName.includes("files") || workspaceName.includes("nautilus"))
                                        return ""
                                    if (workspaceName.includes("browser") || workspaceName.includes("firefox"))
                                        return ""
                                    if (workspaceName.includes("music") || workspaceName.includes("spotify"))
                                        return ""
                                    return ""
                                }

                                color:        isActive ? theme.color5 : "transparent"
                                border.color: isActive ? theme.color5 : Qt.darker(theme.muted, 1.2)
                                border.width: isActive ? 2 : 0

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text:             specialIcon
                                        color:            theme.foreground
                                        font.pixelSize:   14
                                        font.bold:        false
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text:             workspaceName.replace("special:", "").substring(0, 3).toUpperCase()
                                        color:            isActive ? theme.background : theme.muted
                                        font.pixelSize:   10
                                        font.bold:        true
                                        visible:          workspaceName.length > 0
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked: {
                                        Hyprland.dispatch("togglespecialworkspace " + workspaceName)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Bluetooth ────────────────────────────────────────────
                Item {
                    id:     btButton
                    width:  40
                    height: 40

                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id:           btRect
                        anchors.fill: parent
                        color:        "transparent"
                        radius: 5
                        border {
                            width: 2
                            color: theme.color2
                        }

                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text:           bt.btIcon()
                            font.pixelSize: 18
                            color:          bt.btColor()
                        }
                    }

                    MouseArea {
                        anchors.fill:     parent
                        hoverEnabled:     true
                        cursorShape:      Qt.PointingHandCursor
                        acceptedButtons:  Qt.LeftButton | Qt.RightButton

                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                bt.toggle()
                            } else {
                                root.btPopupOpen = !root.btPopupOpen
                            }
                        }

                        onContainsMouseChanged: {
                            btRect.border.color = containsMouse ? theme.muted : theme.color2
                        }
                    }
                }

                // ── System Resources ─────────────────────────────────────
                Rectangle {
                    id:     tempModule
                    width:  40
                    height: 40
                    radius: 5
                    color:  "transparent"
                    border { width: 2; color: theme.color2 }

                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text:           "󰍛"
                        font.pixelSize: 18
                        color:          tempModule.hovered ? Qt.lighter(theme.color4, 1.3) : theme.color4
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.tempPopupOpen = !root.tempPopupOpen
                        onContainsMouseChanged: {
                            tempModule.hovered = containsMouse
                            tempModule.border.color = containsMouse ? theme.muted : theme.color2
                        }
                    }

                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                // ── Weather ──────────────────────────────────────────────
                Rectangle {
                    id:     weatherBtn
                    radius: 5
                    color:  "transparent"
                    border { width: 2; color: theme.color4 }

                    Layout.alignment: Qt.AlignVCenter
                    implicitHeight:   40
                    implicitWidth:    weatherRow.implicitWidth + 28

                    property bool hovered: false

                    Row {
                        id:               weatherRow
                        anchors.centerIn: parent
                        spacing:          6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           weather.weatherIconText()
                            font.pixelSize: 14
                            color:          theme.color4
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           weather.loaded ? weather.tempDisplay() : "--"
                            font.pixelSize: 14
                            font.bold:      true
                            font.family:    "JetBrains Mono Nerd Font Mono"
                            color:          theme.muted
                        }
                    }

                    MouseArea {
                        anchors.fill:    parent
                        hoverEnabled:    true
                        cursorShape:     Qt.PointingHandCursor
                        onClicked:       root.weatherPopupOpen = !root.weatherPopupOpen
                        onContainsMouseChanged: {
                            weatherBtn.hovered = containsMouse
                            weatherBtn.border.color = containsMouse ? theme.muted : theme.color4
                        }
                    }

                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                // ── Left Spacer ───────────────────────────────────────────
                Item { Layout.fillWidth: true }

                // ── Right Spacer ──────────────────────────────────────────
                Item { Layout.fillWidth: true }

                // ── Themes ───────────────────────────────────────────────
                Rectangle {
                    id:     themesBtn
                    width:  40
                    height: 40
                    radius: 5
                    color:  "transparent"
                    border { width: 2; color: theme.color6 }

                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false

                    Text {
                        anchors.centerIn: parent
                        text:           "󰔉"
                        font.pixelSize: 18
                        color:          theme.color6
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.themesPopupOpen = !root.themesPopupOpen
                        onContainsMouseChanged: {
                            themesBtn.hovered = containsMouse
                            themesBtn.border.color = containsMouse ? theme.muted : theme.color6
                        }
                    }

                    Behavior on border.color { ColorAnimation { duration: 120 } }
                }

                // ── Recorder ──────────────────────────────────────────────
                Recorder {
                    Layout.alignment: Qt.AlignVCenter
                }

                // ── Volume (Pipewire) ─────────────────────────────────────
                Item {
                    id:     volumeButton
                    width:  74
                    height: 40

                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        id:           volumeRect
                        anchors.fill: parent
                        color:        "transparent"
                        radius: 5
                        border {
                            width: 2
                            color: audio.volumeMuted ? theme.color1 : theme.color4
                        }

                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text:           audio.volumeIcon()
                                font.pixelSize: 18
                                color:          audio.volumeMuted ? theme.color1 : theme.color2
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
                            volumeRect.border.color = containsMouse
                                ? theme.muted
                                : (audio.volumeMuted ? theme.color1 : theme.color4)
                        }
                    }
                }

                // ── Clock ─────────────────────────────────────────────────
                Item {
                    id:     clockBtn
                    width:  clockLabel.implicitWidth + 16
                    height: 40
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
                    radius: 5
                    color:            root.powerMenuOpen ? theme.color1 : Qt.darker(theme.background, 0.8)
                    border { color: theme.color1; width: 2 }
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text:             "\udb81\udc26"
                        color:            root.powerMenuOpen ? theme.background : theme.color1
                        font.pixelSize:   20
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    root.togglePowerMenu()
                    }
                }
            }
        }

        // ── Salaat Widget (fixed center on screen) ──────────────────────
        Rectangle {
            id:     salaatBtn
            width:  200
            height: 40
            radius: 5
            color:  "transparent"
            border { width: 2; color: theme.color3 }

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top:              parent.top
            anchors.topMargin:        10

            property bool hovered: false

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left:           parent.left
                anchors.leftMargin:     8
                text:             salaat._displayText || "Loading..."
                font.pixelSize:   14
                font.bold:        true
                font.family:      "JetBrains Mono Nerd Font Mono"
                color:            theme.muted
                elide:            Text.ElideRight
                width:            parent.width - 16
                clip:             true
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.salaatPopupOpen = !root.salaatPopupOpen
                onContainsMouseChanged: {
                    salaatBtn.hovered = containsMouse
                    salaatBtn.border.color = containsMouse ? theme.muted : theme.color3
                }
            }

            Behavior on border.color { ColorAnimation { duration: 120 } }
        }
    }
}