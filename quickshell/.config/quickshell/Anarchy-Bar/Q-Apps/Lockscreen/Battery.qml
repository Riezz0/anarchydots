import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: batRoot

    property int capacity: 0
    property string status: "Unknown"
    property bool charging: status.toLowerCase().includes("charging")
    property string icon: {
        if (charging) return "󰂄"
        if (capacity >= 90) return "󰁹"
        if (capacity >= 70) return "󰂁"
        if (capacity >= 50) return "󰁿"
        if (capacity >= 30) return "󰁽"
        if (capacity >= 15) return "󰁻"
        return "󰂃"
    }
    property color dynamicColor: {
        if (charging) return Qt.color(0.4, 0.8, 0.5)
        if (capacity >= 50) return Qt.color(0.6, 0.85, 0.4)
        if (capacity >= 20) return Qt.color(0.9, 0.75, 0.3)
        return Qt.color(0.9, 0.35, 0.35)
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: batProc.running = true
        Component.onCompleted: batProc.running = true
    }

    Process {
        id: batProc
        command: ["bash", "-c", "upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null || echo 'N/A'"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("percentage:")) {
                    var val = line.split(":")[1].trim().replace("%", "")
                    var num = parseInt(val)
                    if (!isNaN(num)) batRoot.capacity = num
                }
                if (line.includes("state:")) {
                    batRoot.status = line.split(":")[1].trim()
                }
            }
        }
    }
}
