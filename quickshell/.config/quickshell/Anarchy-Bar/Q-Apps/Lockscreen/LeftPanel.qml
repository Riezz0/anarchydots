import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: leftPanel

    property string city: ""
    property real temp: 0
    property real feelsLike: 0
    property string condition: ""
    property string icon: ""
    property var notifications: []

    property real cpuUsage: 0
    property real ramUsage: 0
    property string ramUsed: ""
    property string ramTotal: ""
    property real temperature: 0
    property string diskUsage: ""
    property string netRx: ""
    property string netTx: ""

    spacing: 10
    width: 340
    visible: false

    NotificationBox {
        Layout.fillWidth: true
        notifications: leftPanel.notifications
    }
}
