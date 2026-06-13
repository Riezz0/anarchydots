// Import required Qt modules
import QtQuick                            // Core QML types
import QtQuick.Controls                   // UI controls like buttons, text inputs
import QtQuick.Layouts                    // Layout system for arranging items
import Quickshell.Services.SystemTray     // System Tray Support
import Quickshell                         // Core Quickshell functionality
import Quickshell.Io                      // Input/output operations (processes, files)
import Quickshell.Hyprland                // Hyprland window manager integration
import Quickshell.Wayland                 // Wayland protocol support
import Quickshell.DBusMenu                // Required to unpack app dropdown menus
import Quickshell.Services.Pipewire       // Add this to your imports
import "."                                // Import local directory files

ShellRoot {
    id: root

    // ── Properties ────────────────────────────────────────────────────────────
    property bool   powerMenuOpen:  false
    property bool   salaatHovered:  false
    property string salaatText:     "Loading..."
    property string salaatTooltip:  ""
    property var    salaatPrayers:  []
    property bool   volumePopupOpen: false
// ── Audio (Pipewire) ─────────────────────────────────────────────────────
readonly property var  audioSink:   Pipewire.defaultAudioSink
readonly property real volumeLevel: root.audioSink && root.audioSink.audio ? root.audioSink.audio.volume : 0
readonly property bool volumeMuted: root.audioSink && root.audioSink.audio ? root.audioSink.audio.muted : false

PwObjectTracker {
    objects: root.audioSink ? [root.audioSink] : []
}

function volumeIcon() {
    if (root.volumeMuted)   return "󰝟"
    if (root.volumeLevel <= 0)   return "󰖁"
    if (root.volumeLevel < 0.34) return "󰕿"
    if (root.volumeLevel < 0.67) return "󰖀"
    return "󰕾"
}

function setVolume(vol) {
    if (!root.audioSink || !root.audioSink.audio) return
    const clamped = Math.max(0, Math.min(1, vol))
    root.audioSink.audio.volume = clamped
    if (clamped > 0 && root.audioSink.audio.muted)
        root.audioSink.audio.muted = false
}

function toggleMute() {
    if (!root.audioSink || !root.audioSink.audio) return
    root.audioSink.audio.muted = !root.audioSink.audio.muted
}
    // ── Theme ─────────────────────────────────────────────────────────────────
    Theme { id: theme }

    // ── Functions ─────────────────────────────────────────────────────────────
    function togglePowerMenu() { powerMenuOpen = !powerMenuOpen }
    function closePowerMenu()  { powerMenuOpen = false }

    function runCommand(cmd) {
        powerProc.command = ["sh", "-c", cmd]
        powerProc.running = true
        closePowerMenu()
    }

    // ── Processes ─────────────────────────────────────────────────────────────
    Process {
        id:      powerProc
        running: false
    }

    Process {
        id:      salaatProc
        command: ["python3", "/usr/local/bin/salaat.py"]

        stdout: SplitParser {
            onRead: line => {
                if (!line.trim()) return
                try {
                    const result = JSON.parse(line)
                    if (result.text)    root.salaatText    = result.text
                    if (result.tooltip) root.salaatTooltip = result.tooltip
                } catch (e) {}
            }
        }
    }

    // ── Timers ────────────────────────────────────────────────────────────────
    Timer {
        interval:         1000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: { if (!salaatProc.running) salaatProc.running = true }
    }

    Timer {
        interval: 1000
        running:  true
        repeat:   true
        onTriggered: {
            clockLabel.text = Qt.formatDateTime(new Date(), "hh:mm")
        }
    }

    // ── Global Shortcut ───────────────────────────────────────────────────────
    GlobalShortcut {
        name:        "powerMenuToggle"
        description: "Toggle the Quickshell power menu"
        onPressed:   root.togglePowerMenu()
    }

    // ── Bar (DP-2 only) ───────────────────────────────────────────────────────
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
                radius:       0
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
                        radius: 0
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
                        radius: 0
                        color:  "transparent"
                        border { color: theme.color4; width: 2 }

                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth:    workspaceRow.implicitWidth + 20
                        implicitHeight:   workspaceRow.implicitHeight + 15

                        Row {
                            id:               workspaceRow
                            spacing:          5
                            anchors.centerIn: parent

                            Repeater {
                                model: Hyprland.workspaces

                                Rectangle {
                                    required property int index
                                    width:  25
                                    height: 25
                                    radius: 0

                                    property var ws: {
                                        for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                                            const workspace = Hyprland.workspaces.get(i)
                                            if (workspace.id === index + 1)
                                                return workspace
                                        }
                                        return null
                                    }

                                    property bool isActive: Hyprland.focusedWorkspace
                                        && Hyprland.focusedWorkspace.id === (index + 1)

                                    color:        ws ? Qt.darker(theme.background, 1.25) : "transparent"
                                    border.color: ws ? theme.muted : Qt.darker(theme.muted, 1.2)
                                    border.width: 0
                                    opacity:      1

                                    Text {
                                        anchors.centerIn: parent
                                        text:             parent.isActive ? "󰮯" : ""
                                        color:            parent.isActive ? theme.color2 : theme.color4
                                        font.pixelSize:   18
                                        font.bold:        false
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked: {
                                            const workspaceId = parent.index + 1
                                            if (parent.ws) {
                                                parent.ws.activate()
                                            } else if (Hyprland.usingLua) {
                                                Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspaceId + " })")
                                            } else {
                                                Hyprland.dispatch("workspace " + workspaceId)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Left Spacer ───────────────────────────────────────────
                    Item { Layout.fillWidth: true }

                    // ── Quran ─────────────────────────────────────────────────
                    Item {
                        id:     quranButton
                        width:  40
                        height: 40

                        Rectangle {
                            id:           quranRect
                            anchors.fill: parent
                            color:        "transparent"
                            radius:       0
                            border { width: 2; color: theme.color4 }

                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing:          4

                                Text {
                                    text:           ""
                                    font.pixelSize: 20
                                    color:          theme.color2
                                }
                            }
                        }

                        MouseArea {
                            id:           quranArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: { root.runCommand("bash /usr/local/bin/quranwbw.sh") }
                            onContainsMouseChanged: {
                                quranRect.border.color = containsMouse ? theme.muted : theme.color4
                            }
                        }
                    }

                    // ── Salaat Times ──────────────────────────────────────────
                    Rectangle {
                        id:     salaatModule
                        radius: 0
                        color:  "transparent"
                        border { width: 2; color: theme.color3 }

                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight:   40
                        implicitWidth:    salaatLabel.implicitWidth + 20

                        property bool salaatHovered: false

                        Text {
                            id:               salaatLabel
                            anchors.centerIn: parent
                            text:             root.salaatText
                            color:            theme.muted
                            font.pixelSize:   14
                            font.family:      "JetBrainsMonoNF-Propo"
                            font.bold:        false
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: { salaatModule.hovered = true; root.salaatHovered = true  }
                            onExited:  { salaatModule.hovered = false; root.salaatHovered = false }
                        }

                        ToolTip.visible: hovered
                        ToolTip.text:    root.salaatTooltip
                        ToolTip.delay:   0
                    }
                    // ── Sunnan ────────────────────────────────────────────────
                    Item {
                        id:     sunnanButton
                        width:  40
                        height: 40

                        Rectangle {
                            id:           sunnanRect
                            anchors.fill: parent
                            color:        "transparent"
                            radius:       0
                            border { width: 2; color: theme.color4 }

                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing:          4

                                Text {
                                    text:           "󱛉"
                                    font.pixelSize: 20
                                    color:          theme.color2
                                }
                            }
                        }

                        MouseArea {
                            id:           sunnanArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: { root.runCommand("bash /usr/local/bin/sunnah.sh") }
                            onContainsMouseChanged: {
                                sunnanRect.border.color = containsMouse ? theme.muted : theme.color4
                            }
                        }
                    }

                    // ── Right Spacer ──────────────────────────────────────────
                    Item { Layout.fillWidth: true }

                    // ── Themer ────────────────────────────────────────────────
                    Item {
                        id:     themerButton
                        width:  40
                        height: 40

                        Rectangle {
                            id:           themerRect
                            anchors.fill: parent
                            color:        "transparent"
                            radius:       0
                            border { width: 2; color: theme.color4 }

                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors.centerIn: parent
                                spacing:          4

                                Text {
                                    text:           ""
                                    font.pixelSize: 20
                                    color:          theme.color2
                                }
                            }
                        }

                        MouseArea {
                            id:           themerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: { root.runCommand("bash /usr/local/bin/themer.sh") }
                            onContainsMouseChanged: {
                                themerRect.border.color = containsMouse ? theme.muted : theme.color2
                            }
                        }
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
        radius:       0
        border {
            width: 2
            color: root.volumeMuted ? theme.color1 : theme.color4
        }

        Behavior on border.color { ColorAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           root.volumeIcon()
                font.pixelSize: 18
                color:          root.volumeMuted ? theme.color1 : theme.color2
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           Math.round(root.volumeLevel * 100) + "%"
                font.pixelSize: 13
                font.bold:      true
                font.family:    "JetBrainsMonoNF-Propo"
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
                root.toggleMute()
            } else {
                root.volumePopupOpen = !root.volumePopupOpen
            }
        }

        onWheel: wheel => {
            const step  = 0.05
            const delta = wheel.angleDelta.y > 0 ? step : -step
            root.setVolume(root.volumeLevel + delta)
        }

        onContainsMouseChanged: {
            volumeRect.border.color = containsMouse
                ? theme.muted
                : (root.volumeMuted ? theme.color1 : theme.color4)
        }
    }

}
                    // ── Clock ─────────────────────────────────────────────────
                    Text {
                        id:               clockLabel
                        color:            theme.muted
                        font.pixelSize:   14
                        font.bold:        true
                        font.family:      "JetBrainsMonoNF-Propo"
                        Layout.alignment: Qt.AlignVCenter
                        text:             Qt.formatDateTime(new Date(), "hh:mm")
                    }

                    // ── Power Button ──────────────────────────────────────────
                    Rectangle {
                        width:            40
                        height:           40
                        radius:           0
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
        }
    }
// ── Volume Popup (DP-2) ────────────────────────────────────────────────────
Variants {
    model: Quickshell.screens.filter(screen => screen.name === "DP-2")

    PanelWindow {
        screen:  modelData
        visible: root.volumePopupOpen
        required property var modelData

        anchors { top: true; bottom: true; left: true; right: true }

        color:     "transparent"
        focusable: root.volumePopupOpen

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.volumePopupOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked:    root.volumePopupOpen = false
        }

        Rectangle {
            id: volumePanel
            anchors.top:        parent.top
            anchors.horizontalCenter:  parent.horizontalCenter
            anchors.topMargin:  2
            width:    260
            implicitHeight: volumeColumn.implicitHeight + 28
            height:   implicitHeight
            radius:   0
            color:    theme.background
            opacity:  0.98
            border { width: 2; color: theme.color2 }

            MouseArea {
                anchors.fill: parent
                onClicked:    mouse => mouse.accepted = true
            }

            ColumnLayout {
                id: volumeColumn
                anchors.fill:    parent
                anchors.margins: 14
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text:           root.volumeIcon()
                        font.pixelSize: 22
                        color:          root.volumeMuted ? theme.color1 : theme.color2
                    }

                    Text {
                        text:      "Volume"
                        color:     theme.foreground
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text:        Math.round(root.volumeLevel * 100) + "%"
                        color:       theme.muted
                        font.pixelSize: 16
                        font.bold:   true
                        font.family: "JetBrainsMonoNF-Propo"
                    }
                }

                // Slider
                Rectangle {
                    id:     sliderTrack
                    Layout.fillWidth: true
                    implicitHeight: 14
                    radius: 0
                    color:  Qt.darker(theme.background, 1.3)
                    border { width: 1; color: theme.color4 }

                    Rectangle {
                        anchors {
                            left:   parent.left
                            top:    parent.top
                            bottom: parent.bottom
                        }
                        width:  parent.width * Math.min(Math.max(root.volumeLevel, 0), 1)
                        radius: 0
                        color:  root.volumeMuted ? theme.muted : theme.color2

                        Behavior on width { NumberAnimation { duration: 80 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onPressed:         mouse => root.setVolume(mouse.x / width)
                        onPositionChanged: mouse => { if (pressed) root.setVolume(mouse.x / width) }
                    }
                }

                // Output device name
                Text {
                    text:    root.audioSink
                                 ? (root.audioSink.description || root.audioSink.name)
                                 : "No output device"
                    color:   theme.muted
                    font.pixelSize: 11
                    elide:   Text.ElideRight
                    Layout.fillWidth: true
                }

                // Actions
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 0
                        color:  root.volumeMuted ? theme.color1 : "transparent"
                        border { width: 1; color: theme.color4 }

                        Text {
                            anchors.centerIn: parent
                            text:  root.volumeMuted ? "Unmute" : "Mute"
                            color: root.volumeMuted ? theme.background : theme.color2
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    root.toggleMute()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 0
                        color:  "transparent"
                        border { width: 1; color: theme.color4 }

                        Text {
                            anchors.centerIn: parent
                            text:  "Mixer"
                            color: theme.color2
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                root.volumePopupOpen = false
                                root.runCommand("bash /usr/local/bin/pulse.sh")
                            }
                        }
                    }
                }
            }
        }
    }
}
    // ── Power Menu Overlay (all screens) ──────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            screen:  modelData
            visible: root.powerMenuOpen
            required property var modelData

            anchors { top: true; bottom: true; left: true; right: true }

            color:    "transparent"
            focusable: root.powerMenuOpen

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.powerMenuOpen
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

            // Dim backdrop
            Rectangle {
                anchors.fill: parent
                color:        Qt.rgba(theme.background.r, theme.background.g, theme.background.b, 0.72)

                MouseArea {
                    anchors.fill: parent
                    onClicked:    root.closePowerMenu()
                }
            }

            // Dialog
            Item {
                anchors.fill: parent
                focus:        root.powerMenuOpen
                Keys.onEscapePressed: root.closePowerMenu()

                Rectangle {
                    anchors.centerIn: parent
                    width:        Math.min(420, parent.width - 48)
                    height:       powerColumn.implicitHeight + 40
                    radius:       0
                    color:        theme.background
                    border { color: theme.color2; width: 2 }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:    mouse => mouse.accepted = true
                    }

                    ColumnLayout {
                        id:               powerColumn
                        anchors.centerIn: parent
                        spacing:          22

                        Text {
                            text:             "Power Menu"
                            color:            theme.foreground
                            font.pixelSize:   20
                            font.bold:        true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        RowLayout {
                            spacing:          20
                            Layout.alignment: Qt.AlignHCenter

                            PowerButton {
                                icon:        "󰐥"
                                label:       "Shutdown"
                                bgColor:     theme.color1
                                textColor:   theme.background
                                onActivated: root.runCommand("systemctl poweroff")
                            }

                            PowerButton {
                                icon:        "󰜉"
                                label:       "Reboot"
                                bgColor:     theme.color2
                                textColor:   theme.background
                                onActivated: root.runCommand("systemctl reboot")
                            }

                            PowerButton {
                                icon:        "󰍀"
                                label:       "Lock"
                                bgColor:     theme.color4
                                textColor:   theme.background
                                onActivated: root.runCommand("hyprlock")
                            }
                        }

                        Rectangle {
                            width:            90
                            height:           32
                            radius:           0
                            color:            theme.color1
                            Layout.alignment: Qt.AlignHCenter

                            Text {
                                anchors.centerIn: parent
                                text:             "Cancel"
                                color:            theme.background
                                font.bold:        true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    root.closePowerMenu()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── PowerButton Component ─────────────────────────────────────────────────
    component PowerButton: ColumnLayout {
        id: powerButtonRoot

        property string icon
        property string label
        property color  bgColor
        property color  textColor

        signal activated()

        spacing: 8

        Rectangle {
            width:            58
            height:           58
            radius:           0
            color:            powerButtonRoot.bgColor
            Layout.alignment: Qt.AlignHCenter

            Text {
                anchors.centerIn: parent
                text:             powerButtonRoot.icon
                font.pixelSize:   40
                color:            powerButtonRoot.textColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape:  Qt.PointingHandCursor
                hoverEnabled: true
                onClicked:    powerButtonRoot.activated()
            }
        }

        Text {
            text:             powerButtonRoot.label
            color:            powerButtonRoot.textColor
            font.pixelSize:   11
            font.bold:        true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

