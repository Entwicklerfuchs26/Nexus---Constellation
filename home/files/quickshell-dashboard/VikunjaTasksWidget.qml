import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: widget
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color highColor: "#ba1a1a"
    property color mediumColor: "#a9a9ff"

    property bool configured: false
    property bool hasError: false
    property var openTasks: []
    property int doneCount: 0
    readonly property int openCount: widget.openTasks.length

    function _dateOnly(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate())
    }

    function _isOverdue(iso) {
        if (!iso || iso.indexOf("0001-01-01") === 0) return false
        var d = widget._dateOnly(new Date(iso))
        var now = widget._dateOnly(new Date())
        return d.getTime() < now.getTime()
    }

    function _dueLabel(iso) {
        if (!iso || iso.indexOf("0001-01-01") === 0) return ""
        var d = new Date(iso)
        if (widget._isOverdue(iso)) {
            var dd = ("0" + d.getDate()).slice(-2)
            var mo = ("0" + (d.getMonth() + 1)).slice(-2)
            return "überfällig " + dd + "." + mo + "."
        }
        if (d.getHours() === 0 && d.getMinutes() === 0) return "heute"
        var hh = ("0" + d.getHours()).slice(-2)
        var mm = ("0" + d.getMinutes()).slice(-2)
        return hh + ":" + mm
    }

    function _isTodayOrOverdue(iso) {
        if (!iso || iso.indexOf("0001-01-01") === 0) return false
        var d = widget._dateOnly(new Date(iso))
        var now = widget._dateOnly(new Date())
        return d.getTime() <= now.getTime()
    }

    function _byDueThenPriorityDesc(a, b) {
        var da = new Date(a.due_date).getTime()
        var db = new Date(b.due_date).getTime()
        if (da !== db) return da - db
        return (b.priority || 0) - (a.priority || 0)
    }

    function _baseUrl() {
        var u = creds.vikunjaUrl
        if (u.length > 0 && u.charAt(u.length - 1) !== "/") u += "/"
        return u + "api/v1/"
    }

    function _todayDateStr() {
        var now = new Date()
        var mm = ("0" + (now.getMonth() + 1)).slice(-2)
        var dd = ("0" + now.getDate()).slice(-2)
        return now.getFullYear() + "-" + mm + "-" + dd
    }

    function fetchTasks() {
        widget.hasError = false
        var today = widget._todayDateStr()
        var filter = "done = false && due_date >= '0001-01-02T00:00:00' && due_date <= '" + today + "T23:59:59'"
        var url = widget._baseUrl() + "tasks"
            + "?filter=" + encodeURIComponent(filter)
            + "&sort_by=priority&order_by=desc&per_page=50"

        var xhr = new XMLHttpRequest()
        xhr.timeout = 5000
        xhr.ontimeout = function () {
            console.log("VikunjaTasks: Zeitüberschreitung")
            widget.hasError = true
        }
        xhr.onerror = function () {
            console.log("VikunjaTasks: Netzwerkfehler")
            widget.hasError = true
        }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log("VikunjaTasks: HTTP-Fehler", xhr.status)
                widget.hasError = true
                return
            }
            try {
                var all = JSON.parse(xhr.responseText)
                // Server filtert bereits auf heute-oder-überfällig+offen; Client-Filter als Absicherung gegen Zeitzonen-Kanten.
                var due = all.filter(function (t) { return !t.done && widget._isTodayOrOverdue(t.due_date) })
                due.sort(widget._byDueThenPriorityDesc)
                due.forEach(function (t) { t.dueLabel = widget._dueLabel(t.due_date); t.overdue = widget._isOverdue(t.due_date) })
                widget.openTasks = due
            } catch (e) {
                console.log("VikunjaTasks: Parse-Fehler", e)
                widget.hasError = true
            }
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("Authorization", "Bearer " + creds.vikunjaApiToken)
        xhr.send()
    }

    function toggleDone(task) {
        var idx = -1
        for (var i = 0; i < widget.openTasks.length; i++) {
            if (widget.openTasks[i].id === task.id) { idx = i; break }
        }
        if (idx === -1) return

        var updated = widget.openTasks.slice()
        updated[idx] = Object.assign({}, updated[idx], { done: true })
        widget.openTasks = updated
        widget.doneCount += 1

        removeTimer.taskId = task.id
        removeTimer.restart()

        var xhr = new XMLHttpRequest()
        xhr.timeout = 5000
        xhr.ontimeout = function () {
            console.log("VikunjaTasks: PATCH-Zeitüberschreitung")
        }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log("VikunjaTasks: PATCH-Fehler", xhr.status)
            }
        }
        xhr.open("PATCH", widget._baseUrl() + "tasks/" + task.id)
        xhr.setRequestHeader("Authorization", "Bearer " + creds.vikunjaApiToken)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({ id: task.id, done: true }))
    }

    function openVikunja() {
        if (!creds.vikunjaUrl) return
        launcher.exec(["xdg-open", creds.vikunjaUrl])
    }

    Timer {
        id: removeTimer
        property var taskId: null
        interval: 450
        repeat: false
        onTriggered: {
            widget.openTasks = widget.openTasks.filter(function (t) { return t.id !== removeTimer.taskId })
        }
    }

    Process { id: launcher }

    CredentialsLoader {
        id: creds
        onCredentialsLoaded: {
            widget.configured = !creds.isPlaceholder(creds.vikunjaUrl, "VIKUNJA_URL")
            if (widget.configured) widget.fetchTasks()
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: if (widget.configured) widget.fetchTasks()
    }

    Text {
        anchors.centerIn: parent
        visible: !widget.configured
        text: "Tasks nicht konfiguriert"
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        opacity: 0.35
        color: widget.textColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        visible: widget.configured && !widget.hasError

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                radius: 8
                color: Qt.rgba(widget.accentColor.r, widget.accentColor.g, widget.accentColor.b, 0.2)
                Layout.preferredWidth: badgeText.implicitWidth + 14
                Layout.preferredHeight: badgeText.implicitHeight + 4

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: widget.openCount + " offen / " + widget.doneCount + " erledigt"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    color: widget.textColor
                }
            }

            Item { Layout.fillWidth: true }
        }

        Text {
            Layout.fillWidth: true
            visible: widget.openTasks.length === 0
            text: "Keine offenen oder überfälligen Tasks 🎉"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.5
            wrapMode: Text.WordWrap
            color: widget.textColor
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: widget.openTasks.length > 0
            clip: true
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            model: widget.openTasks

            delegate: VikunjaTaskRow {
                required property var modelData
                width: ListView.view.width
                task: modelData
                textColor: widget.textColor
                accentColor: widget.accentColor
                highColor: widget.highColor
                mediumColor: widget.mediumColor
                onToggleRequested: widget.toggleDone(modelData)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 8
            color: Qt.rgba(widget.accentColor.r, widget.accentColor.g, widget.accentColor.b, openBtnArea.containsMouse ? 0.3 : 0.18)

            Text {
                anchors.centerIn: parent
                text: "Vikunja öffnen"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: widget.textColor
            }

            MouseArea {
                id: openBtnArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: widget.openVikunja()
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10
        visible: widget.configured && widget.hasError

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Vikunja nicht erreichbar"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.6
            color: widget.textColor
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: retryText.implicitWidth + 24
            Layout.preferredHeight: retryText.implicitHeight + 12
            radius: 8
            color: Qt.rgba(widget.accentColor.r, widget.accentColor.g, widget.accentColor.b, retryArea.containsMouse ? 0.3 : 0.18)

            Text {
                id: retryText
                anchors.centerIn: parent
                text: "Erneut versuchen"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                color: widget.textColor
            }

            MouseArea {
                id: retryArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: widget.fetchTasks()
            }
        }
    }
}
