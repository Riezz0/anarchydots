pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

// Blank launcher-shaped popup, anchored bottom-center like the real
// launcher (same offsetScale slide-up animation and rounding/padding), but
// rendering only an empty shape. Toggled by hovering the bottom-center
// band (see Panels' hoverZone).
Item {
    id: root

    // TMP DIAG
    onOffsetScaleChanged: console.warn(`[BLANKDIAG] offsetScale=${offsetScale} visible=${visible}`)
    onVisibleChanged: console.warn(`[BLANKDIAG] visible=${visible} offsetScale=${offsetScale}`)

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.blankShell && Config.launcher.enabled

    property real offsetScale: shouldBeActive ? 0 : 1
    readonly property real designHeight: 160

    onShouldBeActiveChanged: {
        console.warn(`[BLANKDIAG] shouldBeActive=${shouldBeActive} visible=${visible} offsetScale=${offsetScale} implicitH=${implicitHeight}`)
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible

        sourceComponent: StyledRect {
            implicitWidth: root.implicitWidth
            implicitHeight: Tokens.sizes.launcher.itemHeight * 2 + Tokens.padding.large * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer
        }
    }
}
