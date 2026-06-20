import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Popup {
    id: settingsPopup
    width: 400
    height: 500
    modal: true
    focus: true
    
    background: Settings {
        // The Settings.qml component created previously
    }
}
