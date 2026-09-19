import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: volumeRoot

    property var hostWindow: null
    property real anchorX: 0
    property int volume: 0
    property bool muted: false
    property bool loaded: false
    property bool devicePopupOpen: false
    property var audioDevices: []
    property bool parsingSinks: false
    property bool parsingAudio: false
    property bool parsingDevices: false

    width: 42
    height: 42

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        border.color: theme.muted
        border.width: root.moduleBorderThickness
        color: volHover.containsMouse ? theme.color3 : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: muted ? "\u{F466}" : (volume === 0 ? "\u{F466}" : (volume >= 66 ? "\u{F028}" : (volume >= 33 ? "\u{F027}" : "\u{F026}")))
            font.pixelSize: 20
            font.family: "JetBrainsMono Nerd Font"
            color: volHover.containsMouse ? theme.background : theme.color3
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: muted ? "Muted" : volume + "%"
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
            font.bold: true
            color: volHover.containsMouse ? theme.background : theme.muted
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: volHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) adjustVolume(5)
            else if (wheel.angleDelta.y < 0) adjustVolume(-5)
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                devicePopupOpen = !devicePopupOpen
                if (devicePopupOpen) refreshDevices()
            } else {
                pulseCmd.running = true
            }
        }
    }

    Loader {
        id: volumeTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: volHover.containsMouse && !volumeRoot.devicePopupOpen
        property real tooltipAnchorX: volumeRoot.anchorX
        onLoaded: {
            item.hostWindow = volumeRoot.hostWindow
            item.title = "Volume"
            item.details = "LEFT CLICK  Open mixer\nRIGHT CLICK  Select output device\nWHEEL  Adjust volume"
        }
        Binding { target: volumeTooltip.item; property: "shown"; value: volumeTooltip.tooltipShown; when: volumeTooltip.item !== null }
        Binding { target: volumeTooltip.item; property: "anchorX"; value: volumeTooltip.tooltipAnchorX; when: volumeTooltip.item !== null }
    }

    function adjustVolume(delta) {
        var newVol = Math.max(0, Math.min(150, volume + delta))
        wpSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol / 100]
        wpSetProc.running = true
        volume = newVol
        volumeOSD.show(volume, muted)
        refreshTimer.restart()
    }

    Timer { id: refreshTimer; interval: 200; onTriggered: refreshVolume() }

    Process {
        id: wpSetProc
        running: false
        stdout: SplitParser { onRead: line => {} }
    }

    Process {
        id: pulseCmd
        running: false
        command: ["kitty", "--class=pulsepad", "-e", "pulsemixer"]
        stdout: SplitParser { onRead: line => {} }
    }

    Process {
        id: deviceListProc
        running: false
        command: ["wpctl", "status"]
        stdout: SplitParser {
            onRead: line => {
                var text = line.trim()
                if (text === "Audio") {
                    volumeRoot.parsingAudio = true
                    return
                }
                if (text === "Video" || text === "Settings") {
                    volumeRoot.parsingAudio = false
                    volumeRoot.parsingSinks = false
                    return
                }
                if (text.indexOf("Sinks:") !== -1) {
                    volumeRoot.parsingSinks = volumeRoot.parsingAudio
                    volumeRoot.parsingDevices = false
                    if (volumeRoot.parsingAudio && volumeRoot.audioDevices.length === 0) volumeRoot.audioDevices = []
                    return
                }
                if (text.indexOf("Devices:") !== -1) {
                    volumeRoot.parsingDevices = volumeRoot.parsingAudio
                    volumeRoot.parsingSinks = false
                    if (volumeRoot.parsingAudio) volumeRoot.audioDevices = []
                    return
                }
                if (text.indexOf("Sources:") !== -1) {
                    volumeRoot.parsingSinks = false
                    return
                }
                if (!volumeRoot.parsingAudio || (!volumeRoot.parsingSinks && !volumeRoot.parsingDevices)) return

                var match = text.match(/(?:\*\s*)?(\d+)\.\s+(.+)/)
                if (!match) return

                var name = match[2]
                    .replace(/\s+\[vol:.*$/, "")
                    .replace(/\s+\[[^\]]+\]\s*$/, "")
                    .trim()
                var devices = volumeRoot.audioDevices.slice()
                var id = parseInt(match[1])
                var active = text.indexOf("*") !== -1

                if (volumeRoot.parsingDevices) {
                    devices.push({ id: id, name: name, active: false, sinkId: -1, targetType: "device" })
                } else {
                    var lowerName = name.toLowerCase()
                    var matchedDevice = -1
                    for (var i = 0; i < devices.length; i++) {
                        var deviceName = devices[i].name.toLowerCase()
                        if (lowerName.indexOf(deviceName) !== -1 || deviceName.indexOf(lowerName) !== -1) {
                            matchedDevice = i
                            break
                        }
                    }
                    if (matchedDevice !== -1) {
                        devices[matchedDevice].sinkId = id
                        devices[matchedDevice].active = active
                    } else {
                        devices.push({ id: id, name: name, active: active, sinkId: id, targetType: "sink" })
                    }
                }
                volumeRoot.audioDevices = devices
            }
        }
    }

    Process {
        id: setDefaultDeviceProc
        running: false
        stdout: SplitParser { onRead: line => {} }
    }

    function refreshDevices() {
        if (deviceListProc.running) deviceListProc.running = false
        audioDevices = []
        parsingSinks = false
        parsingAudio = false
        parsingDevices = false
        deviceListProc.running = true
    }

    function selectDevice(deviceId, sinkId) {
        var id = Number(sinkId >= 0 ? sinkId : deviceId)
        if (!isFinite(id)) return
        if (setDefaultDeviceProc.running) setDefaultDeviceProc.running = false
        var command = ""
        if (sinkId >= 0) {
            command = "wpctl set-default " + String(id) +
                "; target=$(wpctl inspect " + String(id) + " | sed -n 's/.*node.name = \"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
        } else {
            command = "card=$(pactl list short cards | awk -v id=" + String(deviceId) + " '$1 == id {print $2; exit}'); " +
                "profile=$(pactl list cards | awk -v id=" + String(deviceId) + " 'BEGIN{card=0} $0 ~ \"^Card #\" id \"$\" {card=1; next} card && /^Card #[0-9]+/ {exit} card && /^[[:space:]]+output:/ && /available: yes/ {profile=$1; sub(/:$/, \"\", profile); print profile; exit}'); " +
                "if [ -n \"$card\" ] && [ -n \"$profile\" ]; then pactl set-card-profile \"$card\" \"$profile\"; sleep 0.2; target=$(pactl list short sinks | awk -v key=\"${card#alsa_card.}\" '$2 ~ key {print $2; exit}'); fi"
        }
        command += "; if [ -n \"$target\" ]; then pactl set-default-sink \"$target\"; pactl list short sink-inputs | while read stream rest; do pactl move-sink-input \"$stream\" \"$target\"; done; fi"
        setDefaultDeviceProc.command = ["sh", "-c", command]
        setDefaultDeviceProc.running = true
        devicePopupOpen = false
        refreshTimer.restart()
        refreshDevicesTimer.restart()
    }

    Timer {
        id: refreshDevicesTimer
        interval: 700
        onTriggered: refreshDevices()
    }

    PopupWindow {
        id: devicePopup
        visible: volumeRoot.devicePopupOpen && volumeRoot.hostWindow !== null
        color: "transparent"
        implicitWidth: 320
        implicitHeight: Math.max(72, 52 + volumeRoot.audioDevices.length * 44)

        anchor.window: volumeRoot.hostWindow
        anchor.rect.x: volumeRoot.anchorX - implicitWidth / 2
        anchor.rect.y: root.barPosition === "top"
            ? volumeRoot.hostWindow.height + 7
            : -implicitHeight - 7

        Rectangle {
            anchors.fill: parent
            radius: root.popupRadius
            color: theme.background
            opacity: root.popupOpacity
            border.width: root.popupBorderThickness
            border.color: theme.color4

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Text {
                    text: "OUTPUT DEVICE"
                    color: theme.muted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                    Layout.fillWidth: true
                }

                Repeater {
                    model: volumeRoot.audioDevices

                    Rectangle {
                        required property var modelData
                        property int deviceId: modelData.id
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: root.popupRadius
                        color: deviceHover.containsMouse ? theme.color1 : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: modelData.active ? "\u{F00C}" : "\u{F111}"
                                color: modelData.active ? theme.color1 : theme.muted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }

                            Text {
                                text: modelData.name
                                color: deviceHover.containsMouse ? theme.background : theme.foreground
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: deviceHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: volumeRoot.selectDevice(parent.deviceId, modelData.sinkId)
                        }
                    }
                }

                Text {
                    visible: volumeRoot.audioDevices.length === 0
                    text: "No output devices found"
                    color: theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
            }
        }
    }

    Process {
        id: volGetProc
        running: false
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2 * 100)}'"]
        stdout: SplitParser {
            onRead: line => {
                var v = parseInt(line.trim())
                if (!isNaN(v) && v !== volumeRoot.volume) {
                    volumeRoot.volume = v
                    if (volumeRoot.loaded) volumeOSD.show(v, muted)
                }
            }
        }
    }

    Process {
        id: muteGetProc
        running: false
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q MUTED && echo 1 || echo 0"]
        stdout: SplitParser {
            onRead: line => {
                var newMuted = line.trim() === "1"
                if (newMuted !== volumeRoot.muted) {
                    volumeRoot.muted = newMuted
                    if (volumeRoot.loaded) volumeOSD.show(volume, newMuted)
                }
            }
        }
    }

    function refreshVolume() {
        volGetProc.running = true
        muteGetProc.running = true
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: refreshVolume() }
    Component.onCompleted: { refreshVolume(); volumeLoadTimer.start() }
    Timer { id: volumeLoadTimer; interval: 500; running: false; onTriggered: volumeRoot.loaded = true }
}
