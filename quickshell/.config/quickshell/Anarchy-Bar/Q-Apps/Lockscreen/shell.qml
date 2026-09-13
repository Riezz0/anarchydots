import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

ShellRoot {
    id: lockRoot

    Theme { id: theme }

    property int barRadius: 10
    property int popupBorderThickness: 2
    property string lockscreenWallpaper: ""
    property bool lockscreenShowPassword: false

    property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation)

    function expandPath(path) {
        if (path.startsWith("~")) return homeDir + path.substring(1)
        return path
    }

    Lock {
        id: lock
        wallpaperPath: expandPath(lockRoot.lockscreenWallpaper)
        barRadius: lockRoot.barRadius
        popupBorderThickness: lockRoot.popupBorderThickness
        showPassword: lockRoot.lockscreenShowPassword
        notifData: notifReader.notifications
    }

    property string cacheDir: StandardPaths.writableLocation(StandardPaths.CacheLocation).toString().replace(/^file:\/\//, "")

    FileView {
        id: notifFile
        path: lockRoot.cacheDir + "/notifications.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: notifReader.parse(text())
    }

    QtObject {
        id: notifReader
        property var notifications: []
        function parse(text) {
            try {
                var data = JSON.parse(text)
                if (data && data.length > 0) {
                    notifReader.notifications = data
                } else {
                    notifReader.notifications = []
                }
            } catch (e) {
                notifReader.notifications = []
            }
        }
    }

    FileView {
        id: settingsFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (text().length > 0) {
                try {
                    var data = JSON.parse(text())
                    var newRadius = data.lockscreenRadius !== undefined ? data.lockscreenRadius : 10
                    var newBorder = data.lockscreenBorderThickness !== undefined ? data.lockscreenBorderThickness : 2
                    var newWallpaper = data.lockscreenWallpaper !== undefined ? data.lockscreenWallpaper : ""
                    var newShowPassword = data.lockscreenShowPassword !== undefined ? data.lockscreenShowPassword : false
                    if (lockRoot.barRadius !== newRadius) lockRoot.barRadius = newRadius
                    if (lockRoot.popupBorderThickness !== newBorder) lockRoot.popupBorderThickness = newBorder
                    if (lockRoot.lockscreenWallpaper !== newWallpaper) lockRoot.lockscreenWallpaper = newWallpaper
                    if (lockRoot.lockscreenShowPassword !== newShowPassword) lockRoot.lockscreenShowPassword = newShowPassword
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: settingsFile.reload()
    }
}
