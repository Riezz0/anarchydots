import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: temperatures

    property real cpuTemp: 0
    property real gpuTemp: 0

    function poll() {
        cpuTempProcess.running = false
        gpuTempProcess.running = false
        cpuTempProcess.running = true
        gpuTempProcess.running = true
    }

    Timer {
        interval: 1000
        running: systemWidgetsPopup.isOpen
        repeat: true
        onTriggered: temperatures.poll()
        Component.onCompleted: if (systemWidgetsPopup.isOpen) temperatures.poll()
    }

    Connections {
        target: systemWidgetsPopup
        function onIsOpenChanged() {
            if (systemWidgetsPopup.isOpen) temperatures.poll()
        }
    }

    Process {
        id: cpuTempProcess
        command: ["sh", "-c", "sensors 2>/dev/null | grep -m1 '°C' | grep -oP '[+-]?[0-9]+\\.[0-9]+(?=°)' | head -1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var value = parseFloat(text.trim())
                if (!isNaN(value)) temperatures.cpuTemp = Math.round(value)
            }
        }
    }

    Process {
        id: gpuTempProcess
        command: ["sh", "-c", "cat /sys/class/drm/card*/device/hwmon/hwmon*/temp2_input 2>/dev/null | head -1"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var millidegrees = parseInt(text.trim())
                temperatures.gpuTemp = !isNaN(millidegrees) && millidegrees > 0
                    ? Math.round(millidegrees / 1000)
                    : 0
            }
        }
    }
}
