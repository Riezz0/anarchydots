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
    property bool   volumePopupOpen: false
    property string clockTime:      Qt.formatDateTime(new Date(), "hh:mm:ss")
// ── Audio (Pipewire) ─────────────────────────────────────────────────────
readonly property var  audioSink:   Pipewire.defaultAudioSink
readonly property real volumeLevel: root.audioSink && root.audioSink.audio ? root.audioSink.audio.volume : 0
readonly property bool volumeMuted: root.audioSink && root.audioSink.audio ? root.audioSink.audio.muted : false
property bool btPopupOpen: false
property bool weatherPopupOpen: false
property bool calendarPopupOpen: false
property var calendarDate: new Date()
property string gpuTemp:     "GPU: --"
property string cpuTemp:     "CPU: --"

function daysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate()
}

function firstDayOfMonth(year, month) {
    return new Date(year, month, 1).getDay()
}

function calendarMonthName() {
    const months = ["January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"]
    return months[calendarDate.getMonth()] + " " + calendarDate.getFullYear()
}

function prevMonth() {
    var d = new Date(calendarDate)
    d.setMonth(d.getMonth() - 1)
    calendarDate = d
}

function nextMonth() {
    var d = new Date(calendarDate)
    d.setMonth(d.getMonth() + 1)
    calendarDate = d
}

function goToToday() {
    calendarDate = new Date()
}

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

    // ── Bluetooth ────────────────────────────────────────────────────────────
    Bluetooth { id: bt }

    // ── Weather ──────────────────────────────────────────────────────────────
    Weather { id: weather }

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
        id:      gpuTempProc
        command: ["bash", "/usr/local/bin/gpu.sh"]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim()
                if (trimmed) root.gpuTemp = "GPU: " + trimmed
            }
        }
    }

    Process {
        id:      cpuTempProc
        command: ["bash", "/usr/local/bin/cpu.sh"]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim()
                if (trimmed) root.cpuTemp = "CPU: " + trimmed
            }
        }
    }


    // ── Timers ────────────────────────────────────────────────────────────────
    Timer {
        interval:         1000
        running:  true
        repeat:   true
        onTriggered: {
            root.clockTime = Qt.formatDateTime(new Date(), "hh:mm:ss")
        }
    }

    Timer {
        interval:         3000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: {
            if (!gpuTempProc.running) gpuTempProc.running = true
            if (!cpuTempProc.running) cpuTempProc.running = true
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
                                    // Find the highest workspace ID that has windows or is focused
                                    let maxId = 5
                                    for (let i = 0; i < Hyprland.workspaces.count; ++i) {
                                        const ws = Hyprland.workspaces.get(i)
                                        if (ws.id > maxId) maxId = ws.id
                                    }
                                    // Also check focused workspace
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

                                    // Icons for different special workspaces
                                    property string specialIcon: {
                                        if (workspaceName.includes("term") || workspaceName.includes("kitty"))
                                            return ""  // Terminal
                                        if (workspaceName.includes("files") || workspaceName.includes("nautilus"))
                                            return ""  // Files
                                        if (workspaceName.includes("browser") || workspaceName.includes("firefox"))
                                            return ""  // Browser
                                        if (workspaceName.includes("music") || workspaceName.includes("spotify"))
                                            return ""  // Music
                                        return ""  // Default special workspace icon
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

                    // ── Temperature ──────────────────────────────────────────
                    Rectangle {
                        id:     tempModule
                        radius: 5
                        color:  "transparent"
                        border { width: 2; color: theme.color4 }

                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight:   40
                        implicitWidth:    tempColumn.implicitWidth + 20

                        Column {
                            id:               tempColumn
                            anchors.centerIn: parent
                            spacing:          2

                            Text {
                                text:           root.gpuTemp
                                font.pixelSize: 11
                                font.bold:      true
                                font.family:    "JetBrains Mono Nerd Font Mono"
                                color:          theme.color2
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text:           root.cpuTemp
                                font.pixelSize: 11
                                font.bold:      true
                                font.family:    "JetBrains Mono Nerd Font Mono"
                                color:          theme.color3
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
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
                                font.pixelSize: 18
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
            anchors.topMargin:  10
            width:    500
            implicitHeight: volumeColumn.implicitHeight + 28
            height:   implicitHeight
            radius: 5
            color:    theme.background
            opacity:  0.90
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
                        font.pixelSize: 14
                        font.bold:   true
                        font.family: "JetBrains Mono Nerd Font Mono"
                    }
                }

                // Slider
                Rectangle {
                    id:     sliderTrack
                    Layout.fillWidth: true
                    implicitHeight: 14
                    radius: 5
                    color:  Qt.darker(theme.background, 1.3)
                    border { width: 2; color: theme.color4 }

                    Rectangle {
                        anchors {
                            left:   parent.left
                            top:    parent.top
                            bottom: parent.bottom
                        }
                        width:  parent.width * Math.min(Math.max(root.volumeLevel, 0), 1)
                        radius: 5
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
                    font.pixelSize: 12
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
                        radius: 5
                        color:  root.volumeMuted ? theme.color1 : "transparent"
                        border { width: 2; color: theme.color4 }

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
                        radius: 5
                        color:  "transparent"
                        border { width: 2; color: theme.color4 }

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

// ── Bluetooth Popup (DP-2) ────────────────────────────────────────────────────
Variants {
    model: Quickshell.screens.filter(screen => screen.name === "DP-2")

    PanelWindow {
        screen:  modelData
        visible: root.btPopupOpen
        required property var modelData

        anchors { top: true; bottom: true; left: true; right: true }

        color:     "transparent"
        focusable: root.btPopupOpen

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.btPopupOpen
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked:    root.btPopupOpen = false
        }

        Rectangle {
            id: btPanel
            anchors.top:        parent.top
            anchors.horizontalCenter:  parent.horizontalCenter
            anchors.topMargin:  10
            width:    500
            implicitHeight: btColumn.implicitHeight + 32
            height:   implicitHeight
            radius: 5
            color:    theme.background
            opacity:  0.95
            border { width: 2; color: theme.color2 }

            MouseArea {
                anchors.fill: parent
                onClicked:    mouse => mouse.accepted = true
            }

            ColumnLayout {
                id: btColumn
                anchors.fill:    parent
                anchors.margins: 16
                spacing: 0

                // ── Header ─────────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    spacing: 12

                    Text {
                        text:           bt.btIcon()
                        font.pixelSize: 24
                        color:          bt.enabled ? theme.color2 : theme.muted
                    }

                    Text {
                        text:      "Bluetooth"
                        color:     theme.foreground
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Text {
                        text:           bt.stateLabel()
                        color:          theme.muted
                        font.pixelSize: 14
                        font.bold:      true
                        font.family:    "JetBrains Mono Nerd Font Mono"
                    }
                }

                // ── Toggle Button ──────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 16
                    implicitHeight: 32
                    radius: 5
                    color:  bt.enabled ? theme.color2 : "transparent"
                    border { width: 2; color: theme.color4 }

                    Text {
                        anchors.centerIn: parent
                        text:  bt.enabled ? "Disable" : "Enable"
                        color: bt.enabled ? theme.background : theme.color2
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    bt.toggle()
                    }
                }

                // ── Device List Header ─────────────────────────────────────────
                Text {
                    text:      "Devices (" + bt.deviceCount + ")"
                    color:     theme.foreground
                    font.pixelSize: 14
                    font.bold: true
                    Layout.bottomMargin: 10
                }

                // ── Device List ────────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: bt.adapterValid ? bt.adapter.devices : []

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 48
                            radius: 5
                            color:  modelData.connected ? Qt.darker(theme.background, 1.2) : "transparent"
                            border { width: 2; color: modelData.connected ? theme.color2 : theme.color4 }

                            RowLayout {
                                anchors.fill:         parent
                                anchors.leftMargin:   12
                                anchors.rightMargin:  12
                                anchors.topMargin:    0
                                anchors.bottomMargin: 0
                                spacing: 12

                                // Device Name
                                Text {
                                    text:             modelData.name || modelData.address
                                    color:            modelData.connected ? theme.color2 : theme.foreground
                                    font.pixelSize:   13
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    elide:            Text.ElideRight
                                }

                                // Connection Status
                                Text {
                                    text:               modelData.connected ? "Connected" : (modelData.paired ? "Paired" : "")
                                    color:              modelData.connected ? theme.color2 : theme.muted
                                    font.pixelSize:     11
                                    font.family:        "JetBrains Mono Nerd Font Mono"
                                    Layout.rightMargin: 8
                                    Layout.alignment:   Qt.AlignVCenter
                                }

                                // Connect/Disconnect Button
                                Rectangle {
                                    width:  90
                                    height: 30
                                    radius: 5
                                    color:  modelData.connected ? theme.color1 : "transparent"
                                    border { width: 2; color: theme.color4 }
                                    Layout.alignment:   Qt.AlignVCenter
                                    Layout.rightMargin: 4

                                    Text {
                                        anchors.fill:        parent
                                        text:                modelData.connected ? "Disconnect" : "Connect"
                                        color:               modelData.connected ? theme.background : theme.color2
                                        font.pixelSize:      12
                                        font.bold:           true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment:   Text.AlignVCenter
                                        renderType:          Text.NativeRendering
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape:  Qt.PointingHandCursor
                                        onClicked:    bt.connectDevice(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                // ── No Devices Message ─────────────────────────────────────────
                Text {
                    visible: bt.deviceCount === 0
                    text:      "No devices found"
                    color:     theme.muted
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                }
            }
        }
    }
}

    // ── Weather Popup (DP-2) ──────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens.filter(screen => screen.name === "DP-2")

        PanelWindow {
            screen:  modelData
            visible: root.weatherPopupOpen
            required property var modelData

            anchors { top: true; bottom: true; left: true; right: true }

            color:     "transparent"
            focusable: root.weatherPopupOpen

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.weatherPopupOpen
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked:    root.weatherPopupOpen = false
            }

            Rectangle {
                id: weatherPanel
                anchors.top:        parent.top
                anchors.horizontalCenter:  parent.horizontalCenter
                anchors.topMargin:  10
                width:    500
                implicitHeight: weatherColumn.implicitHeight + 32
                height:   implicitHeight
                radius: 5
                color:    theme.background
                opacity:  0.95
                border { width: 2; color: theme.color4 }

                MouseArea {
                    anchors.fill: parent
                    onClicked:    mouse => mouse.accepted = true
                }

                ColumnLayout {
                    id: weatherColumn
                    anchors.fill:    parent
                    anchors.margins: 16
                    spacing: 12

                    // ── Header ──────────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text:           weather.weatherIconText()
                            font.pixelSize: 28
                            color:          theme.color4
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text:      weather.locationDisplay()
                                color:     theme.foreground
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Text {
                                text:      weather.shortCondition()
                                color:     theme.muted
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            text:           weather.loaded ? weather.tempDisplay() : "--"
                            color:          theme.color4
                            font.pixelSize: 28
                            font.bold:      true
                            font.family:    "JetBrains Mono Nerd Font Mono"
                        }
                    }

                    // ── Separator ────────────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 4
                        Layout.topMargin: 4
                        height: 1
                        color: theme.muted
                        opacity: 0.4
                    }

                    // ── Stats Grid ──────────────────────────────────────────────
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 12

                        // Feels Like
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            Layout.alignment: Qt.AlignHCenter
                            radius: 5
                            color: "transparent"
                            border { width: 2; color: Qt.darker(theme.muted, 1.5) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text:           "󰖐"
                                    font.pixelSize: 14
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.color6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           weather.feelsLikeC + "°C"
                                    font.pixelSize: 14
                                    font.bold:      true
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.foreground
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           "Feels Like"
                                    font.pixelSize: 10
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.muted
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Humidity
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            Layout.alignment: Qt.AlignHCenter
                            radius: 5
                            color: "transparent"
                            border { width: 2; color: Qt.darker(theme.muted, 1.5) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text:           "󱈑"
                                    font.pixelSize: 14
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.color3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           weather.humidity + "%"
                                    font.pixelSize: 14
                                    font.bold:      true
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.foreground
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           "Humidity"
                                    font.pixelSize: 10
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.muted
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Wind
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            Layout.alignment: Qt.AlignHCenter
                            radius: 5
                            color: "transparent"
                            border { width: 2; color: Qt.darker(theme.muted, 1.5) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text:           "󰖝"
                                    font.pixelSize: 14
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.color5
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           weather.windSpeed + " km/h"
                                    font.pixelSize: 14
                                    font.bold:      true
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.foreground
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           weather.windDir
                                    font.pixelSize: 10
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.muted
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Pressure
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            Layout.alignment: Qt.AlignHCenter
                            radius: 5
                            color: "transparent"
                            border { width: 2; color: Qt.darker(theme.muted, 1.5) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text:           "󰖂"
                                    font.pixelSize: 14
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.color2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           weather.pressure + " hPa"
                                    font.pixelSize: 14
                                    font.bold:      true
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.foreground
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           "Pressure"
                                    font.pixelSize: 10
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.muted
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // UV Index
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            Layout.alignment: Qt.AlignHCenter
                            radius: 5
                            color: "transparent"
                            border { width: 2; color: Qt.darker(theme.muted, 1.5) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text:           "󰖨"
                                    font.pixelSize: 14
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.color1
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           weather.uvIndex
                                    font.pixelSize: 14
                                    font.bold:      true
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.foreground
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           "UV Index"
                                    font.pixelSize: 10
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.muted
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Visibility
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            Layout.alignment: Qt.AlignHCenter
                            radius: 5
                            color: "transparent"
                            border { width: 2; color: Qt.darker(theme.muted, 1.5) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text:           "󰈈"
                                    font.pixelSize: 14
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.color4
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           weather.visibility + " km"
                                    font.pixelSize: 14
                                    font.bold:      true
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.foreground
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text:           "Visibility"
                                    font.pixelSize: 10
                                    font.family:    "JetBrains Mono Nerd Font Mono"
                                    color:          theme.muted
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }

                    // ── Cloud Cover ─────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 20
                            radius: 5
                            color: Qt.darker(theme.background, 1.3)

                            Rectangle {
                                anchors {
                                    left:   parent.left
                                    top:    parent.top
                                    bottom: parent.bottom
                                }
                                width: parent.width * (parseInt(weather.cloudCover) / 100)
                                radius: 5
                                color: theme.color4
                                opacity: 0.6
                            }
                        }

                        Text {
                            text:           weather.cloudCover + "% clouds"
                            font.pixelSize: 11
                            font.family:    "JetBrains Mono Nerd Font Mono"
                            color:          theme.muted
                        }
                    }

                    // ── Refresh Button ──────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        implicitHeight: 28
                        radius: 5
                        color:  "transparent"
                        border { width: 2; color: theme.color4 }

                        Text {
                            anchors.centerIn: parent
                            text:  "Refresh"
                            color: theme.color4
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    weather.refresh()
                        }
                    }
                }
            }
        }
    }

    // ── Calendar Popup (DP-2) ─────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens.filter(screen => screen.name === "DP-2")

        PanelWindow {
            screen:  modelData
            visible: root.calendarPopupOpen
            required property var modelData

            anchors { top: true; bottom: true; left: true; right: true }

            color:     "transparent"
            focusable: root.calendarPopupOpen

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.calendarPopupOpen
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked:    root.calendarPopupOpen = false
            }

            Rectangle {
                id: calendarPanel
                anchors.top:        parent.top
                anchors.horizontalCenter:  parent.horizontalCenter
                anchors.topMargin:  10
                width:    400
                implicitHeight: calendarColumn.implicitHeight + 32
                height:   implicitHeight
                radius: 5
                color:    theme.background
                opacity:  0.95
                border { width: 2; color: theme.color4 }

                MouseArea {
                    anchors.fill: parent
                    onClicked:    mouse => mouse.accepted = true
                }

                ColumnLayout {
                    id: calendarColumn
                    anchors.fill:    parent
                    anchors.margins: 16
                    spacing: 10

                    // ── Header ──────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 28; height: 28; radius: 5
                            color: "transparent"
                            border { width: 2; color: theme.color4 }

                            Text {
                                anchors.centerIn: parent
                                text: "󰁍"
                                font.pixelSize: 14
                                color: theme.color4
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.prevMonth()
                            }
                        }

                        Text {
                            text: root.calendarMonthName()
                            color: theme.foreground
                            font.pixelSize: 16
                            font.bold: true
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Rectangle {
                            width: 28; height: 28; radius: 5
                            color: "transparent"
                            border { width: 2; color: theme.color4 }

                            Text {
                                anchors.centerIn: parent
                                text: "󰁔"
                                font.pixelSize: 14
                                color: theme.color4
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.nextMonth()
                            }
                        }
                    }

                    // ── Calendar Grid ───────────────────────────────────────
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 0
                        rowSpacing: 4

                        // Day-of-week headers
                        Repeater {
                            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                            Text {
                                text: modelData
                                font.pixelSize: 11
                                font.bold: true
                                font.family: "JetBrains Mono Nerd Font Mono"
                                color: theme.muted
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                horizontalAlignment: Text.AlignHCenter
                                topPadding: 4
                                bottomPadding: 4
                            }
                        }

                        // Separator (spans all 7 columns)
                        Rectangle {
                            Layout.columnSpan: 7
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                            height: 1
                            color: theme.muted
                            opacity: 0.3
                        }

                        // Calendar day cells
                        Repeater {
                            model: 42  // 6 rows * 7 columns

                            Rectangle {
                                required property int index
                                property int rowIndex: Math.floor(index / 7)
                                property int colIndex: index % 7
                                property int dayNum: {
                                    var y = root.calendarDate.getFullYear()
                                    var m = root.calendarDate.getMonth()
                                    var firstDay = root.firstDayOfMonth(y, m)
                                    var totalDays = root.daysInMonth(y, m)
                                    var day = (rowIndex * 7) + colIndex - firstDay + 1
                                    if (day < 1 || day > totalDays) return 0
                                    return day
                                }
                                property bool isToday: {
                                    if (dayNum === 0) return false
                                    var now = new Date()
                                    return dayNum === now.getDate()
                                        && root.calendarDate.getMonth() === now.getMonth()
                                        && root.calendarDate.getFullYear() === now.getFullYear()
                                }

                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                Layout.preferredHeight: 32
                                radius: 5
                                color: isToday ? theme.color2 : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: dayNum === 0 ? "" : dayNum.toString()
                                    font.pixelSize: 12
                                    font.family: "JetBrains Mono Nerd Font Mono"
                                    font.bold: isToday
                                    color: isToday ? theme.background : (dayNum === 0 ? "transparent" : theme.foreground)
                                }
                            }
                        }
                    }

                    // ── Today Button ────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        implicitHeight: 28
                        radius: 5
                        color: "transparent"
                        border { width: 2; color: theme.color4 }

                        Text {
                            anchors.centerIn: parent
                            text: "Today"
                            color: theme.color4
                            font.pixelSize: 12
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.goToToday()
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
                    radius: 5
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
                            radius: 5
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
            radius: 5
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

