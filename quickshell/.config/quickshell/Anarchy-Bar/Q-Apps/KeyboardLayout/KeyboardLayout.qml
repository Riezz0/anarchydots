import QtQuick
import QtCore
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Window {
    id: keyboardWindow

    property var targetScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property color background: "#1d2021"
    property color foreground: "#d5c4a1"
    property color muted: "#928374"
    property color accent: "#b8bb26"
    property color accent2: "#fabd2f"
    property color red: "#fb4934"
    property color keySurface: "#292929"
    property color keyBorder: "#504945"
    property var keyMap: ({})
    property var legendRows: []
    property var modifierItems: []
    property real keyboardHeight: 74
    property real keyboardUnit: Math.max(42, Math.min(84, (contentArea.width - 90) / 17))

    visible: true
    width: targetScreen ? Math.min(1450, Math.max(1100, targetScreen.width - 80)) : 1300
    height: targetScreen ? Math.min(820, Math.max(680, targetScreen.height - 100)) : 760
    x: targetScreen ? targetScreen.x + Math.round((targetScreen.width - width) / 2) : 0
    y: targetScreen ? targetScreen.y + Math.round((targetScreen.height - height) / 2) : 0
    title: "Arabic Keyboard Layout"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    FileView {
        id: layoutFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config/xkb/symbols/my_ar"
        watchChanges: true
        onLoaded: keyboardWindow.parseLayout(text())
        onFileChanged: keyboardWindow.parseLayout(text())
    }

    FileView {
        id: walFile
        path: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.cache/wal/colors.json"
        watchChanges: true
        onLoaded: keyboardWindow.loadColors()
        onFileChanged: keyboardWindow.loadColors()
    }

    // Pywal replaces this file atomically, so inotify may miss a theme change.
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: walFile.reload()
    }

    function loadColors() {
        try {
            var data = JSON.parse(walFile.text())
            background = data.special.background
            foreground = data.special.foreground
            muted = data.colors.color8
            accent = data.colors.color2
            accent2 = data.colors.color3
            red = data.colors.color1
            keySurface = Qt.darker(background, 1.16)
            keyBorder = data.colors.color8
        } catch (error) {}
    }

    function symbolValue(value) {
        var token = value.trim()
        var unicode = token.match(/^U([0-9A-Fa-f]+)$/)
        if (unicode) {
            var codePoint = parseInt(unicode[1], 16)
            var character = String.fromCodePoint(codePoint)
            if ((codePoint >= 0x064B && codePoint <= 0x065F) || codePoint === 0x0670)
                return "◌" + character
            return character
        }
        return token.replace(/^['"]|['"]$/g, "")
    }

    function isHaraka(value) {
        return /[\u064B-\u065F\u0670]/.test(value)
    }

    function rowWidth(row) {
        var total = (row.length - 1) * 6
        for (var i = 0; i < row.length; i++)
            total += row[i].width * keyboardUnit
        return total
    }

    function parseLayout(source) {
        var parsed = {}
        var expression = /key\s+<([A-Z0-9]+)>\s*\{\s*\[\s*([^,]+),\s*([^\]]+)\]/g
        var match
        while ((match = expression.exec(source)) !== null) {
            parsed[match[1]] = {
                normal: symbolValue(match[2]),
                shift: symbolValue(match[3])
            }
        }
        keyMap = parsed
        rebuildLegend()
    }

    function rebuildLegend() {
        var groupedEntries = []
        var modifiers = []
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
            var row = rows[rowIndex]
            var entries = []
            for (var keyIndex = 0; keyIndex < row.length; keyIndex++) {
                var item = row[keyIndex]
                if (item.special) {
                    modifiers.push(item.normal)
                    continue
                }
                var values = keyMap[item.id] || {}
                var normal = values.normal !== undefined ? values.normal : item.normal
                var shift = values.shift !== undefined && !/^[0-9]$/.test(values.shift) ? values.shift : item.shift
                entries.push({ label: item.label, normal: normal, shift: shift })
            }
            if (entries.length > 0)
                groupedEntries.push(entries)
        }
        legendRows = groupedEntries
        modifierItems = modifiers
    }

    function key(id, label, fallbackNormal, fallbackShift, width, fnLabel) {
        var values = keyMap[id] || {}
        var parsedShift = values.shift
        if (parsedShift !== undefined && /^[0-9]$/.test(parsedShift))
            parsedShift = fallbackShift
        return {
            id: id,
            label: label,
            normal: values.normal !== undefined ? values.normal : fallbackNormal,
            shift: parsedShift !== undefined ? parsedShift : fallbackShift,
            width: width || 1,
            fn: fnLabel || "",
            special: false,
            compact: false
        }
    }

    function special(label, width, compact) {
        return {
            id: label,
            label: "",
            normal: label,
            shift: "",
            width: width || 1,
            fn: "",
            special: true,
            compact: compact === true
        }
    }

    property var rows: [
        [special("ESC", 1.25), key("TLDE", "`", "ذ", "ّ"), key("AE01", "1", "١", "!", 1, "F1"), key("AE02", "2", "٢", "@", 1, "F2"), key("AE03", "3", "٣", "#", 1, "F3"), key("AE04", "4", "٤", "$", 1, "F4"), key("AE05", "5", "٥", "%", 1, "F5"), key("AE06", "6", "٦", "^", 1, "F6"), key("AE07", "7", "٧", "&", 1, "F7"), key("AE08", "8", "٨", "*", 1, "F8"), key("AE09", "9", "٩", "(", 1, "F9"), key("AE10", "0", "٠", ")", 1, "F10"), key("AE11", "-", "-", "_", 1, "F11"), key("AE12", "=", "=", "+", 1, "F12"), key("BKSL", "\\", "ّ", "|"), special("BACKSPACE", 1.75)],
        [special("TAB", 1.5), key("AD01", "Q", "ق", "ؤ"), key("AD02", "W", "و", "ئ"), key("AD03", "E", "ش", "÷"), key("AD04", "R", "ر", "×"), key("AD05", "T", "ت", "ط"), key("AD06", "Y", "ي", "ى"), key("AD07", "U", "ء", "ؤ"), key("AD08", "I", "إ", "آ"), key("AD09", "O", "ة", "أ"), key("AD10", "P", "ا", "ٱ"), special("[", 1), special("]", 1), special("\\", 1.5)],
        [special("CAPS LOCK", 1.75), key("AC01", "A", "ا", "ع"), key("AC02", "S", "س", "ص"), key("AC03", "D", "د", "ض"), key("AC04", "F", "ف", "-"), key("AC05", "G", "غ", "ْ"), key("AC06", "H", "ه", "ح"), key("AC07", "J", "ج", "'"), key("AC08", "K", "ك", "خ"), key("AC09", "L", "ل", "ؤ"), key("AC10", ";", "لا", "لآ"), key("AC11", "'", "لأ", "لإ"), special("ENTER", 2.25)],
        [special("SHIFT", 2.25), key("AB01", "Z", "ز", "ذ"), key("AB02", "X", "ظ", "ٌ"), key("AB03", "C", "ث", "ٍ"), key("AB04", "V", "ى", "ً"), key("AB05", "B", "ب", "ُ"), key("AB06", "N", "ن", "ِ"), key("AB07", "M", "م", "َ"), key("AB08", ",", ",", ":"), key("AB09", ".", ".", ">"), key("AB10", "/", "ٰ", "؟"), special("INS", 1), special("DEL", 1), special("SHIFT", 2.75)],
        [special("CTRL", 1.25), special("SUPER", 1.25), special("ALT", 1.25), special("SPACE", 6.25), special("ALT", 1.25), special("FN", 1.25), special("MENU", 1.25), special("CTRL", 1.25)]
    ]

    Component.onCompleted: {
        layoutFile.reload()
        walFile.reload()
        rebuildLegend()
        requestActivate()
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: keyboardWindow.background
            border.width: 0

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 14
            color: "transparent"
            border.width: 0
        }

        Item {
            id: contentArea
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            anchors.topMargin: 22
            anchors.bottomMargin: 20

            Row {
                id: headerRow
                width: parent.width
                height: 36
                anchors.top: parent.top

                Column {
                    spacing: 2
                    Text {
                        text: "ARABIC PHONETIC LAYOUT"
                        color: keyboardWindow.foreground
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        text: "my_ar  /  normal and shift symbols"
                        color: keyboardWindow.muted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }

                Item { width: parent.width - 300; height: 1 }

                Rectangle {
                    width: 72
                    height: 32
                    radius: 8
                    color: closeHover.containsMouse ? keyboardWindow.red : "transparent"
                    border.width: 1
                    border.color: closeHover.containsMouse ? keyboardWindow.red : keyboardWindow.keyBorder

                    Text {
                        anchors.centerIn: parent
                        text: "ESC  CLOSE"
                        color: closeHover.containsMouse ? keyboardWindow.background : keyboardWindow.muted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.bold: true
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }

            Column {
                id: keyboardArea
                anchors.top: headerRow.bottom
                anchors.topMargin: 18
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 6

                Repeater {
                    model: keyboardWindow.rows

                    Row {
                        required property var modelData
                        required property int index
                        width: keyboardWindow.rowWidth(modelData)
                        height: keyboardWindow.keyboardHeight
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Repeater {
                            model: parent.modelData

                            Rectangle {
                                required property var modelData
                                width: keyboardWindow.keyboardUnit * modelData.width
                                height: keyboardWindow.keyboardHeight
                                clip: true
                                radius: 7
                                color: keyHover.containsMouse ? Qt.lighter(keyboardWindow.keySurface, 1.18) : keyboardWindow.keySurface
                                border.width: 1
                                border.color: keyHover.containsMouse ? keyboardWindow.accent : keyboardWindow.keyBorder

                                Text {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.topMargin: 6
                                    anchors.leftMargin: 8
                                    text: modelData.special ? "" : modelData.label
                                    color: keyboardWindow.red
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.special ? modelData.normal : ""
                                    color: keyboardWindow.muted
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Math.max(9, Math.min(13, parent.width * 0.15))
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    visible: !modelData.special
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 6
                                    anchors.rightMargin: 6
                                    anchors.bottomMargin: 4
                                    height: 44
                                    text: modelData.normal
                                    color: keyboardWindow.foreground
                                    font.family: "Noto Naskh Arabic UI"
                                    font.pixelSize: keyboardWindow.isHaraka(modelData.normal) ? 42 : 25
                                    font.weight: Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: !modelData.special
                                    width: Math.min(parent.width * 0.42, 42)
                                    height: 30
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.topMargin: 4
                                    anchors.rightMargin: 5
                                    text: modelData.shift
                                    color: keyboardWindow.accent
                                    font.family: "Noto Naskh Arabic UI"
                                    font.pixelSize: keyboardWindow.isHaraka(modelData.shift) ? 36 : 25
                                    font.weight: Font.Normal
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: keyHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }

            /*
            GridLayout {
                    width: parent.width
                    columns: 7
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: keyboardWindow.legendItems

                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            radius: 7
                            color: legendHover.containsMouse ? Qt.lighter(keyboardWindow.keySurface, 1.18) : keyboardWindow.keySurface
                            border.width: 1
                            border.color: legendHover.containsMouse ? keyboardWindow.accent : keyboardWindow.keyBorder

                            Text {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 6
                                anchors.leftMargin: 9
                                text: modelData.label
                                color: keyboardWindow.red
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                anchors.bottomMargin: 5
                                spacing: 8

                                Text {
                                    width: (parent.width - parent.spacing) / 2
                                    text: modelData.normal
                                    color: keyboardWindow.foreground
                                    font.family: "KFGQPC Uthmanic Script HAFS"
                                    font.pixelSize: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: (parent.width - parent.spacing) / 2
                                    text: modelData.shift
                                    color: keyboardWindow.accent
                                    font.family: "KFGQPC Uthmanic Script HAFS"
                                    font.pixelSize: 24
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: legendHover
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: keyboardWindow.modifierItems

                        Rectangle {
                            required property string modelData
                            width: Math.max(70, modifierLabel.implicitWidth + 24)
                            height: 32
                            radius: 6
                            color: keyboardWindow.keySurface
                            border.width: 1
                            border.color: keyboardWindow.keyBorder

                            Text {
                                id: modifierLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: keyboardWindow.muted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }
            }
            */

            Row {
                id: legendRow
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 28

                Repeater {
                    model: [
                        { color: keyboardWindow.red, text: "English reference" },
                        { color: keyboardWindow.foreground, text: "Arabic (normal)" },
                        { color: keyboardWindow.accent, text: "Arabic (shift)" }
                    ]

                    Row {
                        required property var modelData
                        spacing: 8

                        Rectangle {
                            width: 12
                            height: 20
                            radius: 6
                            color: modelData.color
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            color: keyboardWindow.muted
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Qt.quit()
    }
}
