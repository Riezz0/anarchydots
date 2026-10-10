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
            var radius = 50
            var lineWidth = 7

            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, Math.PI * 2)
            ctx.fillStyle = theme.background
            ctx.fill()

            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, Math.PI * 2)
            ctx.strokeStyle = Qt.darker(meter.meterColor, 1.8)
            ctx.lineWidth = lineWidth
            ctx.stroke()

            var fraction = Math.min(Math.max(meter.progress / meter.maxValue, 0), 1)
            if (fraction > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * fraction)
                ctx.strokeStyle = meter.meterColor
                ctx.lineWidth = lineWidth
                ctx.lineCap = "round"
                ctx.stroke()
            }

            for (var i = 0; i < 12; i++) {
                var angle = (i / 12) * Math.PI * 2 - Math.PI / 2
                var innerRadius = radius - lineWidth / 2 - 2
                var outerRadius = radius - lineWidth / 2 - 5
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(angle) * innerRadius, cy + Math.sin(angle) * innerRadius)
                ctx.lineTo(cx + Math.cos(angle) * outerRadius, cy + Math.sin(angle) * outerRadius)
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
