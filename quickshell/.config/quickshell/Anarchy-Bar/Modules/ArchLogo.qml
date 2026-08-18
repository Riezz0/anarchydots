import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Rectangle {
    id: logoContainer

    readonly property string logoPath:
        StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/quickshell/Anarchy-Bar/Assets/arch.png"

    readonly property string logoUrl:
        logoPath.startsWith("file://") ? logoPath : "file://" + logoPath

    property int _reloadKey: 0

    width: 40
    height: 40
    radius: root.barRadius
    color: "transparent"

    Image {
        anchors.centerIn: parent
        source: logoContainer.logoUrl + "?v=" + logoContainer._reloadKey
        cache: false
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        width: 30
        height: 30
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: settingsPopup.isOpen ? settingsPopup.close() : settingsPopup.open()
    }

    function reload() {
        _reloadKey++
    }

    FileView {
        path: logoContainer.logoPath
        watchChanges: true
        onFileChanged: logoContainer.reload()
    }
}
