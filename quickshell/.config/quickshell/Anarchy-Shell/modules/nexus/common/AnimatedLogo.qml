pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.components
import qs.services

// Arch Linux "A" (nf-md-arch / MDI "arch", U+F06C7), pywal-tinted via the
// live palette (see components/Logo.qml). Keeps the old intro API
// (skipIntroAnimation, blurAmount, animationCompleted, shape aliases) but the
// Caelestia swirl/star spin choreography is replaced by a simple
// scale + fade + unblur intro. The star alias ids are kept only so any
// external binding still resolves — they are invisible 1px placeholders.

Item {
    id: root

    property real blurAmount: skipIntroAnimation ? 0.0 : 1.0
    property bool skipIntroAnimation: false

    property real star1Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star2Opacity: skipIntroAnimation ? 1.0 : 0.0
    property real star3Opacity: skipIntroAnimation ? 1.0 : 0.0

    property real star1Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star2Scale: skipIntroAnimation ? 1.0 : 0.0
    property real star3Scale: skipIntroAnimation ? 1.0 : 0.0

    readonly property alias topShape: leftShape
    readonly property alias bottomShape: rightShape
    readonly property alias star1: star1
    readonly property alias star2: star2
    readonly property alias star3: star3

    signal animationCompleted

    implicitWidth: 96
    implicitHeight: 96

    Item {
        id: logo

        readonly property real designWidth: 24
        readonly property real designHeight: 24

        property color topColour: Colours.palette.m3primary
        property color bottomColour: Colours.palette.m3onSurface

        anchors.fill: parent

        transformOrigin: Item.Center
        scale: root.skipIntroAnimation ? 1.0 : 0.0
        opacity: root.skipIntroAnimation ? 1.0 : 0.0

        layer.enabled: root.blurAmount > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blurAmount
            blurMax: 60
        }

        Behavior on topColour {
            CAnim {}
        }

        Behavior on bottomColour {
            CAnim {}
        }

        Shape {
            id: leftShape

            anchors.centerIn: parent
            width: logo.designWidth
            height: logo.designHeight
            scale: Math.min(logo.width / width, logo.height / height)
            transformOrigin: Item.Center
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: logo.topColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M12,2 L3,21 L8,21 L12,11 Z"
                }
            }
        }

        Shape {
            id: rightShape

            anchors.centerIn: parent
            width: logo.designWidth
            height: logo.designHeight
            scale: Math.min(logo.width / width, logo.height / height)
            transformOrigin: Item.Center
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: logo.bottomColour
                strokeColor: "transparent"

                PathSvg {
                    path: "M12,2 L12,11 L16,21 L21,21 Z"
                }
            }
        }
    }

    // API-compat placeholders (the old sparkles are gone).
    Item {
        id: star1
    }

    Item {
        id: star2
    }

    Item {
        id: star3
    }

    SequentialAnimation {
        running: !root.skipIntroAnimation
        onFinished: root.animationCompleted()

        ParallelAnimation {
            SequentialAnimation {
                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.0
                    to: 1.08
                    duration: 1000
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 1.08
                    to: 0.96
                    duration: 200
                    easing.type: Easing.InOutQuad
                }

                NumberAnimation {
                    target: logo
                    property: "scale"
                    from: 0.96
                    to: 1.0
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }

            NumberAnimation {
                target: logo
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 600
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: root
                property: "blurAmount"
                from: 1.0
                to: 0.0
                duration: 900
                easing.type: Easing.OutCubic
            }
        }
    }
}
