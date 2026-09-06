import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: weatherRoot

    property string city: ""
    property real temp: 0
    property real feelsLike: 0
    property string condition: ""
    property string icon: ""
    property var hourlyForecast: []

    signal updated()

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
        Component.onCompleted: weatherProc.running = true
    }

    Process {
        id: weatherProc
        command: ["curl", "-sf", "wttr.in/?format=j1"]
        running: false
        stdout: SplitParser {
            onRead: line => {}
        }
        onRunningChanged: {
            if (!running && stdout !== null) {
                // Fallback: try reading full output
            }
        }
    }

    Process {
        id: weatherFullProc
        command: ["curl", "-sf", "wttr.in/?format=j1"]
        running: false

        property string buffer: ""

        onRunningChanged: {
            if (!running) {
                parseWeather(buffer)
                buffer = ""
            }
        }

        stdout: SplitParser {
            onRead: line => {
                weatherFullProc.buffer += line
            }
        }
    }

    Component.onCompleted: weatherFullProc.running = true

    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: weatherFullProc.running = true
    }

    function parseWeather(json) {
        try {
            var data = JSON.parse(json)
            if (!data || !data.current_condition || !data.current_condition[0]) return

            var cur = data.current_condition[0]
            city = (data.nearest_area && data.nearest_area[0])
                ? data.nearest_area[0].region[0].value : "Unknown"
            temp = parseFloat(cur.temp_C)
            feelsLike = parseFloat(cur.FeelsLikeC)
            condition = cur.weatherDesc ? cur.weatherDesc[0].value : ""

            var code = parseInt(cur.weatherCode)
            icon = weatherCodeToIcon(code)

            hourlyForecast = []
            if (data.weather && data.weather[0] && data.weather[0].hourly) {
                var hours = data.weather[0].hourly
                var now = new Date()
                var currentHour = now.getHours()
                var count = 0
                for (var i = 0; i < hours.length && count < 4; i++) {
                    var h = parseInt(hours[i].time) / 100
                    if (h >= currentHour || count > 0) {
                        hourlyForecast.push({
                            hour: formatHour(h),
                            temp: parseFloat(hours[i].tempC),
                            icon: weatherCodeToIcon(parseInt(hours[i].weatherCode))
                        })
                        count++
                    }
                }
            }
            updated()
        } catch (e) {
            console.warn("Lockscreen weather parse error:", e)
        }
    }

    function weatherCodeToIcon(code) {
        if (code === 113) return "󰅟"
        if (code === 116) return "󰖐"
        if (code === 119 || code === 122) return "󰖑"
        if (code === 143 || code === 248 || code === 260) return "󰖑"
        if (code === 176 || code === 263 || code === 266 || code === 293 || code === 296) return "󰖗"
        if (code === 299 || code === 302 || code === 305 || code === 308) return "󰖖"
        if (code === 311 || code === 314 || code === 356 || code === 359) return "󰖖"
        if (code === 317 || code === 320 || code === 350 || code === 362 || code === 365) return "󰙿"
        if (code === 323 || code === 326 || code === 329 || code === 332 || code === 335 || code === 338 || code === 368 || code === 371) return "󰤇"
        if (code === 374 || code === 377) return "󰤈"
        if (code === 200 || code === 386 || code === 389 || code === 392 || code === 395) return "󰖓"
        return "󰖐"
    }

    function formatHour(h) {
        if (h === 0) return "12am"
        if (h === 12) return "12pm"
        if (h < 12) return h + "am"
        return (h - 12) + "pm"
    }
}
