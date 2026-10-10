import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: calendarWindow
    screen: calendarPopup.targetScreen

    visible: calendarPopup.isOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    focusable: calendarPopup.isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: calendarPopup.isOpen
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    mask: Region { item: calendarPanel }

    property var currentMonth: new Date()
    property string selectedDateKey: ""
    property bool taskPanelOpen: false
    property bool taskFormOpen: false
    property bool taskSavePending: false
    property string taskValidationError: ""
    property bool reminderMenuOpen: false
    property int reminderChoiceIndex: 2
    readonly property var reminderLabels: ["At due time", "5 min before", "10 min before", "15 min before", "30 min before", "60 min before"]

    function defaultTaskTime() {
        var now = new Date()
        var todayKey = now.getFullYear() + "-" + ("0" + (now.getMonth() + 1)).slice(-2)
            + "-" + ("0" + now.getDate()).slice(-2)
        if (selectedDateKey !== todayKey) return "09:00"

        var minutes = Math.ceil((now.getHours() * 60 + now.getMinutes() + 10) / 5) * 5
        if (minutes >= 1440) minutes = 1439
        return ("0" + Math.floor(minutes / 60)).slice(-2) + ":" + ("0" + (minutes % 60)).slice(-2)
    }

    function selectDate(dateKey) {
        if (selectedDateKey === dateKey && taskPanelOpen) {
            taskPanelOpen = false
            taskFormOpen = false
            taskSavePending = false
            taskValidationError = ""
            reminderMenuOpen = false
            return
        }

        selectedDateKey = dateKey
        taskPanelOpen = true
        taskFormOpen = calendarTasks.ready && calendarTasks.writable
            && calendarTasks.tasksForDate(dateKey).length === 0
        taskSavePending = false
        taskValidationError = ""
        reminderMenuOpen = false
        if (taskFormOpen) {
            taskTitleInput.text = ""
            taskTimeInput.text = defaultTaskTime()
            reminderChoiceIndex = 2
        }

        Qt.callLater(function() {
            var maxY = Math.max(0, calendarWindow.height - calendarPanel.height)
            if (calendarPanel.y > maxY) {
                calendarPanel.y = maxY
                root.calendarY = maxY
                root.saveSettings()
            }
        })
    }

    function selectedDateLabel() {
        var parts = selectedDateKey.split("-")
        if (parts.length !== 3) return "Selected day"
        return Qt.formatDate(new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])), "ddd, d MMM yyyy")
    }

    function submitTask() {
        var title = taskTitleInput.text.trim()
        var time = taskTimeInput.text.trim()
        var match = /^(?:[01][0-9]|2[0-3]):[0-5][0-9]$/.exec(time)

        if (!calendarTasks.ready) {
            taskValidationError = "Task storage is still loading."
            return
        }
        if (!calendarTasks.writable) {
            taskValidationError = calendarTasks.errorMessage || "Task storage is unavailable."
            return
        }
        if (title.length === 0) {
            taskValidationError = "Enter a task title."
            return
        }
        if (!match) {
            taskValidationError = "Enter a valid 24-hour time, such as 14:30."
            return
        }

        if (taskSavePending) {
            calendarTasks.saveTasks()
            return
        }

        var dateParts = selectedDateKey.split("-")
        var timeParts = time.split(":")
        var dueAt = new Date(
            Number(dateParts[0]), Number(dateParts[1]) - 1, Number(dateParts[2]),
            Number(timeParts[0]), Number(timeParts[1]), 0, 0
        ).getTime()
        if (dueAt <= Date.now()) {
            taskValidationError = "Choose a due time in the future."
            return
        }

        var reminderPresets = [0, 5, 10, 15, 30, 60]
        var taskId = calendarTasks.addTask(
            title, selectedDateKey, dueAt, reminderPresets[reminderChoiceIndex]
        )
        if (!taskId) {
            taskValidationError = calendarTasks.errorMessage || "Could not save this task."
            return
        }

        taskSavePending = true
        taskValidationError = "Saving task…"
    }

    Connections {
        target: calendarTasks
        function onTasksSaved() {
            if (!calendarWindow.taskSavePending) return
            calendarWindow.taskSavePending = false
            calendarWindow.taskFormOpen = false
            calendarWindow.taskValidationError = ""
            taskTitleInput.text = ""
            taskTimeInput.text = "09:00"
        }
        function onTasksSaveFailed(message) {
            if (!calendarWindow.taskSavePending) return
            calendarWindow.taskSavePending = false
            calendarWindow.taskValidationError = message
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => mouse.accepted = true
    }

    Rectangle {
        x: calendarPanel.x + root.widgetShadowX
        y: calendarPanel.y + root.widgetShadowY
        width: 360
        height: calendarPanel.height
        radius: root.widgetShadowRadius
        color: Qt.rgba(0, 0, 0, calendarPopup.isOpen ? root.widgetShadowOpacity : 0)
    }

    Rectangle {
        id: calendarPanel
        x: Math.max(0, Math.min(root.calendarX, Math.max(0, parent.width - width)))
        y: Math.max(0, Math.min(root.calendarY, Math.max(0, parent.height - height)))
        width: 360
        height: calendarWindow.taskPanelOpen ? 500 : 340
        property real contentScale: 1
        radius: root.widgetRadius
        color: theme.background
        opacity: calendarPopup.isOpen ? root.widgetOpacity : 0
        border.color: theme.color5
        border.width: root.widgetBorderThickness
        clip: true

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        ColumnLayout {
            id: calendarOuter
            anchors.fill: parent
            anchors.margins: 16 * calendarPanel.contentScale
            spacing: 8 * calendarPanel.contentScale

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.rightMargin: 30

                Text {
                    text: "◀"
                    font.pixelSize: 14 * calendarPanel.contentScale
                    color: theme.color5
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var m = calendarWindow.currentMonth
                            calendarWindow.currentMonth = new Date(m.getFullYear(), m.getMonth() - 1, 1)
                            calendarWindow.taskPanelOpen = false
                        }
                    }
                }

                Text {
                    text: Qt.formatDateTime(calendarWindow.currentMonth, "MMMM yyyy")
                    font.pixelSize: 14 * calendarPanel.contentScale
                    font.bold: true
                    color: theme.foreground
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: calendarPanel
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: 0
                        drag.maximumX: Math.max(0, calendarWindow.width - calendarPanel.width)
                        drag.minimumY: 0
                        drag.maximumY: Math.max(0, calendarWindow.height - calendarPanel.height)
                        onReleased: {
                            root.calendarX = calendarPanel.x
                            root.calendarY = calendarPanel.y
                            root.saveSettings()
                        }
                    }
                }

                Text {
                    text: "▶"
                    font.pixelSize: 14 * calendarPanel.contentScale
                    color: theme.color5
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var m = calendarWindow.currentMonth
                            calendarWindow.currentMonth = new Date(m.getFullYear(), m.getMonth() + 1, 1)
                            calendarWindow.taskPanelOpen = false
                        }
                    }
                }

            }

            // Today button
            Rectangle {
                Layout.fillWidth: true
                height: 28 * calendarPanel.contentScale
                radius: root.widgetRadius
                color: todayHover.containsMouse ? Qt.darker(theme.color2, 1.2) : theme.color2

                Text {
                    anchors.centerIn: parent
                    text: "Today"
                    font.pixelSize: 11 * calendarPanel.contentScale
                    font.bold: true
                    color: theme.background
                }

                MouseArea {
                    id: todayHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        calendarWindow.currentMonth = new Date()
                        calendarWindow.taskPanelOpen = false
                    }
                }
            }

            // Day names
            RowLayout {
                Layout.fillWidth: true

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                    Text {
                        text: modelData
                        font.pixelSize: 11 * calendarPanel.contentScale
                        color: theme.muted
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Days
            GridLayout {
                Layout.fillWidth: true
                columns: 7

                Repeater {
                    model: {
                        var m = calendarWindow.currentMonth
                        var firstDay = new Date(m.getFullYear(), m.getMonth(), 1)
                        var lastDay = new Date(m.getFullYear(), m.getMonth() + 1, 0)
                        var startDay = (firstDay.getDay() + 6) % 7
                        var totalDays = lastDay.getDate()
                        var today = new Date()

                        var days = []
                        for (var i = 0; i < startDay; i++) {
                            days.push({ day: 0, isCurrentMonth: false })
                        }
                        for (var d = 1; d <= totalDays; d++) {
                            var isToday = d === today.getDate() && m.getMonth() === today.getMonth() && m.getFullYear() === today.getFullYear()
                            var dateKey = m.getFullYear() + "-" + ("0" + (m.getMonth() + 1)).slice(-2) + "-" + ("0" + d).slice(-2)
                            days.push({ day: d, isCurrentMonth: true, isToday: isToday, dateKey: dateKey })
                        }
                        while (days.length % 7 !== 0) {
                            days.push({ day: 0, isCurrentMonth: false })
                        }
                        while (days.length < 42) {
                            days.push({ day: 0, isCurrentMonth: false })
                        }
                        return days
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 36 * calendarPanel.contentScale
                        Layout.preferredHeight: 28 * calendarPanel.contentScale
                        radius: root.widgetRadius
                        border.color: modelData.dateKey === calendarWindow.selectedDateKey ? theme.color5 : "transparent"
                        border.width: modelData.dateKey === calendarWindow.selectedDateKey ? 1 : 0
                        color: modelData.day === 0 ? "transparent" : (modelData.isToday ? theme.color2 : (dayHover.containsMouse ? Qt.darker(theme.background, 1.2) : "transparent"))

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day === 0 ? "" : modelData.day.toString()
                            font.pixelSize: 11 * calendarPanel.contentScale
                            color: modelData.day === 0 ? "transparent" : (modelData.isToday ? theme.background : (modelData.isCurrentMonth ? theme.foreground : theme.muted))
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            width: 4
                            height: 4
                            radius: 2
                            color: theme.color4
                            visible: modelData.day !== 0 && calendarTasks.tasksForDate(modelData.dateKey).length > 0
                        }

                        MouseArea {
                            id: dayHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.day !== 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: calendarWindow.selectDate(modelData.dateKey)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: theme.muted
                opacity: 0.35
                visible: calendarWindow.taskPanelOpen
            }

            RowLayout {
                Layout.fillWidth: true
                visible: calendarWindow.taskPanelOpen && !calendarWindow.taskFormOpen
                spacing: 6

                Text {
                    text: calendarWindow.selectedDateLabel()
                    color: theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 28
                    height: 26
                    radius: root.widgetRadius
                    color: addTaskHover.containsMouse ? theme.color4 : Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.25)

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: theme.foreground
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        id: addTaskHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: calendarTasks.ready && calendarTasks.writable
                        onClicked: {
                            calendarWindow.taskFormOpen = true
                            calendarWindow.taskValidationError = ""
                            calendarWindow.reminderMenuOpen = false
                            taskTitleInput.text = ""
                            taskTimeInput.text = calendarWindow.defaultTaskTime()
                            reminderChoiceIndex = 2
                        }
                    }
                }

                Rectangle {
                    width: 28
                    height: 26
                    radius: root.widgetRadius
                    color: closeTasksHover.containsMouse ? theme.color1 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: closeTasksHover.containsMouse ? theme.background : theme.muted
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: closeTasksHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendarWindow.taskPanelOpen = false
                    }
                }
            }

            ListView {
                id: dateTasksList
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: calendarWindow.taskPanelOpen && !calendarWindow.taskFormOpen
                clip: true
                spacing: 3
                model: calendarTasks.tasksForDate(calendarWindow.selectedDateKey)

                delegate: Rectangle {
                    required property var modelData
                    width: dateTasksList.width
                    height: 28
                    radius: root.widgetRadius
                    color: Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.04)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        spacing: 5

                        Rectangle {
                            width: 15
                            height: 15
                            radius: 4
                            color: modelData.completed ? theme.color2 : "transparent"
                            border.color: modelData.completed ? theme.color2 : theme.muted
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.completed ? "✓" : ""
                                color: theme.background
                                font.pixelSize: 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarTasks.setCompleted(modelData.id, !modelData.completed)
                            }
                        }

                        Text {
                            text: modelData.title
                            color: modelData.completed ? theme.muted : theme.color15
                            font.pixelSize: 12
                            font.bold: !modelData.completed
                            font.strikeout: modelData.completed
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: Qt.formatDateTime(new Date(modelData.dueAt), "h:mm AP")
                            color: theme.muted
                            font.pixelSize: 10
                        }

                        Text {
                            text: "×"
                            color: deleteTaskHover.containsMouse ? theme.color1 : theme.muted
                            font.pixelSize: 15

                            MouseArea {
                                id: deleteTaskHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarTasks.deleteTask(modelData.id)
                            }
                        }
                    }
                }
            }

            Text {
                visible: calendarWindow.taskPanelOpen && !calendarWindow.taskFormOpen && dateTasksList.count > 0 && calendarTasks.errorMessage.length > 0
                text: calendarTasks.errorMessage
                color: theme.color1
                font.pixelSize: 10
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                visible: calendarWindow.taskPanelOpen && !calendarWindow.taskFormOpen && dateTasksList.count === 0
                text: calendarTasks.errorMessage || (calendarTasks.ready ? "No tasks for this date." : "Loading tasks…")
                color: calendarTasks.errorMessage ? theme.color1 : theme.muted
                font.pixelSize: 11
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            RowLayout {
                visible: calendarWindow.taskPanelOpen && calendarWindow.taskFormOpen
                Layout.fillWidth: true

                Text {
                    text: calendarWindow.selectedDateLabel() + " · New task"
                    color: theme.foreground
                    font.pixelSize: 12
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                visible: calendarWindow.taskPanelOpen && calendarWindow.taskFormOpen
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                TextField {
                    id: taskTitleInput
                    Layout.fillWidth: true
                    placeholderText: "Task title"
                    color: theme.color15
                    palette.placeholderText: theme.color7
                    selectByMouse: true
                    enabled: !calendarWindow.taskSavePending && calendarTasks.ready && calendarTasks.writable
                    background: Rectangle {
                        radius: root.widgetRadius
                        color: Qt.darker(theme.background, 1.12)
                        border.color: theme.muted
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Due"
                        color: theme.muted
                        font.pixelSize: 11
                    }

                    TextField {
                        id: taskTimeInput
                        Layout.preferredWidth: 82
                        text: "09:00"
                        color: theme.foreground
                        selectByMouse: true
                        validator: RegularExpressionValidator { regularExpression: /^(?:[01][0-9]|2[0-3]):[0-5][0-9]$/ }
                        enabled: !calendarWindow.taskSavePending && calendarTasks.ready && calendarTasks.writable
                        background: Rectangle {
                            radius: root.widgetRadius
                            color: Qt.darker(theme.background, 1.12)
                            border.color: theme.muted
                        }
                    }

                    Item {
                        id: reminderPicker
                        Layout.fillWidth: true
                        height: 34
                        z: calendarWindow.reminderMenuOpen ? 20 : 0
                        enabled: !calendarWindow.taskSavePending && calendarTasks.ready && calendarTasks.writable

                        Rectangle {
                            anchors.fill: parent
                            radius: root.widgetRadius
                            color: calendarWindow.reminderMenuOpen ? Qt.darker(theme.background, 1.12) : Qt.darker(theme.background, 1.08)
                            border.color: calendarWindow.reminderMenuOpen ? theme.color4 : theme.muted

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                text: calendarWindow.reminderLabels[calendarWindow.reminderChoiceIndex]
                                color: theme.foreground
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: calendarWindow.reminderMenuOpen ? "⌃" : "⌄"
                                color: theme.muted
                                font.pixelSize: 13
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: calendarWindow.reminderMenuOpen = !calendarWindow.reminderMenuOpen
                            }
                        }

                        Rectangle {
                            id: reminderMenu
                            visible: calendarWindow.reminderMenuOpen
                            z: 1
                            width: reminderPicker.width
                            height: calendarWindow.reminderLabels.length * 28 + 8
                            anchors.bottom: reminderPicker.top
                            anchors.bottomMargin: 4
                            radius: root.widgetRadius
                            color: theme.background
                            border.color: theme.color4
                            border.width: 1

                            Column {
                                id: reminderOptions
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 2

                                Repeater {
                                    model: calendarWindow.reminderLabels

                                    Rectangle {
                                        required property int index
                                        required property string modelData
                                        width: reminderOptions.width
                                        height: 26
                                        radius: Math.max(2, root.widgetRadius - 2)
                                        color: reminderOptionHover.containsMouse
                                            ? theme.color4
                                            : (index === calendarWindow.reminderChoiceIndex
                                                ? Qt.rgba(theme.color4.r, theme.color4.g, theme.color4.b, 0.18)
                                                : "transparent")

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData
                                            color: reminderOptionHover.containsMouse ? theme.background : theme.foreground
                                            font.pixelSize: 11
                                        }

                                        MouseArea {
                                            id: reminderOptionHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                calendarWindow.reminderChoiceIndex = index
                                                calendarWindow.reminderMenuOpen = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: calendarWindow.taskValidationError.length > 0 || calendarTasks.errorMessage.length > 0
                    text: calendarWindow.taskValidationError || calendarTasks.errorMessage
                    color: theme.color1
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 64
                        height: 26
                        radius: root.widgetRadius
                        color: cancelTaskHover.containsMouse ? Qt.darker(theme.background, 1.2) : "transparent"
                        Text { anchors.centerIn: parent; text: "Cancel"; color: theme.muted; font.pixelSize: 10 }
                        MouseArea {
                            id: cancelTaskHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !calendarWindow.taskSavePending
                            onClicked: calendarWindow.taskFormOpen = false
                        }
                    }

                    Rectangle {
                        width: 64
                        height: 26
                        radius: root.widgetRadius
                        color: saveTaskHover.containsMouse ? theme.color5 : theme.color4
                        Text { anchors.centerIn: parent; text: calendarWindow.taskSavePending ? "Saving…" : "Save"; color: theme.background; font.pixelSize: 10; font.bold: true }
                        MouseArea {
                            id: saveTaskHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !calendarWindow.taskSavePending && calendarTasks.ready && calendarTasks.writable
                            onClicked: calendarWindow.submitTask()
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 8
            anchors.rightMargin: 8
            width: 24
            height: 24
            radius: root.widgetRadius
            color: calendarCloseHover.containsMouse
                ? theme.color1
                : Qt.rgba(theme.foreground.r, theme.foreground.g, theme.foreground.b, 0.08)
            z: 20

            Text {
                anchors.centerIn: parent
                text: "×"
                color: calendarCloseHover.containsMouse ? theme.background : theme.foreground
                font.pixelSize: 16
            }

            MouseArea {
                id: calendarCloseHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calendarPopup.close()
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: root.barRadius
            color: "transparent"
            border.color: theme.color5
            border.width: root.widgetBorderThickness
            z: 10
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: calendarPopup.close()
    }

}
