// ═══════════════════════════════════════════════════════════════════════════════
// Weather Module - Quickshell Weather Integration
// ═══════════════════════════════════════════════════════════════════════════════
// Fetches weather data from wttr.in (free, no API key required).
// Auto-detects current city via IP geolocation.
//
// Usage in shell.qml:
//   Weather { id: weather }
//   weather.tempDisplay()       // "26°C"
//   weather.locationDisplay()   // "Cape Town, South Africa"
//   weather.shortCondition()    // "Partly cloudy"
//   weather.weatherIconText()   // Nerd Font weather icon
// ═══════════════════════════════════════════════════════════════════════════════

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: weatherRoot

    // ═══════════════════════════════════════════════════════════════════════════
    // Properties
    // ═══════════════════════════════════════════════════════════════════════════

    property string city:         ""
    property string country:      ""
    property string tempC:        "--"
    property string feelsLikeC:   "--"
    property string humidity:     "--"
    property string windSpeed:    "--"
    property string windDir:      "--"
    property string condition:    "Loading..."
    property string pressure:     "--"
    property string uvIndex:      "--"
    property string visibility:   "--"
    property string cloudCover:   "--"
    property string weatherIcon:  ""
    property bool   loaded:       false

    // ═══════════════════════════════════════════════════════════════════════════
    // Data Fetching
    // ═══════════════════════════════════════════════════════════════════════════

    Process {
        id:      weatherProc
        command: ["curl", "-s", "--max-time", "10", "https://wttr.in/?format=j1"]
        running: false

        property string buffer: ""

        stdout: SplitParser {
            onRead: line => {
                weatherProc.buffer += line + "\n"
            }
        }

        onRunningChanged: {
            if (!running) {
                weatherRoot.parseWeather(weatherProc.buffer)
                weatherProc.buffer = ""
            }
        }
    }

    // ── Refresh Timer ───────────────────────────────────────────────────────
    // Refresh every 15 minutes
    Timer {
        interval:         900000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: {
            if (!weatherProc.running) {
                weatherProc.buffer = ""
                weatherProc.running = true
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // Functions
    // ═══════════════════════════════════════════════════════════════════════════

    function parseWeather(jsonStr) {
        try {
            const data = JSON.parse(jsonStr)
            const cc   = data.current_condition[0]

            weatherRoot.tempC      = cc.temp_C
            weatherRoot.feelsLikeC = cc.FeelsLikeC
            weatherRoot.humidity   = cc.humidity
            weatherRoot.windSpeed  = cc.windspeedKmph
            weatherRoot.windDir    = cc.winddir16Point
            weatherRoot.condition  = cc.weatherDesc[0].value
            weatherRoot.pressure   = cc.pressure
            weatherRoot.uvIndex    = cc.uvIndex
            weatherRoot.visibility = cc.visibility
            weatherRoot.cloudCover = cc.cloudcover

            const area = data.nearest_area[0]
            weatherRoot.city    = area.areaName[0].value
            weatherRoot.country = area.country[0].value

            weatherRoot.weatherIcon = getWeatherIcon(cc.weatherCode)
            weatherRoot.loaded      = true
        } catch (e) {
            console.warn("Weather: failed to parse response:", e)
        }
    }

    function weatherIconText() {
        return weatherRoot.weatherIcon || "󰖐"
    }

    function tempDisplay() {
        return weatherRoot.tempC + "°C"
    }

    function locationDisplay() {
        if (weatherRoot.city && weatherRoot.country)
            return weatherRoot.city + ", " + weatherRoot.country
        return "Loading..."
    }

    function shortCondition() {
        return weatherRoot.condition
    }

    function refresh() {
        if (!weatherProc.running) {
            weatherProc.buffer = ""
            weatherProc.running = true
        }
    }

    // ── Weather Code → Nerd Font Icon ────────────────────────────────────────
    function getWeatherIcon(code) {
        const c = parseInt(code)

        // Clear
        if (c === 113)                          return "󰖨"
        // Partly cloudy
        if (c === 116)                          return "󰖏"
        // Cloudy / Overcast
        if (c === 119 || c === 122)             return "󰖐"
        // Fog / Mist
        if (c === 143 || c === 248 || c === 260) return "󰖌"
        // Light rain / Patchy rain
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314].includes(c))
            return "󰖒"
        // Heavy rain / Shower
        if ([353, 356, 359].includes(c))
            return "󰖒"
        // Snow / Sleet
        if ([350, 362, 365, 368, 371, 374, 377, 398, 401, 404, 407].includes(c))
            return "󰖓"
        // Thunderstorm
        if ([386, 389, 392, 395].includes(c))
            return "󰖓"

        return "󰖐"
    }
}