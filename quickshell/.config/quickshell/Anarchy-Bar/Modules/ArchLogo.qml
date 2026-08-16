import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Image {
    id: logo

    readonly property string logoPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Assets/arch.png"

    readonly property string logoUrl:
        logoPath.startsWith("file://") ? logoPath : "file://" + logoPath

    property int _reloadKey: 0

    source: logoUrl + "?v=" + _reloadKey
    cache: false
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true

    function reload() {
        _reloadKey++
    }

    FileView {
        path: logo.logoPath
        watchChanges: true
        onFileChanged: logo.reload()
    }
}
