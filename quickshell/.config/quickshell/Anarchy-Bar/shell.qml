import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "Modules"

ShellRoot {
    id: root

    Theme { id: theme }

    property int barRadius: 6
    property real barOpacity: 1.0
    property int barBorderThickness: 0
    property int moduleBorderThickness: 0
    property var barMonitors: []

    readonly property string settingsPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"

    Component.onCompleted: loadSettings()

    function loadSettings() {
        settingsFile.reload()
    }

    function saveSettings() {
        var data = {
            "barRadius": barRadius,
            "barOpacity": barOpacity,
            "barBorderThickness": barBorderThickness,
            "moduleBorderThickness": moduleBorderThickness,
            "barMonitors": barMonitors
        }
        settingsFile.setText(JSON.stringify(data, null, 2))
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: false
        onLoaded: {
            if (settingsFile.text().length > 0) {
                try {
                    var data = JSON.parse(settingsFile.text())
                    if (data.barRadius !== undefined) root.barRadius = data.barRadius
                    if (data.barOpacity !== undefined) root.barOpacity = data.barOpacity
                    if (data.barBorderThickness !== undefined) root.barBorderThickness = data.barBorderThickness
                    if (data.moduleBorderThickness !== undefined) root.moduleBorderThickness = data.moduleBorderThickness
                    if (data.barMonitors !== undefined) root.barMonitors = data.barMonitors
                } catch (e) {
                    console.warn("Anarchy-Bar: failed to parse settings:", e)
                }
            }
        }
    }

    onBarRadiusChanged: saveSettings()
    onBarOpacityChanged: saveSettings()
    onBarBorderThicknessChanged: saveSettings()
    onModuleBorderThicknessChanged: saveSettings()
    onBarMonitorsChanged: saveSettings()

    function getMonitorName(monitor) {
        if (monitor && monitor.name) return monitor.name
        return ""
    }

    function isMonitorEnabled(monitor) {
        if (barMonitors.length === 0) return true
        var name = getMonitorName(monitor)
        return barMonitors.indexOf(name) !== -1
    }

    function toggleMonitor(monitor) {
        var name = getMonitorName(monitor)
        var idx = barMonitors.indexOf(name)
        if (idx === -1) {
            barMonitors.push(name)
        } else {
            barMonitors.splice(idx, 1)
        }
        barMonitorsChanged()
    }

    Item {
        id: powerMenu
        property bool isOpen: false
        property var targetScreen: null
        function open(screen) {
            targetScreen = screen
            isOpen = true
        }
        function close() {
            isOpen = false
            targetScreen = null
        }
        function runCmd(cmd) {
            cmdProc.command = ["sh", "-c", cmd]
            cmdProc.running = true
            close()
        }
    }

    Item {
        id: settingsPopup
        property bool isOpen: false
        property var targetScreen: null
        function open(screen) {
            targetScreen = screen
            isOpen = true
        }
        function close() {
            isOpen = false
            targetScreen = null
        }
    }

    Item {
        id: calendarPopup
        property bool isOpen: false
        function open() { isOpen = true }
        function close() { isOpen = false }
    }

    Process {
        id: cmdProc
        running: false
    }

    Bar {}
    PowerMenu {}
    SettingsPopup {}
    CalendarPopup {}
}
