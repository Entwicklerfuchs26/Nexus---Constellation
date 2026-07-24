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

    function _baseUrl() {
        var u = creds.vikunjaUrl
        if (u.length > 0 && u.charAt(u.length - 1) !== "/") u += "/"
        return u
    }

    function isToday(iso) {
        if (!iso || iso.indexOf("0001-01-01") === 0) return false
        var d = new Date(iso)
        var now = new Date()
        return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate()
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
                var todays = all.filter(function (t) { return !t.done && tasks.isToday(t.due_date) })
                todays.sort(function (a, b) { return (b.priority || 0) - (a.priority || 0) })
                tasks.taskList = todays
            } catch (e) {
                console.log("Tasks-Widget: Parse-Fehler", e)
            }
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("Authorization", "Bearer " + creds.vikunjaApiToken)
        xhr.send()
    }

    function toggleDone(task) {
        var idx = -1
        for (var i = 0; i < tasks.taskList.length; i++) {
            if (tasks.taskList[i].id === task.id) { idx = i; break }
        }
        if (idx === -1) return

        var wasDone = task.done
        var updated = tasks.taskList.slice()
        updated[idx] = Object.assign({}, updated[idx], { done: !wasDone })
        tasks.taskList = updated

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log("Tasks-Widget: PATCH-Fehler", xhr.status)
                var reverted = tasks.taskList.slice()
                reverted[idx] = Object.assign({}, reverted[idx], { done: wasDone })
                tasks.taskList = reverted
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
        visible: tasks.configured && tasks.taskList.length === 0
        text: "Keine offenen Tasks heute"
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

            RowLayout {
                id: taskRow
                required property var modelData
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 16
                    height: 16
                    radius: 4
                    color: taskRow.modelData.done ? tasks.accentColor : "transparent"
                    border.color: tasks.accentColor
                    border.width: 1.5

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: tasks.toggleDone(taskRow.modelData)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: taskRow.modelData.title
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    font.strikeout: taskRow.modelData.done
                    opacity: taskRow.modelData.done ? 0.4 : 1
                    elide: Text.ElideRight
                    color: tasks.textColor
                }

                Text {
                    visible: taskRow.modelData.priority > 0
                    text: "P" + taskRow.modelData.priority
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    opacity: 0.6
                    color: tasks.textColor
                }

                Rectangle {
                    radius: 8
                    color: Qt.rgba(tasks.accentColor.r, tasks.accentColor.g, tasks.accentColor.b, taskRow.modelData.done ? 0.15 : 0.25)
                    Layout.preferredWidth: badgeText.implicitWidth + 14
                    Layout.preferredHeight: badgeText.implicitHeight + 4

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: taskRow.modelData.done ? "erledigt" : "offen"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        color: tasks.textColor
                    }
                }
            }
        }
    }
}
