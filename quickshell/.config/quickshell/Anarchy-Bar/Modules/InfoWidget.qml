import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: infoRoot

    property string tempC: "--"
    property string condition: "Loading..."
    property string city: ""
    property string country: ""
    property string humidity: "--"
    property string windSpeed: "--"
    property string windDir: "--"
    property string weatherIcon: ""
    property bool loaded: false
    property bool showHourly: false
    property real feelsLike: 0

    property var hourlyTimes: []
    property var hourlyTemps: []
    property var hourlyCodes: []

    property real latitude: 0
    property real longitude: 0

    property real cpuTemp: 0
    property real cpuUsage: 0
    property real ramUsage: 0
    property real ramTotal: 0
    property real ramUsed: 0
    property real gpuTemp: 0
    property real gpuUsage: 0
    property string gpuName: "N/A"
    property bool hasGpu: false
    property var disks: []

    width: 42
    height: 42
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
        anchors.fill: parent
        radius: root.barRadius
        border.color: theme.muted
        border.width: root.moduleBorderThickness
        color: infoHover.containsMouse ? theme.color4 : "transparent"
    }

    Text {
        anchors.centerIn: parent
        text: "\u{F17A}"
        font.pixelSize: 20
        font.family: "JetBrainsMono Nerd Font"
        color: infoHover.containsMouse ? theme.background : theme.muted
    }

    MouseArea {
        id: infoHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (infoPopup.isOpen) infoPopup.close()
            else infoPopup.open()
        }
    }

    Process {
        id: geoProc
        running: false
        command: ["curl", "-s", "--max-time", "10", "https://ipinfo.io/json"]
        stdout: StdioCollector {
            id: geoStdio
            onStreamFinished: { infoRoot.parseGeo(geoStdio.text) }
        }
    }

    Process {
        id: weatherProc
        running: false
        function fetch() {
            var url = "https://api.open-meteo.com/v1/forecast"
                + "?latitude=" + infoRoot.latitude
                + "&longitude=" + infoRoot.longitude
                + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m"
                + "&hourly=temperature_2m,weather_code"
                + "&timezone=auto"
            command = ["curl", "-s", "--max-time", "10", url]
            running = true
        }
        stdout: StdioCollector {
            id: weatherStdio
            onStreamFinished: { infoRoot.parseWeather(weatherStdio.text) }
        }
    }

    Timer { interval: 1000; running: true; repeat: false; onTriggered: { if (!geoProc.running) geoProc.running = true } }
    Timer { interval: 900000; running: true; repeat: true; onTriggered: { if (!weatherProc.running && latitude !== 0) weatherProc.fetch() } }

    function parseGeo(jsonStr) {
        try {
            var data = JSON.parse(jsonStr)
            latitude = parseFloat(data.loc.split(",")[0])
            longitude = parseFloat(data.loc.split(",")[1])
            city = data.city || ""
            country = data.country || ""
        } catch (e) {}
        if (!weatherProc.running) weatherProc.fetch()
    }

    function parseWeather(jsonStr) {
        try {
            var data = JSON.parse(jsonStr)
            var cc = data.current
            tempC = Math.round(cc.temperature_2m).toString()
            feelsLike = Math.round(cc.apparent_temperature)
            humidity = cc.relative_humidity_2m.toString()
            windSpeed = Math.round(cc.wind_speed_10m).toString()
            windDir = getWindDir(cc.wind_direction_10m)
            condition = getConditionText(cc.weather_code)
            weatherIcon = getWeatherIcon(cc.weather_code)
            if (data.hourly && data.hourly.time) {
                hourlyTimes = data.hourly.time
                hourlyTemps = data.hourly.temperature_2m
                hourlyCodes = data.hourly.weather_code
            }
            loaded = true
        } catch (e) {}
    }

    function currentHourIndex() {
        if (!hourlyTimes || hourlyTimes.length === 0) return 0
        var now = new Date()
        for (var i = 0; i < hourlyTimes.length; i++) {
            var t = new Date(hourlyTimes[i])
            if (t.getHours() === now.getHours() && t.getDate() === now.getDate()) return i
        }
        return 0
    }

    function getHourlyLabel(offset) {
        var idx = currentHourIndex() + offset
        if (idx >= hourlyTimes.length) return "--"
        return Qt.formatDateTime(new Date(hourlyTimes[idx]), "h AP")
    }

    function getHourlyIcon(offset) {
        var idx = currentHourIndex() + offset
        if (idx >= hourlyCodes.length) return ""
        return getWeatherIcon(hourlyCodes[idx])
    }

    function getHourlyTemp(offset) {
        var idx = currentHourIndex() + offset
        if (idx >= hourlyTemps.length) return "--"
        return Math.round(hourlyTemps[idx]).toString()
    }

    function getWindDir(degrees) {
        var dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        return dirs[Math.round(degrees / 22.5) % 16]
    }

    function getConditionText(code) {
        var c = parseInt(code)
        if (c === 0) return "Clear sky"
        if (c <= 3) return "Partly cloudy"
        if (c <= 49) return "Fog"
        if (c <= 69) return "Drizzle"
        if (c <= 79) return "Snow"
        if (c <= 82) return "Rain"
        if (c <= 86) return "Snow showers"
        if (c <= 99) return "Thunderstorm"
        return "Unknown"
    }

    function getWeatherIcon(code) {
        var c = parseInt(code)
        if (c === 0) return "\u{F0599}"
        if (c === 1 || c === 2) return "\u{F0595}"
        if (c === 3) return "\u{F0590}"
        if (c >= 45 && c <= 48) return "\u{F0591}"
        if (c >= 51 && c <= 67) return "\u{F0597}"
        if (c >= 71 && c <= 77) return "\u{F0598}"
        if (c >= 80 && c <= 82) return "\u{F0597}"
        if (c >= 85 && c <= 86) return "\u{F0598}"
        if (c >= 95 && c <= 99) return "\u{F0598}"
        return "\u{F0590}"
    }

    function refreshWeather() {
        if (!geoProc.running && !weatherProc.running) geoProc.running = true
    }

    Process {
        id: cpuTempProc
        running: false
        command: ["sh", "-c", "sensors 2>/dev/null | grep Tctl | head -1 | awk '{print $2}' | tr -d '+°C'"]

        property string buffer: ""

        stdout: SplitParser { onRead: data => { cpuTempProc.buffer += data + "\n" } }
        stderr: SplitParser { onRead: data => { cpuTempProc.buffer += data + "\n" } }

        onRunningChanged: {
            if (!running) {
                var val = parseFloat(cpuTempProc.buffer.trim())
                if (!isNaN(val)) cpuTemp = Math.round(val)
                cpuTempProc.buffer = ""
            }
        }
    }

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
                        if (!isNaN(val) && val > 0) { gpuTemp = Math.round(val / 1000); hasGpu = true }
                    } else if (l.indexOf("GPU_NAME:") === 0) {
                        gpuName = l.substring(9).trim()
                    }
                }
                gpuTempProc.buffer = ""
            }
        }
    }

    Process {
        id: usageProc
        running: false
        command: ["sh", "-c", "echo CPUUsage:$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print 100-$8}' || echo 0); echo GPUUsage:$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1 || echo 0); echo MEM:$(free -b | awk '/Mem:/{print $3\" \"$2}')"]

        property string buffer: ""

        stdout: SplitParser { onRead: data => { usageProc.buffer += data + "\n" } }
        stderr: SplitParser { onRead: data => { usageProc.buffer += data + "\n" } }

        onRunningChanged: {
            if (!running) {
                infoRoot.parseUsage(usageProc.buffer)
                usageProc.buffer = ""
            }
        }
    }

    property int cpuPrevIdle: 0
    property int cpuPrevTotal: 0

    function parseUsage(text) {
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim()
            if (l.indexOf("CPUUsage:") === 0) {
                cpuUsage = Math.round(parseFloat(l.split(":")[1])) || 0
            } else if (l.indexOf("GPUUsage:") === 0) {
                gpuUsage = parseInt(l.split(":")[1]) || 0
            } else if (l.indexOf("MEM:") === 0) {
                var mp = l.split(":")[1].split(" ")
                ramUsed = parseInt(mp[0]) / (1024 * 1024 * 1024)
                ramTotal = parseInt(mp[1]) / (1024 * 1024 * 1024)
                ramUsage = ramTotal > 0 ? Math.round(ramUsed / ramTotal * 100) : 0
            }
        }
        readCpuUsage()
        readDisks()
    }

    function readCpuUsage() {
        cpuReadProc.running = true
    }

    Process {
        id: cpuReadProc
        running: false
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: StdioCollector {
            id: cpuReadStdio
            onStreamFinished: {
                var parts = cpuReadStdio.text.trim().split(/\s+/)
                if (parts.length < 5) return
                var idle = parseInt(parts[4])
                var total = 0
                for (var i = 1; i < parts.length; i++) total += parseInt(parts[i])
                var dIdle = idle - infoRoot.cpuPrevIdle
                var dTotal = total - infoRoot.cpuPrevTotal
                if (dTotal > 0) cpuUsage = Math.round((1 - dIdle / dTotal) * 100)
                cpuPrevIdle = idle
                cpuPrevTotal = total
            }
        }
    }

    function readDisks() {
        diskProc.running = true
    }

    Process {
        id: diskProc
        running: false
        command: ["sh", "-c", "lsblk -d -J -o NAME,SIZE,MOUNTPOINT,FSTYPE 2>/dev/null"]
        stdout: StdioCollector {
            id: diskStdio
            onStreamFinished: { infoRoot.parseDisks(diskStdio.text) }
        }
    }

    function parseDisks(jsonStr) {
        var result = []
        try {
            var data = JSON.parse(jsonStr)
            for (var i = 0; i < data.blockdevices.length; i++) {
                var d = data.blockdevices[i]
                var mounted = d.mountpoint && d.mountpoint.length > 0
                result.push({
                    name: d.name,
                    size: d.size || "?",
                    mount: mounted ? d.mountpoint : "Unmounted",
                    fstype: d.fstype || "",
                    mounted: mounted
                })
            }
        } catch (e) {}
        disks = result
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!cpuTempProc.running) cpuTempProc.running = true
            if (!gpuTempProc.running) gpuTempProc.running = true
            if (!usageProc.running) usageProc.running = true
        }
    }

    Component.onCompleted: {
        cpuTempProc.running = true
        gpuTempProc.running = true
        usageProc.running = true
    }
}
