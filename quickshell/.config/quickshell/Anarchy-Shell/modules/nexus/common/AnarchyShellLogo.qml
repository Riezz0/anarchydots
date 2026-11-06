import QtQuick
import QtQuick.Effects
import Quickshell
import qs.services

Item {
    id: root

    implicitWidth: 160
    implicitHeight: 160

    Image {
        id: archMark

        anchors.fill: parent
        source: Quickshell.shellPath("assets/anarchy-shell-arch.svg")
        sourceSize: Qt.size(512, 512)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
    }

    MultiEffect {
        anchors.fill: archMark
        source: archMark
        colorization: 1
        colorizationColor: Colours.palette.m3primary
    }

    Image {
        id: orbit

        anchors.fill: parent
        source: Quickshell.shellPath("assets/anarchy-shell-orbit.svg")
        sourceSize: Qt.size(512, 512)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
    }

    MultiEffect {
        anchors.fill: orbit
        source: orbit
        colorization: 1
        colorizationColor: Colours.palette.m3onSurface
    }

    Image {
        id: stars

        anchors.fill: parent
        source: Quickshell.shellPath("assets/anarchy-shell-stars.svg")
        sourceSize: Qt.size(512, 512)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
    }

    MultiEffect {
        anchors.fill: stars
        source: stars
        colorization: 1
        colorizationColor: Colours.palette.m3tertiary
    }
}
