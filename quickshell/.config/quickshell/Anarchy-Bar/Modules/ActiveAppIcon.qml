import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

Item {
    id: activeApp

    property var hostWindow: null
    property real anchorX: 0
    property int cornerRadius: 10
    property string iconSource: ""
    property string applicationName: ""

    function desktopEntryForClass(windowClass) {
        const normalizedClass = windowClass.toLowerCase()
        const entries = DesktopEntries.applications.values

        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            if (entry && entry.startupClass
                    && entry.startupClass.toLowerCase() === normalizedClass)
                return entry
        }

        return DesktopEntries.heuristicLookup(windowClass)
    }

    function updateFromWindow(info) {
        const workspaceName = info.workspace && info.workspace.name
                ? info.workspace.name : ""

        // Scratchpads live on Hyprland special workspaces; don't show their icons.
        if (workspaceName.indexOf("special:") === 0) {
            iconSource = ""
            applicationName = ""
            return
        }

        const windowClass = info.class || info.initialClass || ""
        if (!windowClass) {
            iconSource = ""
            applicationName = ""
            return
        }

        const entry = desktopEntryForClass(windowClass)
        const iconName = entry && entry.icon ? entry.icon : windowClass.toLowerCase()
        let resolvedIcon = iconName.startsWith("/")
                ? "file://" + iconName : Quickshell.iconPath(iconName, true)

        if (!resolvedIcon)
            resolvedIcon = Quickshell.iconPath(windowClass.toLowerCase(), true)
        if (!resolvedIcon && windowClass.toLowerCase() === "kitty")
            resolvedIcon = "file:///usr/share/icons/hicolor/scalable/apps/kitty.svg"
        if (!resolvedIcon)
            resolvedIcon = Quickshell.iconPath("application-x-executable")

        iconSource = resolvedIcon
        applicationName = entry && entry.name ? entry.name : windowClass
    }

    function refreshActiveWindow() {
        if (activeWindowProc.running)
            return
        activeWindowProc.buffer = ""
        activeWindowProc.running = true
    }

    Process {
        id: activeWindowProc
        command: ["hyprctl", "activewindow", "-j"]
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => activeWindowProc.buffer += data
        }

        onRunningChanged: {
            if (running)
                return

            try {
                activeApp.updateFromWindow(JSON.parse(buffer || "{}"))
            } catch (error) {
                activeApp.iconSource = ""
                activeApp.applicationName = ""
                console.warn("Anarchy-Bar: failed to read active window:", error)
            }
            buffer = ""
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: activeApp.refreshActiveWindow()
    }

    visible: iconSource.length > 0
    width: visible ? 42 : 0
    height: 42
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
        anchors.fill: parent
        radius: activeApp.cornerRadius
        color: "transparent"

        IconImage {
            anchors.centerIn: parent
            width: 24
            height: 24
            source: activeApp.iconSource
            asynchronous: true
        }

        MouseArea {
            id: activeAppMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }

    Loader {
        id: activeAppTooltip
        source: "BarTooltip.qml"
        property bool tooltipShown: activeAppMouse.containsMouse
        property real tooltipAnchorX: activeApp.anchorX
        Binding { target: activeAppTooltip.item; property: "hostWindow"; value: activeApp.hostWindow; when: activeAppTooltip.item !== null }
        Binding { target: activeAppTooltip.item; property: "shown"; value: activeAppTooltip.tooltipShown; when: activeAppTooltip.item !== null }
        Binding { target: activeAppTooltip.item; property: "anchorX"; value: activeAppTooltip.tooltipAnchorX; when: activeAppTooltip.item !== null }
        Binding { target: activeAppTooltip.item; property: "title"; value: activeApp.applicationName; when: activeAppTooltip.item !== null }
        Binding { target: activeAppTooltip.item; property: "details"; value: "Active application"; when: activeAppTooltip.item !== null }
    }
}
