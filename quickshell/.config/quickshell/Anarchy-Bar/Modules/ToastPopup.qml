import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: toastWindow

    visible: toastList.length > 0
    screen: powerMenu.targetScreen

    property var toastList: []
    property int maxToasts: 3

    function addToast(appName, summary, body, persistent, taskId) {
        var toast = {
            id: Date.now() + Math.random(),
            appName: appName,
            summary: summary,
            body: body,
            persistent: persistent === true,
            taskId: taskId || ""
        }
        var list = toastList.slice()
        list.push(toast)

        var transientCount = list.filter(function(item) { return !item.persistent }).length
        while (transientCount > maxToasts) {
            var transientIndex = list.findIndex(function(item) { return !item.persistent })
            if (transientIndex < 0) break
            list.splice(transientIndex, 1)
            transientCount--
        }

        toastList = list
        if (!toast.persistent)
            dismissTimerComponent.createObject(toastWindow, { toastId: toast.id })
    }

    function dismissToast(toastId) {
        var toast = toastList.find(function(item) { return item.id === toastId })
        if (toast && toast.taskId)
            calendarTasks.acknowledgeReminder(toast.taskId)
        toastList = toastList.filter(function(toast) { return toast.id !== toastId })
    }

    anchors { top: true; left: true; right: true }

    implicitHeight: toastColumn.implicitHeight + 40
    exclusiveZone: 0
    color: "transparent"
    focusable: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region { item: toastColumn }

    Connections {
        target: notifs
        function onNotificationReceived(appName, summary, body, urgency, timeout, actions) {
            toastWindow.addToast(appName, summary, body, false, "")
        }
    }

    Connections {
        target: calendarTasks
        function onReminderTriggered(taskId, title, dueLabel) {
            toastWindow.addToast("Task reminder", title, "Due " + dueLabel, true, taskId)
        }
        function onReminderCancelled(taskId) {
            toastWindow.toastList = toastWindow.toastList.filter(function(toast) {
                return toast.taskId !== taskId
            })
        }
    }

    Component {
        id: dismissTimerComponent
        Timer {
            property real toastId: 0
            interval: 4000
            running: true
            repeat: false
            onTriggered: {
                var list = toastWindow.toastList.slice()
                list = list.filter(function(t) { return t.id !== toastId })
                toastWindow.toastList = list
                destroy()
            }
        }
    }

    Column {
        id: toastColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        spacing: 8

        Repeater {
            model: toastWindow.toastList

            Rectangle {
                required property var modelData
                required property int index

                width: 320
                height: toastContent.implicitHeight + 20
                radius: root.popupRadius
                color: theme.background
                opacity: 0.95
                border.color: theme.color4
                border.width: root.popupBorderThickness
                clip: true

                ColumnLayout {
                    id: toastContent
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: notifs.notifIcon()
                            font.pixelSize: 16
                            font.family: "JetBrainsMono Nerd Font"
                            color: theme.color4
                        }

                        Text {
                            text: modelData.appName || "Notification"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            color: theme.muted
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: modelData.summary || ""
                        font.pixelSize: 13
                        font.bold: true
                        color: theme.foreground
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: modelData.body && modelData.body.length > 0
                        text: modelData.body || ""
                        font.pixelSize: 11
                        color: theme.muted
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        visible: modelData.persistent
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 72
                            height: 24
                            radius: root.popupRadius
                            color: dismissHover.containsMouse ? theme.color5 : theme.color4

                            Text {
                                anchors.centerIn: parent
                                text: "Dismiss"
                                font.pixelSize: 11
                                font.bold: true
                                color: theme.background
                            }

                            MouseArea {
                                id: dismissHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toastWindow.dismissToast(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
