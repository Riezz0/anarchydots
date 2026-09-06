import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: freezeRoot

    property var screenshots: ({})

    signal captureComplete()

    function captureAll(screens) {
        var pending = screens.length
        if (pending === 0) {
            captureComplete()
            return
        }
        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i]
            var name = screen.name || ("screen" + i)
            captureScreen(name, function(scrName) {
                return function() {
                    pending--
                    if (pending <= 0) captureComplete()
                }
            }(name))
        }
    }

    function captureScreen(screenName, callback) {
        var proc = Qt.createQmlObject(`
            import QtQuick
            import Quickshell
            import Quickshell.Io
            Process {
                id: freezeProc
                command: ["grim", "-o", "${screenName}", "/tmp/lockscreen_freeze_${screenName}.png"]
                running: false
                onRunningChanged: {
                    if (!running) {
                        if (callback) callback()
                        freezeProc.destroy()
                    }
                }
            }
        `, freezeRoot)
        proc.running = true
    }

    function clearAll() {
        for (var key in screenshots) {
            var proc = Qt.createQmlObject(`
                import QtQuick
                import Quickshell
                import Quickshell.Io
                Process {
                    running: false
                    command: ["rm", "-f", "/tmp/lockscreen_freeze_${key}.png"]
                    Component.onCompleted: running = true
                }
            `, freezeRoot)
        }
        screenshots = {}
    }

    function getScreenshotPath(screenName) {
        return "/tmp/lockscreen_freeze_" + screenName + ".png"
    }
}
