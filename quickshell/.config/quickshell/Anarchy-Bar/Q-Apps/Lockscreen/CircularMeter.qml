import QtQuick

Item {
    id: meter

    property string label: ""
    property string value: ""
    property string subText: ""
    property real progress: 0
    property color meterColor: theme.color4
    property real maxValue: 100

    width: 110
    height: 130

    Canvas {
        id: canvas
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 110
        height: 110

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2
            var cy = height / 2
            var r = 50
            var lw = 7

            // Solid background circle
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.fillStyle = theme.background
            ctx.fill()

            // Outer border
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.strokeStyle = Qt.darker(meter.meterColor, 1.8)
            ctx.lineWidth = lw
            ctx.stroke()

            // Progress arc on edge
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
                ctx.strokeStyle = theme.color7
                ctx.lineWidth = 1
                ctx.stroke()
            }
        }

        Connections {
            target: meter
            function onProgressChanged() { canvas.requestPaint() }
            function onMeterColorChanged() { canvas.requestPaint() }
        }

        Connections {
            target: theme
            function onColorsChanged() { canvas.requestPaint() }
        }

        Component.onCompleted: canvas.requestPaint()
    }

    // Label above circle
    Text {
        anchors.horizontalCenter: canvas.horizontalCenter
        anchors.verticalCenter: canvas.verticalCenter
        anchors.verticalCenterOffset: -16
        text: meter.label
        font.pixelSize: 11
        font.family: "JetBrainsMono Nerd Font"
        color: theme.foreground
        z: 1
    }

    // Value centered
    Text {
        anchors.horizontalCenter: canvas.horizontalCenter
        anchors.verticalCenter: canvas.verticalCenter
        anchors.verticalCenterOffset: 4
        text: meter.value
        font.pixelSize: 24
        font.bold: true
        font.family: "JetBrainsMono Nerd Font"
        color: theme.foreground
        z: 1
    }

    // SubText below value
    Text {
        visible: meter.subText.length > 0
        anchors.horizontalCenter: canvas.horizontalCenter
        anchors.verticalCenter: canvas.verticalCenter
        anchors.verticalCenterOffset: 24
        text: meter.subText
        font.pixelSize: 10
        font.family: "JetBrainsMono Nerd Font"
        color: theme.foreground
        z: 1
    }
}
