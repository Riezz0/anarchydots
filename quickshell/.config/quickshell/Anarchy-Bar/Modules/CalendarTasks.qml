import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

Item {
    id: store
    visible: false
    width: 0
    height: 0

    property var tasks: []
    property bool ready: false
    property bool directoryReady: false
    property bool writePending: false
    property bool saveAgain: false
    property bool writable: true
    property string errorMessage: ""
    property var pendingReminders: []

    readonly property string dataDirectory:
        StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
            .toString().replace(/^file:\/\//, "") + "/anarchy-bar"
    readonly property string taskFilePath: dataDirectory + "/calendar-tasks.json"

    signal reminderTriggered(string taskId, string title, string dueLabel)
    signal reminderCancelled(string taskId)
    signal tasksSaved()
    signal tasksSaveFailed(string message)

    function tasksForDate(dateKey) {
        var result = tasks.filter(function(task) {
            return task.dateKey === dateKey
        })
        result.sort(function(a, b) { return Number(a.dueAt) - Number(b.dueAt) })
        return result
    }

    function saveTasks() {
        if (!ready || !writable) return false
        if (writePending) {
            saveAgain = true
            return true
        }
        writePending = true
        taskFile.setText(JSON.stringify(tasks, null, 2))
        return true
    }

    function addTask(title, dateKey, dueAt, reminderMinutes) {
        var cleanTitle = String(title || "").trim()
        var timestamp = Number(dueAt)
        var lead = Number(reminderMinutes)
        if (!ready || !writable || cleanTitle.length === 0 || !isFinite(timestamp) || timestamp <= Date.now())
            return ""

        var task = {
            id: String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000)),
            title: cleanTitle,
            dateKey: dateKey,
            dueAt: timestamp,
            reminderMinutes: isFinite(lead) ? Math.max(0, lead) : 10,
            completed: false,
            reminded: false,
            acknowledged: false
        }
        var nextTasks = tasks.slice()
        nextTasks.push(task)
        tasks = nextTasks
        saveTasks()
        checkReminders(false)
        return task.id
    }

    function setCompleted(taskId, completed) {
        if (!ready || !writable) return
        var nextTasks = tasks.slice()
        for (var i = 0; i < nextTasks.length; i++) {
            if (nextTasks[i].id === taskId) {
                nextTasks[i] = {
                    id: nextTasks[i].id,
                    title: nextTasks[i].title,
                    dateKey: nextTasks[i].dateKey,
                    dueAt: nextTasks[i].dueAt,
                    reminderMinutes: nextTasks[i].reminderMinutes,
                    completed: completed,
                    reminded: completed ? nextTasks[i].reminded : false,
                    acknowledged: completed
                }
                tasks = nextTasks
                saveTasks()
                if (completed) reminderCancelled(taskId)
                return
            }
        }
    }

    function acknowledgeReminder(taskId) {
        if (!ready || !writable) return
        var nextTasks = tasks.slice()
        for (var i = 0; i < nextTasks.length; i++) {
            if (nextTasks[i].id !== taskId) continue
            if (nextTasks[i].acknowledged) return
            nextTasks[i] = {
                id: nextTasks[i].id,
                title: nextTasks[i].title,
                dateKey: nextTasks[i].dateKey,
                dueAt: nextTasks[i].dueAt,
                reminderMinutes: nextTasks[i].reminderMinutes,
                completed: nextTasks[i].completed,
                reminded: nextTasks[i].reminded,
                acknowledged: true
            }
            tasks = nextTasks
            saveTasks()
            return
        }
    }

    function deleteTask(taskId) {
        if (!ready || !writable) return
        reminderCancelled(taskId)
        tasks = tasks.filter(function(task) { return task.id !== taskId })
        saveTasks()
    }

    function loadTasks(contents) {
        try {
            var parsed = contents.trim().length === 0 ? [] : JSON.parse(contents)
            if (!Array.isArray(parsed)) throw new Error("Task data must be a JSON array")
            for (var i = 0; i < parsed.length; i++) {
                var item = parsed[i]
                if (!item || typeof item.id !== "string" || typeof item.title !== "string"
                        || !/^\d{4}-\d{2}-\d{2}$/.test(item.dateKey)
                        || !isFinite(Number(item.dueAt)))
                    throw new Error("Invalid task entry")
            }
            tasks = parsed.map(function(task) {
                return {
                    id: task.id,
                    title: task.title,
                    dateKey: task.dateKey,
                    dueAt: Number(task.dueAt),
                    reminderMinutes: Math.max(0, Number(task.reminderMinutes) || 0),
                    completed: task.completed === true,
                    reminded: task.reminded === true,
                    acknowledged: task.acknowledged === true
                }
            })
            ready = true
            checkReminders(true)
        } catch (error) {
            ready = true
            writable = false
            errorMessage = "Could not read calendar tasks; saved data was left untouched."
            console.warn("Anarchy-Bar: failed to read calendar tasks:", error)
        }
    }

    function checkReminders(startupCheck) {
        if (!ready || !writable || writePending) return

        var now = Date.now()
        var changed = false
        var nextTasks = tasks.slice()
        var dueReminders = []

        for (var i = 0; i < nextTasks.length; i++) {
            var task = nextTasks[i]
            if (task.completed || task.acknowledged) continue

            var dueAt = Number(task.dueAt)
            var reminderAt = dueAt - Number(task.reminderMinutes || 0) * 60000
            if (startupCheck && dueAt <= now) {
                nextTasks[i] = {
                    id: task.id,
                    title: task.title,
                    dateKey: task.dateKey,
                    dueAt: task.dueAt,
                    reminderMinutes: task.reminderMinutes,
                    completed: task.completed,
                    reminded: true,
                    acknowledged: true
                }
                changed = true
                continue
            }

            if (task.reminded) {
                if (startupCheck && now >= reminderAt && now < dueAt) {
                    dueReminders.push({
                        id: task.id,
                        title: task.title,
                        dueLabel: Qt.formatDateTime(new Date(dueAt), "ddd, MMM d h:mm AP")
                    })
                }
                continue
            }

            var withinDeliveryWindow = !startupCheck && now <= dueAt + reminderTimer.interval
            if (now >= reminderAt && (now < dueAt || withinDeliveryWindow)) {
                nextTasks[i] = {
                    id: task.id,
                    title: task.title,
                    dateKey: task.dateKey,
                    dueAt: task.dueAt,
                    reminderMinutes: task.reminderMinutes,
                    completed: task.completed,
                    reminded: true,
                    acknowledged: false
                }
                dueReminders.push({
                    id: task.id,
                    title: task.title,
                    dueLabel: Qt.formatDateTime(new Date(dueAt), "ddd, MMM d h:mm AP")
                })
                changed = true
            }
        }

        if (changed)
            tasks = nextTasks
        if (changed || dueReminders.length > 0) {
            pendingReminders = pendingReminders.concat(dueReminders)
            saveTasks()
        } else if (pendingReminders.length > 0) {
            saveTasks()
        }
    }

    Process {
        id: createDataDirectory
        command: ["/usr/bin/mkdir", "-p", store.dataDirectory]
        running: true
        stderr: StdioCollector { id: createDirectoryError }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                store.ready = true
                store.writable = false
                var detail = createDirectoryError.text.trim()
                store.errorMessage = "Could not create the local calendar task folder (exit " + exitCode + ")"
                    + (detail.length > 0 ? ": " + detail : ".")
                console.warn("Anarchy-Bar: failed to create task directory:", detail)
                return
            }
            store.directoryReady = true
        }
    }

    FileView {
        id: taskFile
        path: store.directoryReady ? store.taskFilePath : ""
        watchChanges: false

        onLoaded: store.loadTasks(text())
        onLoadFailed: error => {
            if (!store.directoryReady) return
            if (error === FileViewError.FileNotFound) {
                store.tasks = []
                store.ready = true
                store.writePending = true
                setText("[]")
            } else {
                store.ready = true
                store.writable = false
                store.errorMessage = "Could not load calendar tasks."
                console.warn("Anarchy-Bar: failed to load calendar tasks:", error)
            }
        }
        onSaved: {
            store.writePending = false
            if (store.saveAgain) {
                store.saveAgain = false
                store.saveTasks()
                return
            }
            store.errorMessage = ""
            store.tasksSaved()
            var reminders = store.pendingReminders.slice()
            store.pendingReminders = []
            for (var i = 0; i < reminders.length; i++) {
                store.reminderTriggered(reminders[i].id, reminders[i].title, reminders[i].dueLabel)
            }
        }
        onSaveFailed: error => {
            store.writePending = false
            store.writable = false
            store.errorMessage = "Could not save calendar tasks."
            console.warn("Anarchy-Bar: failed to save calendar tasks:", error)
            store.tasksSaveFailed(store.errorMessage)
        }
    }

    Timer {
        id: reminderTimer
        interval: 15000
        repeat: true
        running: store.ready && store.writable
        onTriggered: store.checkReminders(false)
    }
}
