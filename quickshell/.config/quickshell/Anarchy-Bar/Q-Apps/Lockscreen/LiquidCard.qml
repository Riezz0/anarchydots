import QtQuick

Canvas {
    id: liquidCard

    property string icon: ""
    property string title: ""
    property string value: ""
    property string subText: ""
    property color fillGradientStart: theme.color4
    property color fillGradientEnd: theme.color5
    property real fillLevel: 0
    property real wavePhase: 0
    property real globalWavePhase: 0

    width: parent ? parent.width : 130
    height: 68
    onPaint: drawCard()

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            liquidCard.wavePhase += 0.08
            liquidCard.drawCard()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: rootLock.barRadius
        color: Qt.rgba(theme.color8.r, theme.color8.g, theme.color8.b, 0.2)
        border.color: Qt.rgba(theme.color7.r, theme.color7.g, theme.color7.b, 0.12)
        border.width: rootLock.popupBorderThickness
    }

    function drawCard() {
        var ctx = getContext("2d")
        ctx.reset()

        ctx.beginPath()
        ctx.roundedRect(0, 0, width, height, rootLock.barRadius, rootLock.barRadius)
        ctx.clip()

        var fillH = height * (fillLevel / 100)
        var waveH = 6

        ctx.beginPath()
        ctx.moveTo(0, height)
        for (var x = 0; x <= width; x += 2) {
            var y = height - fillH + Math.sin((x / width) * Math.PI * 2 + wavePhase) * waveH
                + Math.sin((x / width) * Math.PI * 3 + wavePhase * 1.3) * waveH * 0.5
            ctx.lineTo(x, y)
        }
        ctx.lineTo(width, height)
        ctx.closePath()

        var grad = ctx.createLinearGradient(0, height - fillH, 0, height)
        grad.addColorStop(0, Qt.rgba(fillGradientStart.r, fillGradientStart.g, fillGradientStart.b, 0.6))
        grad.addColorStop(1, Qt.rgba(fillGradientEnd.r, fillGradientEnd.g, fillGradientEnd.b, 0.4))
        ctx.fillStyle = grad
        ctx.fill()

        ctx.fillStyle = theme.foreground
        ctx.font = "14px JetBrainsMono Nerd Font"
        ctx.textAlign = "left"
        ctx.textBaseline = "top"

        ctx.fillStyle = Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.7)
        ctx.font = "14px JetBrainsMono Nerd Font"
        ctx.fillText(icon, 10, 10)

        ctx.fillStyle = Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.6)
        ctx.font = "11px JetBrainsMono Nerd Font"
        ctx.fillText(title, 28, 11)

        ctx.fillStyle = theme.foreground
        ctx.font = "bold 18px JetBrainsMono Nerd Font"
        ctx.fillText(value, 10, 34)

        if (subText.length > 0) {
            ctx.fillStyle = Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.5)
            ctx.font = "10px JetBrainsMono Nerd Font"
            ctx.fillText(subText, 10, 58)
        }
    }
}
