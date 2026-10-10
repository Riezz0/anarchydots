//@ pragma UseQApplication
import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "Modules"
import "Q-Apps/Lockscreen"

ShellRoot {
    id: root

    Theme { id: theme }

    property int barRadius: 6
    property real barOpacity: 1.0
    property int barBorderThickness: 0
    property string barPosition: "top"
    property int moduleBorderThickness: 0
    property real popupOpacity: 0.95
    property int popupBorderThickness: 0
    property int popupRadius: 6
    property bool widgetShadowEnabled: true
    property int widgetShadowX: 5
    property int widgetShadowY: 4
    property int widgetShadowRadius: 6
    property real widgetShadowOpacity: 0.63
    property real widgetOpacity: 1.0
    property int widgetRadius: 6
    property int widgetBorderThickness: 0
    property string themeSwitcherThumbnailShape: "portrait"
    property bool themeSwitcherOpen: false
    property string themeThumbnailStyle: "cover"
    property string workspaceIndicatorStyle: "numbers"
    property int hyprlandBorderThickness: 2
    property real hyprlandActiveOpacity: 0.6
    property real hyprlandInactiveOpacity: 0.2
    property int hyprlandRounding: 10
    property int hyprlandRoundingPower: 10
    property bool hyprlandBlurEnabled: true
    property int hyprlandBlurPasses: 3
    property int hyprlandBlurSize: 20
    property real hyprlandBlurVibrancy: 0.6
    property int hyprlandGapIn: 10
    property int hyprlandGapOut: 10
    property var barMonitors: []
    property int rofiBorderRadius: 5
    property int rofiBorderThickness: 2
    property int calendarX: 10
    property int calendarY: 210
    property int clockPopupX: -1
    property int clockPopupY: -1
    property int systemWidgetsX: -1
    property int systemWidgetsY: -1
    property string lockscreenWallpaper: ""
    property int lockscreenRadius: 10
    property int lockscreenBorderThickness: 2
    property bool lockscreenShowPassword: false
    property bool isLoadingSettings: true
    property bool popupStateReady: false

    readonly property string settingsPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"
    readonly property string themeSwitcherStatePath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/anarchy-theme-switcher.state"
    readonly property string popupStatePath:
        StandardPaths.writableLocation(StandardPaths.CacheLocation) + "/anarchy-bar-widgets-state.json"
    readonly property string hyprlandPatchPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/.hypr-themes/patch-look.sh"

    Component.onCompleted: loadSettings()

    function loadSettings() {
        settingsFile.reload()
    }

    function saveSettings() {
        if (isLoadingSettings) return
        var data = {
            "barRadius": barRadius,
            "barOpacity": barOpacity,
            "barBorderThickness": barBorderThickness,
            "barPosition": barPosition,
            "moduleBorderThickness": moduleBorderThickness,
            "popupOpacity": popupOpacity,
            "popupBorderThickness": popupBorderThickness,
            "popupRadius": popupRadius,
            "widgetShadowEnabled": widgetShadowEnabled,
            "widgetShadowX": widgetShadowX,
            "widgetShadowY": widgetShadowY,
            "widgetShadowRadius": widgetShadowRadius,
            "widgetShadowOpacity": widgetShadowOpacity,
            "widgetOpacity": widgetOpacity,
            "widgetRadius": widgetRadius,
            "widgetBorderThickness": widgetBorderThickness,
            "themeSwitcherThumbnailShape": themeSwitcherThumbnailShape,
            "themeThumbnailStyle": themeThumbnailStyle,
            "workspaceIndicatorStyle": workspaceIndicatorStyle,
            "hyprlandBorderThickness": hyprlandBorderThickness,
            "hyprlandActiveOpacity": hyprlandActiveOpacity,
            "hyprlandInactiveOpacity": hyprlandInactiveOpacity,
            "hyprlandRounding": hyprlandRounding,
            "hyprlandRoundingPower": hyprlandRoundingPower,
            "hyprlandBlurEnabled": hyprlandBlurEnabled,
            "hyprlandBlurPasses": hyprlandBlurPasses,
            "hyprlandBlurSize": hyprlandBlurSize,
            "hyprlandBlurVibrancy": hyprlandBlurVibrancy,
            "hyprlandGapIn": hyprlandGapIn,
            "hyprlandGapOut": hyprlandGapOut,
            "barMonitors": barMonitors.length > 0 ? barMonitors : undefined,
            "rofiBorderRadius": rofiBorderRadius,
            "rofiBorderThickness": rofiBorderThickness,
            "calendarX": calendarX,
            "calendarY": calendarY,
            "clockPopupX": clockPopupX,
            "clockPopupY": clockPopupY,
            "systemWidgetsX": systemWidgetsX,
            "systemWidgetsY": systemWidgetsY,
            "lockscreenWallpaper": lockscreenWallpaper,
                "lockscreenRadius": lockscreenRadius,
                "lockscreenBorderThickness": lockscreenBorderThickness,
                "lockscreenShowPassword": lockscreenShowPassword
        }
        settingsFile.setText(JSON.stringify(data, null, 2))
    }

    function saveSystemWidgetsPosition(x, y) {
        systemWidgetsX = Math.round(x)
        systemWidgetsY = Math.round(y)
        saveSettings()
    }

    function screenForName(name) {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function savePopupState() {
        if (!popupStateReady) return
        popupStateFile.setText(JSON.stringify({
            calendarOpen: calendarPopup.isOpen,
            calendarScreen: calendarPopup.targetScreen && calendarPopup.targetScreen.name
                ? calendarPopup.targetScreen.name : "",
            clockOpen: clockDetailsPopup.isOpen,
            clockScreen: clockDetailsPopup.targetScreen && clockDetailsPopup.targetScreen.name
                ? clockDetailsPopup.targetScreen.name : "",
            systemWidgetsOpen: systemWidgetsPopup.isOpen,
            systemWidgetsScreen: systemWidgetsPopup.targetScreen && systemWidgetsPopup.targetScreen.name
                ? systemWidgetsPopup.targetScreen.name : ""
        }, null, 2))
    }

    function restorePopupState(text) {
        try {
            var data = JSON.parse(text)
            calendarPopup.targetScreen = screenForName(data.calendarScreen || "")
            clockDetailsPopup.targetScreen = screenForName(data.clockScreen || "")
            systemWidgetsPopup.targetScreen = screenForName(data.systemWidgetsScreen || "")
            calendarPopup.isOpen = data.calendarOpen === true
            clockDetailsPopup.isOpen = data.clockOpen === true
            systemWidgetsPopup.isOpen = data.systemWidgetsOpen === true
        } catch (error) {
            console.warn("Anarchy-Bar: failed to restore widget state:", error)
        }
        popupStateReady = true
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        onFileChanged: {
            if (!isLoadingSettings) hyprlandPatchTimer.restart()
        }
        onLoaded: {
            if (settingsFile.text().length > 0) {
                try {
                    var data = JSON.parse(settingsFile.text())
                    if (data.barRadius !== undefined) root.barRadius = data.barRadius
                    if (data.barOpacity !== undefined) root.barOpacity = data.barOpacity
                    if (data.barBorderThickness !== undefined) root.barBorderThickness = data.barBorderThickness
                    if (data.barPosition !== undefined) root.barPosition = data.barPosition
                    if (data.moduleBorderThickness !== undefined) root.moduleBorderThickness = data.moduleBorderThickness
                    if (data.popupOpacity !== undefined) root.popupOpacity = data.popupOpacity
                    if (data.popupBorderThickness !== undefined) root.popupBorderThickness = data.popupBorderThickness
                    if (data.popupRadius !== undefined) root.popupRadius = data.popupRadius
                    if (data.widgetShadowEnabled !== undefined) root.widgetShadowEnabled = data.widgetShadowEnabled
                    if (data.widgetShadowX !== undefined) root.widgetShadowX = data.widgetShadowX
                    if (data.widgetShadowY !== undefined) root.widgetShadowY = data.widgetShadowY
                    if (data.widgetShadowRadius !== undefined) root.widgetShadowRadius = data.widgetShadowRadius
                    if (data.widgetShadowOpacity !== undefined) root.widgetShadowOpacity = data.widgetShadowOpacity
                    if (data.widgetOpacity !== undefined) root.widgetOpacity = data.widgetOpacity
                    if (data.widgetRadius !== undefined) root.widgetRadius = data.widgetRadius
                    if (data.widgetBorderThickness !== undefined) root.widgetBorderThickness = data.widgetBorderThickness
                    if (data.themeSwitcherThumbnailShape !== undefined) {
                        if (data.themeSwitcherThumbnailShape === "rounded-square")
                            root.themeSwitcherThumbnailShape = "square"
                        else if (data.themeSwitcherThumbnailShape === "rounded"
                                || data.themeSwitcherThumbnailShape === "vertical")
                            root.themeSwitcherThumbnailShape = "portrait"
                        else
                            root.themeSwitcherThumbnailShape = data.themeSwitcherThumbnailShape
                    } else if (data.themeThumbnailsCircular === true) {
                        root.themeSwitcherThumbnailShape = "circle"
                    }
                    if (data.themeThumbnailStyle !== undefined) root.themeThumbnailStyle = data.themeThumbnailStyle
                    if (data.workspaceIndicatorStyle !== undefined) root.workspaceIndicatorStyle = data.workspaceIndicatorStyle
                    if (data.hyprlandBorderThickness !== undefined) root.hyprlandBorderThickness = data.hyprlandBorderThickness
                    if (data.hyprlandActiveOpacity !== undefined) root.hyprlandActiveOpacity = data.hyprlandActiveOpacity
                    if (data.hyprlandInactiveOpacity !== undefined) root.hyprlandInactiveOpacity = data.hyprlandInactiveOpacity
                    if (data.hyprlandRounding !== undefined) root.hyprlandRounding = data.hyprlandRounding
                    if (data.hyprlandRoundingPower !== undefined) root.hyprlandRoundingPower = data.hyprlandRoundingPower
                    if (data.hyprlandBlurEnabled !== undefined) root.hyprlandBlurEnabled = data.hyprlandBlurEnabled
                    if (data.hyprlandBlurPasses !== undefined) root.hyprlandBlurPasses = data.hyprlandBlurPasses
                    if (data.hyprlandBlurSize !== undefined) root.hyprlandBlurSize = data.hyprlandBlurSize
                    if (data.hyprlandBlurVibrancy !== undefined) root.hyprlandBlurVibrancy = data.hyprlandBlurVibrancy
                    if (data.hyprlandGapIn !== undefined) root.hyprlandGapIn = data.hyprlandGapIn
                    if (data.hyprlandGapOut !== undefined) root.hyprlandGapOut = data.hyprlandGapOut
                    if (data.barMonitors !== undefined && data.barMonitors.length > 0) {
                        var available = []
                        for (var j = 0; j < Quickshell.screens.length; j++) {
                            var sn = Quickshell.screens[j]
                            if (sn && sn.name) available.push(sn.name)
                        }
                        var anyMatch = false
                        for (var k = 0; k < data.barMonitors.length; k++) {
                            if (available.indexOf(data.barMonitors[k]) !== -1) {
                                anyMatch = true
                                break
                            }
                        }
                        if (anyMatch) {
                            root.barMonitors = data.barMonitors
                        } else {
                            root.barMonitors = available
                        }
                    } else {
                        var detected = []
                        for (var i = 0; i < Quickshell.screens.length; i++) {
                            var s = Quickshell.screens[i]
                            if (s && s.name) detected.push(s.name)
                        }
                        root.barMonitors = detected
                    }
                    if (data.rofiBorderRadius !== undefined) root.rofiBorderRadius = data.rofiBorderRadius
                    if (data.rofiBorderThickness !== undefined) root.rofiBorderThickness = data.rofiBorderThickness
                    if (data.calendarX !== undefined) root.calendarX = data.calendarX
                    if (data.calendarY !== undefined) root.calendarY = data.calendarY
                    if (data.clockPopupX !== undefined) root.clockPopupX = data.clockPopupX
                    if (data.clockPopupY !== undefined) root.clockPopupY = data.clockPopupY
                    if (data.systemWidgetsX !== undefined) root.systemWidgetsX = data.systemWidgetsX
                    if (data.systemWidgetsY !== undefined) root.systemWidgetsY = data.systemWidgetsY
                    if (data.lockscreenWallpaper !== undefined) root.lockscreenWallpaper = data.lockscreenWallpaper
                    if (data.lockscreenRadius !== undefined) root.lockscreenRadius = data.lockscreenRadius
                    if (data.lockscreenBorderThickness !== undefined) root.lockscreenBorderThickness = data.lockscreenBorderThickness
                    if (data.lockscreenShowPassword !== undefined) root.lockscreenShowPassword = data.lockscreenShowPassword
                } catch (e) {
                    console.warn("Anarchy-Bar: failed to parse settings:", e)
                }
            }
            hyprlandPatchTimer.restart()
            isLoadingSettings = false
        }
    }

    FileView {
        id: popupStateFile
        path: root.popupStatePath
        watchChanges: false
        onLoaded: root.restorePopupState(text())
        onLoadFailed: error => {
            root.popupStateReady = true
            if (error !== FileViewError.FileNotFound)
                console.warn("Anarchy-Bar: failed to load widget state:", error)
        }
    }

    FileView {
        id: themeSwitcherStateFile
        path: root.themeSwitcherStatePath
        watchChanges: true
        onLoaded: root.themeSwitcherOpen = text().trim() === "open"
        onFileChanged: reload()
    }

    Process {
        command: ["bash", "-c", "mkdir -p ~/.cache; [ -e ~/.cache/anarchy-theme-switcher.state ] || printf 'closed\\n' > ~/.cache/anarchy-theme-switcher.state"]
        running: true
        onExited: themeSwitcherStateFile.reload()
    }

    onBarRadiusChanged: saveSettings()
    onBarOpacityChanged: saveSettings()
    onBarBorderThicknessChanged: saveSettings()
    onBarPositionChanged: saveSettings()
    onModuleBorderThicknessChanged: saveSettings()
    onPopupOpacityChanged: saveSettings()
    onPopupBorderThicknessChanged: saveSettings()
    onPopupRadiusChanged: saveSettings()
    onWidgetShadowEnabledChanged: saveSettings()
    onWidgetShadowXChanged: saveSettings()
    onWidgetShadowYChanged: saveSettings()
    onWidgetShadowRadiusChanged: saveSettings()
    onWidgetShadowOpacityChanged: saveSettings()
    onWidgetOpacityChanged: saveSettings()
    onWidgetRadiusChanged: saveSettings()
    onWidgetBorderThicknessChanged: saveSettings()
    onThemeSwitcherThumbnailShapeChanged: saveSettings()
    onThemeThumbnailStyleChanged: saveSettings()
    onWorkspaceIndicatorStyleChanged: saveSettings()
    onHyprlandBorderThicknessChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandActiveOpacityChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandInactiveOpacityChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandRoundingChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandRoundingPowerChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandBlurEnabledChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandBlurPassesChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandBlurSizeChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandBlurVibrancyChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandGapInChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onHyprlandGapOutChanged: {
        saveSettings()
        hyprlandPatchTimer.restart()
    }
    onBarMonitorsChanged: saveSettings()
    onRofiBorderRadiusChanged: {
        saveSettings()
        rofiPatchTimer.restart()
    }
    onRofiBorderThicknessChanged: {
        saveSettings()
        rofiPatchTimer.restart()
    }
    onLockscreenWallpaperChanged: saveSettings()
    onLockscreenRadiusChanged: saveSettings()
    onLockscreenBorderThicknessChanged: saveSettings()

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
        property var targetScreen: null
        function open(screen) {
            if (screen) targetScreen = screen
            else if (!targetScreen) targetScreen = root.screenForName("")
            isOpen = true
            root.savePopupState()
        }
        function close() {
            isOpen = false
            targetScreen = null
            root.savePopupState()
        }
    }

    Item {
        id: widgetsDrawer
        property bool isOpen: false
        property var targetScreen: null
        function open(screen) {
            if (screen) targetScreen = screen
            isOpen = true
        }
        function close() {
            isOpen = false
            targetScreen = null
        }
    }

    Item {
        id: clockDetailsPopup
        property bool isOpen: false
        property var targetScreen: null
        function open(screen) {
            if (screen) targetScreen = screen
            else if (!targetScreen) targetScreen = root.screenForName("")
            isOpen = true
            root.savePopupState()
        }
        function close() {
            isOpen = false
            targetScreen = null
            root.savePopupState()
        }
    }

    Item {
        id: systemWidgetsPopup
        property bool isOpen: false
        property var targetScreen: null
        function open(screen) {
            if (screen) targetScreen = screen
            else if (!targetScreen) targetScreen = root.screenForName("")
            isOpen = true
            root.savePopupState()
        }
        function close() {
            isOpen = false
            targetScreen = null
            root.savePopupState()
        }
    }

    Item {
        id: updatesPopup
        property bool isOpen: false
        function open() { isOpen = true }
        function close() { isOpen = false }
    }

    Item {
        id: salaatPopup
        property bool isOpen: false
        function open() { isOpen = true }
        function close() { isOpen = false }
    }

    Item {
        id: notificationsPopup
        property bool isOpen: false
        function open() { isOpen = true }
        function close() { isOpen = false }
    }

    Item {
        id: keybindsPopup
        property bool isOpen: false
        property string targetScreen: ""
        function open() { isOpen = true }
        function close() {
            isOpen = false
            targetScreen = ""
        }
    }

    Process {
        id: cmdProc
        running: false
    }

    Process {
        id: hyprlandPatchProc
        running: false
    }

    Process {
        id: hyprctlBorderProc
        running: false
    }

    Process {
        id: borderFilesProc
        running: false
    }

    Timer {
        id: hyprlandPatchTimer
        interval: 150
        repeat: false
        onTriggered: {
            var value = root.hyprlandBorderThickness.toString()
            if (hyprctlBorderProc.running)
                hyprctlBorderProc.running = false
            if (borderFilesProc.running)
                borderFilesProc.running = false

            hyprctlBorderProc.command = ["hyprctl", "eval", "hl.config({ general = { border_size = " + value + ", gaps_in = " + root.hyprlandGapIn + ", gaps_out = " + root.hyprlandGapOut + " }, decoration = { active_opacity = " + root.hyprlandActiveOpacity + ", inactive_opacity = " + root.hyprlandInactiveOpacity + ", rounding = " + root.hyprlandRounding + ", rounding_power = " + root.hyprlandRoundingPower + ", blur = { enabled = " + root.hyprlandBlurEnabled + ", passes = " + root.hyprlandBlurPasses + ", size = " + root.hyprlandBlurSize + ", vibrancy = " + root.hyprlandBlurVibrancy + " } } })"]
            hyprctlBorderProc.running = true

            var syncCommand = "for f in $HOME/.config/.hypr-themes/*/hyprlook; do " +
                "[ -f \"$f\" ] || continue; " +
                "sed -i -E 's/gaps_in[[:space:]]*=[[:space:]]*[0-9]+/gaps_in = " + root.hyprlandGapIn + "/g; " +
                "s/gaps_out[[:space:]]*=[[:space:]]*[0-9]+/gaps_out = " + root.hyprlandGapOut + "/g; " +
                "s/border_size[[:space:]]*=[[:space:]]*[0-9]+/border_size = " + value + "/g; " +
                "s/active_opacity[[:space:]]*=[[:space:]]*[0-9.]+/active_opacity = " + root.hyprlandActiveOpacity + "/g; " +
                "s/inactive_opacity[[:space:]]*=[[:space:]]*[0-9.]+/inactive_opacity = " + root.hyprlandInactiveOpacity + "/g; " +
                "s/rounding_power[[:space:]]*=[[:space:]]*[0-9]+/rounding_power = " + root.hyprlandRoundingPower + "/g; " +
                "s/rounding[[:space:]]*=[[:space:]]*[0-9]+/rounding = " + root.hyprlandRounding + "/g' \"$f\"; " +
                "sed -i -E '/blur[[:space:]]*=/,/},},/ { s/enabled[[:space:]]*=[[:space:]]*(true|false)/enabled = " + root.hyprlandBlurEnabled + "/g; s/passes[[:space:]]*=[[:space:]]*[0-9]+/passes = " + root.hyprlandBlurPasses + "/g; s/size[[:space:]]*=[[:space:]]*[0-9]+/size = " + root.hyprlandBlurSize + "/g; s/vibrancy[[:space:]]*=[[:space:]]*[0-9.]+/vibrancy = " + root.hyprlandBlurVibrancy + "/g; }' \"$f\"; done; " +
                "sed -i -E 's/gaps_in[[:space:]]*=[[:space:]]*[0-9]+/gaps_in = " + root.hyprlandGapIn + "/g; " +
                "s/gaps_out[[:space:]]*=[[:space:]]*[0-9]+/gaps_out = " + root.hyprlandGapOut + "/g; " +
                "s/border_size[[:space:]]*=[[:space:]]*[0-9]+/border_size = " + value + "/g; " +
                "s/active_opacity[[:space:]]*=[[:space:]]*[0-9.]+/active_opacity = " + root.hyprlandActiveOpacity + "/g; " +
                "s/inactive_opacity[[:space:]]*=[[:space:]]*[0-9.]+/inactive_opacity = " + root.hyprlandInactiveOpacity + "/g; " +
                "s/rounding_power[[:space:]]*=[[:space:]]*[0-9]+/rounding_power = " + root.hyprlandRoundingPower + "/g; " +
                "s/rounding[[:space:]]*=[[:space:]]*[0-9]+/rounding = " + root.hyprlandRounding + "/g' $HOME/.config/hypr/modules/look.lua; " +
                "sed -i -E '/blur[[:space:]]*=/,/},},/ { s/enabled[[:space:]]*=[[:space:]]*(true|false)/enabled = " + root.hyprlandBlurEnabled + "/g; s/passes[[:space:]]*=[[:space:]]*[0-9]+/passes = " + root.hyprlandBlurPasses + "/g; s/size[[:space:]]*=[[:space:]]*[0-9]+/size = " + root.hyprlandBlurSize + "/g; s/vibrancy[[:space:]]*=[[:space:]]*[0-9.]+/vibrancy = " + root.hyprlandBlurVibrancy + "/g; }' $HOME/.config/hypr/modules/look.lua; " +
                "bash " + root.hyprlandPatchPath + " --sync-all " + value + " " + root.hyprlandActiveOpacity + " " + root.hyprlandInactiveOpacity + " " + root.hyprlandRounding + " " + root.hyprlandRoundingPower + " " + root.hyprlandBlurEnabled + " " + root.hyprlandBlurPasses + " " + root.hyprlandBlurSize + " " + root.hyprlandBlurVibrancy + " " + root.hyprlandGapIn + " " + root.hyprlandGapOut + "; hyprctl reload"
            borderFilesProc.command = ["bash", "-c", syncCommand]
            borderFilesProc.running = true
        }
    }

    Process {
        id: rofiPatchProc
        running: false
        stdout: SplitParser { onRead: line => {} }
        stderr: SplitParser { onRead: line => {} }
    }

    Timer {
        id: rofiPatchTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (rofiPatchProc.running)
                rofiPatchProc.running = false

            var rofiDir = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace(/^file:\/\//, "") + "/.config/rofi/launcher"
            var rofiPath = rofiDir + "/launcher.rasi"
            var patchScript = rofiDir + "/patch-rofi.sh"
            rofiPatchProc.command = ["bash", patchScript, rofiPath, root.rofiBorderRadius.toString(), root.rofiBorderThickness.toString()]
            rofiPatchProc.running = true
        }
    }

    Bar {}
    Updates { id: updates }
    Salaat { id: salaat }
    Notifications { id: notifs }
    PowerMenu {}
    SettingsPopup {}
    CalendarTasks { id: calendarTasks }
    CalendarPopup {}
    SystemWidgetsPopup {}
    WidgetsDrawer {}
    UpdatesPopup {}
    SalaatPopup {}
    NotificationsPopup {}
    KeybindsPopup {}
    VolumeOSD { id: volumeOSD }
    ToastPopup {}
}
