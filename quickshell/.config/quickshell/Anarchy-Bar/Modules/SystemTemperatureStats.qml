import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Scope {
    id: temperatures

    property real cpuTemp: 0
    property real gpuTemp: 0
    readonly property string cpuTempScriptPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "")
        + "/.config/quickshell/Anarchy-Bar/Scripts/read-cpu-temp.sh"

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
        command: ["bash", temperatures.cpuTempScriptPath]
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
