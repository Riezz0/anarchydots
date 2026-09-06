import QtQuick

Canvas {
    id: introCanvas

    signal introFinished()

    anchors.fill: parent
    z: 10

    property real progress: 0
    property var layers: [
        { color: theme.background, speed: 1.0 },
        { color: theme.color1, speed: 1.3 },
        { color: theme.color2, speed: 0.8 },
        { color: theme.color4, speed: 1.1 },
        { color: theme.color5, speed: 0.9 }
    ]

    NumberAnimation {
        id: introAnim
        target: introCanvas
        property: "progress"
        from: 0; to: 1
        duration: 1200
        easing.type: Easing.OutCubic
        onRunningChanged: {
            if (!running) {
                introCanvas.visible = false
                introCanvas.introFinished()
            }
        }
    }

    function start() {
        visible = true
        progress = 0
        introAnim.start()
    }

    onPaint: {
        if (!visible) return
        var ctx = getContext("2d")
        ctx.reset()
        ctx.clearRect(0, 0, width, height)

        for (var i = layers.length - 1; i >= 0; i--) {
            var layer = layers[i]
            var layerProgress = Math.max(0, Math.min(1, (progress - i * 0.08) * layer.speed * 1.5))
            if (layerProgress <= 0) continue

            ctx.beginPath()
            ctx.moveTo(0, height)

            var waveAmplitude = 40 * (1 - layerProgress)
            var segments = 80

            for (var x = 0; x <= width; x += width / segments) {
                var normalizedX = x / width
                var waveOffset = Math.sin(normalizedX * Math.PI * 3 + i * 1.2) * waveAmplitude
                    + Math.sin(normalizedX * Math.PI * 5 + i * 0.8) * waveAmplitude * 0.4

                var baseY = height * (1 - layerProgress)
                var y = baseY + waveOffset

                ctx.lineTo(x, Math.max(0, y))
            }

            ctx.lineTo(width, 0)
            ctx.lineTo(0, 0)
            ctx.closePath()

            ctx.fillStyle = layer.color
            ctx.globalAlpha = 0.9 - i * 0.1
            ctx.fill()
            ctx.globalAlpha = 1.0
        }

        if (progress > 0.5) {
            var wipeProgress = (progress - 0.5) * 2
            var centerX = width / 2
            var revealRadius = wipeProgress * width * 0.8

            ctx.save()
            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath()
            ctx.arc(centerX, height / 2, revealRadius, 0, Math.PI * 2)
            ctx.fill()
            ctx.restore()
        }
    }
}
