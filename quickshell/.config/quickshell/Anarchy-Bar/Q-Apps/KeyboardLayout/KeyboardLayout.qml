import QtQuick
import QtCore
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
    property real keyUnit: Math.min(76, (width - 140) / 17.4)
    property real keyHeight: Math.max(64, Math.min(86, keyUnit * 1.12))

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
        requestActivate()
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: keyboardWindow.background
        border.width: 2
        border.color: keyboardWindow.accent

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: 14
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(keyboardWindow.foreground.r, keyboardWindow.foreground.g, keyboardWindow.foreground.b, 0.08)
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
                id: keyboardStack
                width: keyboardWindow.keyUnit * 17 + 64
                x: (parent.width - width) / 2
                y: headerRow.height + 18
                spacing: 4

                Repeater {
                    model: keyboardWindow.rows

                    Row {
                        required property int index
                        required property var modelData
                        anchors.left: parent.left
                        spacing: 4

                        Repeater {
                            model: parent.modelData

                            Rectangle {
                                required property var modelData
                                width: keyboardWindow.keyUnit * modelData.width + 6 * (modelData.width - 1)
                                height: modelData.compact ? keyboardWindow.keyHeight * 0.68 : keyboardWindow.keyHeight
                                radius: 7
                                color: keyHover.containsMouse ? Qt.lighter(keyboardWindow.keySurface, 1.18) : keyboardWindow.keySurface
                                border.width: 1
                                border.color: keyHover.containsMouse ? keyboardWindow.accent : keyboardWindow.keyBorder

                                Text {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.leftMargin: 8
                                    anchors.topMargin: 5
                                    text: modelData.label
                                    color: keyboardWindow.red
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Math.max(9, keyboardWindow.keyUnit * 0.16)
                                    font.bold: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.normal
                                    color: keyboardWindow.foreground
                                    font.family: modelData.special ? "JetBrainsMono Nerd Font" : "KFGQPC Uthmanic Script HAFS"
                                    font.pixelSize: modelData.special ? Math.max(10, keyboardWindow.keyUnit * 0.17) : Math.max(28, keyboardWindow.keyUnit * 0.46)
                                    font.weight: modelData.special ? Font.DemiBold : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 5
                                    text: modelData.fn
                                    visible: modelData.fn.length > 0
                                    color: keyboardWindow.muted
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Math.max(9, keyboardWindow.keyUnit * 0.15)
                                }

                                Text {
                                    width: parent.width * 0.52
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.rightMargin: 8
                                    anchors.bottomMargin: 5
                                    text: modelData.shift
                                    visible: !modelData.special
                                    color: keyboardWindow.accent
                                    font.family: "KFGQPC Uthmanic Script HAFS"
                                    font.pixelSize: Math.max(24, keyboardWindow.keyUnit * 0.42)
                                    font.weight: Font.Normal
                                    font.bold: false
                                    horizontalAlignment: Text.AlignRight
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

            Row {
                id: legendRow
                y: keyboardStack.y + keyboardStack.height + 18
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
