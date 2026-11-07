import QtQuick
import QtQuick.Shapes
import qs.services

// Arch Linux "A" (nerdfonts nf-md-arch / Material Design Icons "arch", U+F06C7),
// redrawn as two quad legs in a 24x24 box. Colours stay bound to the live
// pywal-derived palette (Colours, from scheme.json via wal-to-caelestia),
// preserving the previous two-tone pywal identity: left leg = m3primary,
// right leg = m3onSurface (overridable per usage, e.g. User.qml).

Item {
    id: root

    readonly property real designWidth: 24
    readonly property real designHeight: 24

    property color topColour: Colours.palette.m3primary
    property color bottomColour: Colours.palette.m3onSurface

    implicitWidth: designWidth
    implicitHeight: designHeight

    Shape {
        anchors.centerIn: parent
        width: root.designWidth
        height: root.designHeight
        scale: Math.min(root.width / width, root.height / height)
        transformOrigin: Item.Center
        preferredRendererType: Shape.CurveRenderer

        // Left leg: apex (12,2) -> bottom-left outer (3,21) ->
        // bottom-left inner (8,21) -> inner apex (12,11)
        ShapePath {
            fillColor: root.topColour
            strokeColor: "transparent"

            PathSvg {
                path: "M12,2 L3,21 L8,21 L12,11 Z"
            }
        }

        // Right leg: apex (12,2) -> inner apex (12,11) ->
        // bottom-right inner (16,21) -> bottom-right outer (21,21)
        ShapePath {
            fillColor: root.bottomColour
            strokeColor: "transparent"

            PathSvg {
                path: "M12,2 L12,11 L16,21 L21,21 Z"
            }
        }
    }
}
