import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

ShellRoot {
    id: lockRoot

    Theme { id: theme }

    property int barRadius: 10
    property int popupBorderThickness: 2

    Lock { id: lock }

    FileView {
        id: settingsFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Settings/bar.json"
        watchChanges: true
        onLoaded: {
            if (text().length > 0) {
                try {
                    var data = JSON.parse(text())
                    if (data.barRadius !== undefined) lockRoot.barRadius = data.barRadius
                    if (data.popupBorderThickness !== undefined) lockRoot.popupBorderThickness = data.popupBorderThickness
                } catch (e) {}
            }
        }
    }
}
