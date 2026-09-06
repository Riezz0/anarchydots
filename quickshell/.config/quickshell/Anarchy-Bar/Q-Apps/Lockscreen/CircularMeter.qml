import QtQuick

Item {
    id: meter

    property string label: ""
    property string value: ""
    property string subText: ""
    property real progress: 0
    property color meterColor: theme.color4
    property real maxValue: 100

    width: 95
    height: 115

    Canvas {
        id: canvas
        anchors.centerIn: parent
        width: 95
        height: 95

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var r = 38
            var lw = 6

            // Background track
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.strokeStyle = Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.5)
            ctx.lineWidth = lw
            ctx.lineCap = "round"
            ctx.stroke()

            // Progress arc
            var frac = Math.min(Math.max(meter.progress / meter.maxValue, 0), 1)
            if (frac > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac)
                ctx.strokeStyle = meter.meterColor
                ctx.lineWidth = lw
                ctx.lineCap = "round"
                ctx.stroke()
            }

            // Tick marks
            for (var i = 0; i < 12; i++) {
                var tickAngle = (i / 12) * Math.PI * 2 - Math.PI / 2
                var innerR = r - lw / 2 - 2
                var outerR = r - lw / 2 - 5
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(tickAngle) * innerR, cy + Math.sin(tickAngle) * innerR)
                ctx.lineTo(cx + Math.cos(tickAngle) * outerR, cy + Math.sin(tickAngle) * outerR)
                ctx.strokeStyle = Qt.rgba(theme.color7.r, theme.color7.g, theme.color7.b, 0.3)
                ctx.lineWidth = 1
                ctx.stroke()
            }
        }

        Connections {
            target: meter
            function onProgressChanged() { canvas.requestPaint() }
            function onMeterColorChanged() { canvas.requestPaint() }
        }

        Component.onCompleted: canvas.requestPaint()
    }

    // Value text centered in circle
    Text {
        anchors.centerIn: canvas
        text: meter.value
        font.pixelSize: 20
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: theme.foreground
        z: 1
    }

    // Label below circle
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: canvas.bottom
        anchors.topMargin: 3
        text: meter.label
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
        color: Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.6)
    }

    // Sub text below label
    Text {
        visible: meter.subText.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.children[2].bottom
        anchors.topMargin: 2
        text: meter.subText
        font.pixelSize: 11
        font.family: "JetBrainsMono Nerd Font"
        color: Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.4)
    }
}
