import QtQuick
import Quickshell
import Quickshell.Io
import "Modules"

ShellRoot {
    id: root

    Theme { id: theme }

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

    Process {
        id: cmdProc
        running: false
    }

    Bar {}
    PowerMenu {}
}
