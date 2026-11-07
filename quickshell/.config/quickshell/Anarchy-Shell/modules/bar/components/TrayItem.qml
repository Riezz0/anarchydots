pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        // iconMap is populated asynchronously; reading it here forces the
        // binder to re-resolve once the scan completes (same pattern as
        // notifications/apps). Without it, getTrayIcon() resolves before the
        // map exists and keeps the provider's broken tile.
        source: {
            const _ = Icons.iconMap;
            return Icons.getTrayIcon(root.modelData.id, root.modelData.icon);
        }
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }
}
