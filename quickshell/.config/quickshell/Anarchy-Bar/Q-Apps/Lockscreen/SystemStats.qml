import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: statsRoot

    property real cpuUsage: 0
    property real cpuTemp: 0
    property real ramUsage: 0
    property string ramUsed: ""
    property string ramTotal: ""
    property real gpuUsage: 0
    property real gpuTemp: 0
    property bool hasGpu: false
    property string gpuName: ""
    property real temperature: 0
    property string diskUsage: ""
    property string netRx: ""
    property string netTx: ""

    property real prevNetRx: 0
    property real prevNetTx: 0
    property bool firstNetRead: true

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: pollAll()
        Component.onCompleted: pollAll()
    }

    function pollAll() {
        usageProc.running = true
        cpuTempProc.running = true
        gpuTempProc.running = true
        diskProc.running = true
        netProc.running = true
    }

    // Combined CPU/RAM/GPU usage
    Process {
        id: usageProc
        running: false
        command: ["sh", "-c", "echo CPUUsage:$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print 100-$8}' || echo 0); echo GPUUsage:$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1 || echo 0); echo MEM:$(free -b | awk '/Mem:/{print $3\" \"$2}')"]

        property string buffer: ""
        stdout: SplitParser { onRead: data => { usageProc.buffer += data + "\n" } }
        stderr: SplitParser { onRead: data => { usageProc.buffer += data + "\n" } }

        onRunningChanged: {
            if (!running) {
                var lines = usageProc.buffer.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i].trim()
                    if (l.indexOf("CPUUsage:") === 0) {
                        statsRoot.cpuUsage = Math.round(parseFloat(l.split(":")[1])) || 0
                    } else if (l.indexOf("GPUUsage:") === 0) {
                        var gpuVal = parseInt(l.split(":")[1]) || 0
                        statsRoot.gpuUsage = gpuVal
                        if (gpuVal > 0) statsRoot.hasGpu = true
                    } else if (l.indexOf("MEM:") === 0) {
                        var mp = l.split(":")[1].split(" ")
                        var usedBytes = parseInt(mp[0])
                        var totalBytes = parseInt(mp[1])
                        statsRoot.ramUsage = totalBytes > 0 ? Math.round(usedBytes / totalBytes * 100) : 0
                        statsRoot.ramUsed = formatBytes(usedBytes)
                        statsRoot.ramTotal = formatBytes(totalBytes)
                    }
                }
                usageProc.buffer = ""
                // Also read /proc/stat for more accurate CPU
                cpuReadProc.running = true
            }
        }
    }

    // Accurate CPU from /proc/stat
    property int cpuPrevIdle: 0
    property int cpuPrevTotal: 0

    Process {
        id: cpuReadProc
        running: false
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(/\s+/)
                if (parts.length < 5) return
                var idle = parseInt(parts[4])
                var total = 0
                for (var i = 1; i < parts.length; i++) total += parseInt(parts[i])
                var dIdle = idle - statsRoot.cpuPrevIdle
                var dTotal = total - statsRoot.cpuPrevTotal
                if (dTotal > 0) statsRoot.cpuUsage = Math.round((1 - dIdle / dTotal) * 100)
                statsRoot.cpuPrevIdle = idle
                statsRoot.cpuPrevTotal = total
            }
        }
    }

    // CPU temp
    Process {
        id: cpuTempProc
        running: false
        command: ["sh", "-c", "sensors 2>/dev/null | grep -m1 '°C' | grep -oP '[+-][0-9]+\\.[0-9]+(?=°)' | head -1"]
        stdout: SplitParser {
            onRead: line => {
                var val = parseFloat(line.trim())
                if (!isNaN(val)) {
                    statsRoot.cpuTemp = Math.round(val)
                    statsRoot.temperature = Math.round(val)
                }
            }
        }
    }

    // GPU temp and name
    Process {
        id: gpuTempProc
        running: false
        command: ["sh", "-c", "T=$(cat /sys/class/drm/card*/device/hwmon/hwmon*/temp2_input 2>/dev/null | head -1); N=$(lspci 2>/dev/null | grep -i 'VGA' | head -1 | sed 's/.*\\] //;s/ (rev.*//'); if [ -n \"$T\" ]; then echo \"GPU_TEMP:$T\"; echo \"GPU_NAME:$N\"; else echo GPU_FAIL; fi"]

        property string buffer: ""
        stdout: SplitParser { onRead: data => { gpuTempProc.buffer += data + "\n" } }
        stderr: SplitParser { onRead: data => { gpuTempProc.buffer += data + "\n" } }

        onRunningChanged: {
            if (!running) {
                var lines = gpuTempProc.buffer.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i].trim()
                    if (l.indexOf("GPU_TEMP:") === 0) {
                        var val = parseInt(l.split(":")[1])
                        if (!isNaN(val) && val > 0) { statsRoot.gpuTemp = Math.round(val / 1000); statsRoot.hasGpu = true }
                    } else if (l.indexOf("GPU_NAME:") === 0) {
                        statsRoot.gpuName = l.substring(9).trim()
                    }
                }
                gpuTempProc.buffer = ""
            }
        }
    }

    // Disk
    Process {
        id: diskProc
        running: false
        command: ["sh", "-c", "df -h / | awk 'NR==2{print $3\"/\"$2\" (\"$5\")\"}'"]
        stdout: SplitParser {
            onRead: line => { statsRoot.diskUsage = line.trim() }
        }
    }

    // Network
    Process {
        id: netProc
        running: false
        command: ["sh", "-c", "awk 'NR>2{split($0, a, \":\"); gsub(/[ \\t]/, \"\", a[1]); if(a[1]!=\"lo\" && a[1]!=\"virbr0\" && a[1]!=\"\" && a[1]!=\"face\") print a[1], $2, $10}' /proc/net/dev | head -1"]
        stdout: SplitParser {
            onRead: line => {
                var parts = line.trim().split(/\s+/)
                if (parts.length >= 3) {
                    var rx = parseInt(parts[1])
                    var tx = parseInt(parts[2])
                    if (!statsRoot.firstNetRead && statsRoot.prevNetRx > 0) {
                        statsRoot.netRx = formatSpeed(rx - statsRoot.prevNetRx)
                        statsRoot.netTx = formatSpeed(tx - statsRoot.prevNetTx)
                    }
                    statsRoot.prevNetRx = rx
                    statsRoot.prevNetTx = tx
                    statsRoot.firstNetRead = false
                }
            }
        }
    }

    function formatBytes(bytes) {
        if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + " GB"
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(0) + " MB"
        return bytes + " B"
    }

    function formatSpeed(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + " MB/s"
        if (bytes >= 1024) return (bytes / 1024).toFixed(0) + " KB/s"
        return bytes + " B/s"
    }
}
