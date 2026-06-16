import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: statsRoot

    property string cpuTemp:      "--"
    property string gpuTemp:      "--"
    property string ramTemp:      "--"
    property real   cpuTempRaw:   0
    property real   gpuTempRaw:   0
    property real   ramTempRaw:   0
    property real   cpuUsage:     0
    property real   gpuUsage:     0
    property real   ramUsage:     0
    property real   ramUsageGB:   0
    property string ramUsed:      "--"
    property string ramTotal:     "--"
    property string cpuClock:     "--"
    property string gpuClock:     "--"
    property string ramClock:     "--"
    property bool   loaded:       false
    property bool   popupOpen:    false

    Process {
        id:      statProc
        command: ["bash", "-c", "echo \"CPU_TEMP:$(sensors 2>/dev/null | grep Tctl | head -1 | awk '{print $2}' | tr -d '+°C')\"; echo \"GPU_TEMP:$(sensors 2>/dev/null | grep junction | head -1 | awk '{print $2}' | tr -d '+°C')\"; echo \"CPU Usage:$(top -bn1 | grep 'Cpu(s)' | awk '{print 100-$8}')\"; echo \"GPU Usage:$(nvidia-smi 2>/dev/null | grep '%' | head -1 | awk '{for(i=1;i<=NF;i++) if($i ~ /%/) print $(i-1)}' | tr -d '%')\"; echo \"RAM_USED:$(free -m | awk '/Mem:/{print $3}')\"; echo \"RAM_TOTAL:$(free -m | awk '/Mem:/{print $2}')\"; echo \"CPU_CLOCK:$(cat /proc/cpuinfo 2>/dev/null | grep 'cpu MHz' | head -1 | awk -F: '{print $2}' | tr -d ' ')\""]
        running: false

        property string output: ""

        stdout: SplitParser {
            onRead: line => { statProc.output += line + "\n" }
        }

        onRunningChanged: {
            if (!running && statProc.output) {
                statsRoot.parseStats(statProc.output)
                statProc.output = ""
            }
        }
    }

    Timer {
        interval:         2000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered:      { if (!statProc.running) statProc.running = true }
    }

    function parseStats(raw) {
        const lines = raw.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line.startsWith("CPU_TEMP:")) {
                const val = parseFloat(line.substring(9).trim())
                if (!isNaN(val)) {
                    cpuTempRaw = val
                    cpuTemp    = Math.round(val) + "°C"
                } else {
                    cpuTempRaw = 0
                    cpuTemp    = "--"
                }
            } else if (line.startsWith("GPU_TEMP:")) {
                const val = parseFloat(line.substring(9).trim())
                if (!isNaN(val)) {
                    gpuTempRaw = val
                    gpuTemp    = Math.round(val) + "°C"
                } else {
                    gpuTempRaw = 0
                    gpuTemp    = "--"
                }
            } else if (line.startsWith("CPU Usage:")) {
                const val = parseFloat(line.substring(10).trim())
                cpuUsage = isNaN(val) ? 0 : Math.min(val, 100)
            } else if (line.startsWith("GPU Usage:")) {
                const val = parseFloat(line.substring(10).trim())
                gpuUsage = isNaN(val) ? 0 : Math.min(val, 100)
            } else if (line.startsWith("RAM_USED:")) {
                ramUsed = line.substring(9).trim() + " MB"
            } else if (line.startsWith("RAM_TOTAL:")) {
                ramTotal = line.substring(10).trim() + " MB"
            } else if (line.startsWith("CPU_CLOCK:")) {
                const val = line.substring(10).trim()
                cpuClock = val ? Math.round(parseFloat(val)) + " MHz" : "--"
            } else if (line.startsWith("GPU_CLOCK:")) {
                const val = line.substring(10).trim()
                gpuClock = val ? Math.round(parseFloat(val)) + " MHz" : "--"
            } else if (line.startsWith("RAM_CLOCK:")) {
                const val = line.substring(10).trim()
                ramClock = val ? Math.round(parseFloat(val)) + " MHz" : "--"
            } else if (line.startsWith("RAM_TEMP:")) {
                const val = parseFloat(line.substring(9).trim())
                if (!isNaN(val)) {
                    ramTempRaw = val
                    ramTemp = Math.round(val) + "°C"
                } else {
                    ramTempRaw = 0
                    ramTemp = "--"
                }
            }
        }

        const used = parseInt(ramUsed)
        const total = parseInt(ramTotal)
        ramUsage = (total > 0) ? (used / total) * 100 : 0
        ramUsageGB = used

        loaded = true
    }

    function togglePopup() {
        popupOpen = !popupOpen
    }
}
