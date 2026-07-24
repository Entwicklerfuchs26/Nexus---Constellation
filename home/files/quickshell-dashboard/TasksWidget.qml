import QtQuick
import QtQuick.Layouts

Item {
    id: tasks
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"

    property bool configured: false
    property var taskList: []
    property var noDueTaskList: []
    property bool showNoDue: false

    function _baseUrl() {
        var u = creds.vikunjaUrl
        if (u.length > 0 && u.charAt(u.length - 1) !== "/") u += "/"
        return u + "api/v1/"
    }

    function hasNoDueDate(iso) {
        return !iso || iso.indexOf("0001-01-01") === 0
    }

    function isDueOrOverdue(iso) {
        if (tasks.hasNoDueDate(iso)) return false
        var endOfToday = new Date()
        endOfToday.setHours(23, 59, 59, 999)
        return new Date(iso) <= endOfToday
    }

    function _byPriorityDesc(a, b) {
        return (b.priority || 0) - (a.priority || 0)
    }

    function _findIndex(list, taskId) {
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === taskId) return i
        }
        return -1
    }

    function fetchTasks() {
        var url = tasks._baseUrl()
            + "tasks/all?filter_by=done&filter_value=false&filter_comparator=equals"
            + "&sort_by=priority&order_by=desc&per_page=50"

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log("Tasks-Widget: HTTP-Fehler", xhr.status)
                return
            }
            try {
                var all = JSON.parse(xhr.responseText)
                var due = all.filter(function (t) { return !t.done && tasks.isDueOrOverdue(t.due_date) })
                due.sort(tasks._byPriorityDesc)
                var noDue = all.filter(function (t) { return !t.done && tasks.hasNoDueDate(t.due_date) })
                noDue.sort(tasks._byPriorityDesc)
                tasks.taskList = due
                tasks.noDueTaskList = noDue
            } catch (e) {
                console.log("Tasks-Widget: Parse-Fehler", e)
            }
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("Authorization", "Bearer " + creds.vikunjaApiToken)
        xhr.send()
    }

    function toggleDone(task) {
        var inDue = tasks._findIndex(tasks.taskList, task.id) !== -1
        var list = inDue ? tasks.taskList : tasks.noDueTaskList
        var idx = tasks._findIndex(list, task.id)
        if (idx === -1) return

        var wasDone = task.done
        var updated = list.slice()
        updated[idx] = Object.assign({}, updated[idx], { done: !wasDone })
        if (inDue) tasks.taskList = updated
        else tasks.noDueTaskList = updated

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log("Tasks-Widget: PATCH-Fehler", xhr.status)
                var reverted = updated.slice()
                reverted[idx] = Object.assign({}, reverted[idx], { done: wasDone })
                if (inDue) tasks.taskList = reverted
                else tasks.noDueTaskList = reverted
            }
        }
        xhr.open("PATCH", tasks._baseUrl() + "tasks/" + task.id)
        xhr.setRequestHeader("Authorization", "Bearer " + creds.vikunjaApiToken)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({ id: task.id, done: !wasDone }))
    }

    CredentialsLoader {
        id: creds
        onCredentialsLoaded: {
            tasks.configured = !creds.isPlaceholder(creds.vikunjaUrl, "VIKUNJA_URL")
            if (tasks.configured) tasks.fetchTasks()
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: if (tasks.configured) tasks.fetchTasks()
    }

    Text {
        anchors.centerIn: parent
        visible: !tasks.configured
        text: "Tasks nicht konfiguriert"
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        opacity: 0.35
        color: tasks.textColor
    }

    Text {
        anchors.centerIn: parent
        visible: tasks.configured && tasks.taskList.length === 0 && tasks.noDueTaskList.length === 0
        text: "Keine offenen Tasks"
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        opacity: 0.4
        color: tasks.textColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        visible: tasks.configured

        Repeater {
            model: tasks.taskList

            TaskRow {
                required property var modelData
                task: modelData
                textColor: tasks.textColor
                accentColor: tasks.accentColor
                onToggleRequested: tasks.toggleDone(modelData)
            }
        }

        Text {
            visible: tasks.noDueTaskList.length > 0
            text: (tasks.showNoDue ? "▾ " : "▸ ") + tasks.noDueTaskList.length + " ohne Fälligkeitsdatum"
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            opacity: 0.5
            color: tasks.textColor

            MouseArea {
                anchors.fill: parent
                onClicked: tasks.showNoDue = !tasks.showNoDue
            }
        }

        Repeater {
            model: tasks.showNoDue ? tasks.noDueTaskList : []

            TaskRow {
                required property var modelData
                task: modelData
                textColor: tasks.textColor
                accentColor: tasks.accentColor
                onToggleRequested: tasks.toggleDone(modelData)
            }
        }
    }
}
