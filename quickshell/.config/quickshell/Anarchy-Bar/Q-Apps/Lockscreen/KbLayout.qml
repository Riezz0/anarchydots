import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: kbRoot

    property string layout: "US"

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: detectLayout()
        Component.onCompleted: detectLayout()
    }

    Process {
        id: hyprProc
        command: ["bash", "-c", "hyprctl devices -j 2>/dev/null | python3 -c \"import sys,json; d=json.load(sys.stdin); kbs=[k for k in d.get('keyboards',[])]; print(kbs[0].get('active_keymap','US') if kbs else 'US')\" 2>/dev/null || echo US"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var l = line.trim()
                if (l.length > 0 && l.length < 10) kbRoot.layout = l.substring(0, 2).toUpperCase()
            }
        }
    }

    Process {
        id: swayProc
        command: ["bash", "-c", "swaymsg -t get_inputs 2>/dev/null | python3 -c \"import sys,json; d=json.load(sys.stdin); x=[i for i in d if i.get('type')=='keyboard']; print(x[0].get('xkb_active_layout_name','US') if x else 'US')\" 2>/dev/null || echo US"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var l = line.trim()
                if (l.length > 0 && l.length < 10) kbRoot.layout = l.substring(0, 2).toUpperCase()
            }
        }
    }

    Process {
        id: niriProc
        command: ["bash", "-c", "niri msg -j keyboard-layouts 2>/dev/null | python3 -c \"import sys,json; d=json.load(sys.stdin); idx=d.get('names',['US']).index(d.get('current','US')) if 'current' in d else 0; print(d.get('names',['US'])[idx])\" 2>/dev/null || echo US"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var l = line.trim()
                if (l.length > 0 && l.length < 10) kbRoot.layout = l.substring(0, 2).toUpperCase()
            }
        }
    }

    function detectLayout() {
        if (!hyprProc.running) hyprProc.running = true
        if (!swayProc.running) swayProc.running = true
        if (!niriProc.running) niriProc.running = true
    }
}
