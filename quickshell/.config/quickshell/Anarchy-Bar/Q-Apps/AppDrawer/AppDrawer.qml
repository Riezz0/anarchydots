import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: drawer

    readonly property int cardWidth: 460
    readonly property int cardHeight: 408
    readonly property int rowHeight: 52
    readonly property string wallpaperPath: "file:///home/riezzo/.config/activebg/Wall.png"

    property string cursorMonitor: ""
    property string iconThemeName: "GruvboxDark-Icons"
    readonly property string iconThemePath:
        StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/icons/" + iconThemeName

    property color background: "#202020"
    property color foreground: "#eeeeee"
    property color muted: "#a0a0a0"
    property color accent: "#89b4fa"
    property color highlightColor: "#a6e3a1"
    property color surface: "#303030"
    property color border: "#555555"
    property var allApplications: []
    property var filteredApplications: []

    function monitorForCursor() {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === cursorMonitor)
                return Quickshell.screens[i]
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    screen: monitorForCursor()
    visible: cursorMonitor.length > 0
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    focusable: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function applyWalColors() {
        try {
            var data = JSON.parse(walColors.text())
            background = data.special.background
            foreground = data.special.foreground
            muted = data.colors.color8
            accent = data.colors.color4
            highlightColor = data.colors.color2
            surface = data.colors.color0
            border = data.colors.color4
        } catch (e) {
            console.warn("AppDrawer: failed to parse pywal colors:", e)
        }
    }

    function refreshApplications() {
        var entries = DesktopEntries.applications.values
        var apps = []
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i]
            if (!entry || entry.noDisplay)
                continue
            apps.push({
                entry: entry,
                name: entry.name,
                description: entry.genericName || entry.comment || ""
            })
        }
        apps.sort(function(a, b) { return a.name.localeCompare(b.name) })
        allApplications = apps
        filterApplications()
    }

    function filterApplications() {
        var query = searchField.text.trim().toLowerCase()
        if (!query) {
            filteredApplications = allApplications
            return
        }

        var matches = []
        for (var i = 0; i < allApplications.length; i++) {
            var app = allApplications[i]
            var haystack = [app.name, app.description,
                            app.entry ? app.entry.name : "",
                            app.entry ? app.entry.genericName : "",
                            app.entry ? app.entry.comment : "",
                            app.entry && app.entry.keywords ? app.entry.keywords.join(" ") : ""]
                .join(" ").toLowerCase()
            if (haystack.indexOf(query) !== -1)
                matches.push(app)
        }
        filteredApplications = matches
    }

    function launch(entry) {
        if (!entry)
            return
        entry.entry.execute()
        Qt.quit()
    }

    FileView {
        id: walColors
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"
        watchChanges: true
        onLoaded: drawer.applyWalColors()
        onFileChanged: drawer.applyWalColors()
    }

    FileView {
        id: iconThemeFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/current_icon_theme.txt"
        watchChanges: true
        onLoaded: drawer.loadIconTheme()
        onFileChanged: drawer.loadIconTheme()
    }

    function loadIconTheme() {
        var selected = iconThemeFile.text().trim()
        if (selected.length > 0)
            iconThemeName = selected
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: walColors.reload()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: iconThemeFile.reload()
    }

    Process {
        id: cursorProcess
        command: ["bash", "-c", "bash ~/.config/quickshell/Anarchy-Bar/Scripts/detect-cursor-monitor.sh"]
        running: true
        stdout: StdioCollector {
            id: cursorOutput
            onStreamFinished: drawer.cursorMonitor = cursorOutput.text.trim()
        }
    }

    Component.onCompleted: {
        drawer.refreshApplications()
        searchField.forceActiveFocus()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { drawer.refreshApplications() }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(drawer.cardWidth, drawer.width - 28)
        height: Math.min(drawer.cardHeight, drawer.height - 28)
        radius: 9
        color: Qt.rgba(drawer.background.r, drawer.background.g,
                       drawer.background.b, 0.94)
        border.color: drawer.border
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 102
                radius: 6
                clip: true
                color: drawer.surface
                border.color: Qt.rgba(drawer.foreground.r, drawer.foreground.g,
                                      drawer.foreground.b, 0.65)
                border.width: 2

                Image {
                    anchors.fill: parent
                    source: drawer.wallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(drawer.background.r, drawer.background.g,
                                   drawer.background.b, 0.22)
                }

                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: 35
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: drawer.foreground
                    selectionColor: drawer.accent
                    selectedTextColor: drawer.background
                    font.pixelSize: 16
                    font.family: "JetBrainsMono Nerd Font"
                    clip: true
                    focus: true
                    onTextChanged: {
                        drawer.filterApplications()
                        appList.currentIndex = 0
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            appList.incrementCurrentIndex()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            appList.decrementCurrentIndex()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            drawer.launch(drawer.filteredApplications[appList.currentIndex])
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            Qt.quit()
                            event.accepted = true
                        }
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search..."
                        color: Qt.rgba(drawer.muted.r, drawer.muted.g,
                                      drawer.muted.b, 0.88)
                        font: searchField.font
                        visible: !searchField.text
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: -26
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: drawer.muted
                        font.pixelSize: 20
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }

            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: drawer.filteredApplications
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: delegateRoot
                    required property var modelData
                    required property int index
                    readonly property bool highlighted:
                        delegateMouse.containsMouse || appList.currentIndex === index
                    width: appList.width
                    height: drawer.rowHeight
                    radius: 4
                        color: highlighted
                            ? Qt.rgba(drawer.highlightColor.r, drawer.highlightColor.g,
                                  drawer.highlightColor.b, 1.0)
                        : Qt.rgba(drawer.foreground.r, drawer.foreground.g,
                                  drawer.foreground.b, 0.06)

                    IconImage {
                        id: appIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        source: delegateRoot.resolvedIcon
                        asynchronous: true
                    }

                    property string resolvedIcon: ""

                    Process {
                        id: iconLookup
                        command: ["bash", "-c",
                            "themeRoot=\"$1\"; icon=\"$2\"; themeName=\"$3\"; " +
                            "if [ -f \"$icon\" ]; then printf 'file://%s' \"$icon\"; exit 0; fi; " +
                            "for root in \"$themeRoot\" \"$HOME/.icons/$themeName\" \"$HOME/.icons/default\" /usr/share/icons/hicolor /usr/share/icons/Adwaita /usr/share/icons/breeze /usr/share/icons/breeze-dark; do " +
                            "for ext in svg png xpm; do " +
                            "file=$(find -L \"$root\" -type f -iname \"$icon.$ext\" -print -quit 2>/dev/null); " +
                            "if [ -f \"$file\" ]; then printf 'file://%s' \"$file\"; exit 0; fi; " +
                            "done; done; " +
                            "for root in \"$themeRoot\" \"$HOME/.icons/$themeName\" \"$HOME/.icons/default\" /usr/share/icons/hicolor /usr/share/icons/Adwaita /usr/share/icons/breeze /usr/share/icons/breeze-dark; do " +
                            "file=$(find -L \"$root\" -type f -iname 'applications-utilities.svg' -print -quit 2>/dev/null); " +
                            "if [ -f \"$file\" ]; then printf 'file://%s' \"$file\"; exit 0; fi; " +
                            "done", "icon-resolver", drawer.iconThemePath, modelData.entry.icon, drawer.iconThemeName]
                        running: true
                        stdout: StdioCollector {
                            id: iconOutput
                            onStreamFinished: {
                                delegateRoot.resolvedIcon = iconOutput.text.trim()
                            }
                        }
                    }

                    Connections {
                        target: drawer
                        function onIconThemeNameChanged() {
                            iconLookup.running = false
                            iconLookup.running = true
                        }
                    }

                    Text {
                        anchors.left: appIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        text: modelData.name
                        color: delegateRoot.highlighted ? drawer.background : drawer.foreground
                        font.pixelSize: 14
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.left: appIcon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        text: modelData.description
                        color: delegateRoot.highlighted ? drawer.background : drawer.muted
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: drawer.launch(modelData)
                        onEntered: appList.currentIndex = index
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: appList.contentHeight > appList.height
                        ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }
        }
    }

}
