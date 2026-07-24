import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: activity
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"

    readonly property string baseUrl: "http://localhost:5600"

    property bool checking: true
    property bool serverUp: false
    property bool starting: false

    property var topApps: []
    property real activeSeconds: 0
    property real idleSeconds: 0

    function _get(url, onDone) {
        var xhr = new XMLHttpRequest()
        xhr.timeout = 5000
        xhr.ontimeout = function () { onDone(null) }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) { onDone(null); return }
            try { onDone(JSON.parse(xhr.responseText)) } catch (e) { onDone(null) }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function checkAndLoad() {
        activity.checking = true
        activity._get(activity.baseUrl + "/api/0/info", function (info) {
            if (!info) {
                activity.checking = false
                activity.serverUp = false
                return
            }
            activity.serverUp = true
            activity._loadBuckets()
        })
    }

    function _loadBuckets() {
        activity._get(activity.baseUrl + "/api/0/buckets/", function (buckets) {
            if (!buckets) { activity.checking = false; return }
            var windowId = null
            var afkId = null
            for (var id in buckets) {
                if (id.indexOf("aw-watcher-window") === 0) windowId = id
                if (id.indexOf("aw-watcher-afk") === 0) afkId = id
            }
            if (!windowId && !afkId) { activity.checking = false; return }

            var today = new Date()
            today.setHours(0, 0, 0, 0)
            var startIso = today.toISOString()
            var endIso = new Date().toISOString()
            var qs = "?start=" + encodeURIComponent(startIso) + "&end=" + encodeURIComponent(endIso) + "&limit=-1"

            var pending = 0
            var windowEvents = []
            var afkEvents = []

            if (windowId) {
                pending++
                activity._get(activity.baseUrl + "/api/0/buckets/" + windowId + "/events" + qs, function (data) {
                    windowEvents = data || []
                    pending--
                    if (pending === 0) activity._finish(windowEvents, afkEvents)
                })
            }
            if (afkId) {
                pending++
                activity._get(activity.baseUrl + "/api/0/buckets/" + afkId + "/events" + qs, function (data) {
                    afkEvents = data || []
                    pending--
                    if (pending === 0) activity._finish(windowEvents, afkEvents)
                })
            }
            if (pending === 0) activity.checking = false
        })
    }

    function _finish(windowEvents, afkEvents) {
        var perApp = {}
        for (var i = 0; i < windowEvents.length; i++) {
            var ev = windowEvents[i]
            var app = (ev.data && ev.data.app) ? ev.data.app : "?"
            perApp[app] = (perApp[app] || 0) + (ev.duration || 0)
        }
        var list = []
        for (var a in perApp) list.push({ app: a, seconds: perApp[a] })
        list.sort(function (x, y) { return y.seconds - x.seconds })
        activity.topApps = list.slice(0, 5)

        var active = 0
        var idle = 0
        for (var j = 0; j < afkEvents.length; j++) {
            var e = afkEvents[j]
            if (e.data && e.data.status === "not-afk") active += (e.duration || 0)
            else idle += (e.duration || 0)
        }
        activity.activeSeconds = active
        activity.idleSeconds = idle
        activity.checking = false
    }

    function formatDuration(seconds) {
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        if (h > 0) return h + "h " + m + "min"
        return m + "min"
    }

    function startServer() {
        activity.starting = true
        starterProc.running = true
    }

    Process {
        id: starterProc
        command: ["bash", "-c", "timeout 5 systemctl --user start aw-server aw-watcher-afk aw-watcher-window 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                activity.starting = false
                activity.checkAndLoad()
            }
        }
    }

    Component.onCompleted: checkAndLoad()
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: activity.checkAndLoad()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            visible: activity.checking
            text: "Lädt…"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: activity.textColor
        }

        ColumnLayout {
            visible: !activity.checking && !activity.serverUp
            spacing: 8

            Text {
                text: "ActivityWatch läuft nicht"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                opacity: 0.6
                color: activity.textColor
            }

            Text {
                Layout.maximumWidth: 260
                wrapMode: Text.WordWrap
                text: "Dienst installiert, aber nicht gestartet — oder noch nicht ausgerollt (Rebuild nötig)."
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                opacity: 0.45
                color: activity.textColor
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(activity.textColor.r, activity.textColor.g, activity.textColor.b, startMouse.containsMouse ? 0.14 : 0.08)
                Layout.preferredWidth: startLabel.implicitWidth + 20
                Layout.preferredHeight: 26

                Text {
                    id: startLabel
                    anchors.centerIn: parent
                    text: activity.starting ? "…" : "aw-server starten"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: activity.textColor
                }

                MouseArea {
                    id: startMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: activity.startServer()
                }
            }
        }

        ColumnLayout {
            visible: !activity.checking && activity.serverUp
            Layout.fillWidth: true
            spacing: 10

            RowLayout {
                spacing: 20
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: activity.formatDuration(activity.activeSeconds)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                        font.bold: true
                        color: activity.textColor
                    }
                    Text {
                        text: "aktiv"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        opacity: 0.5
                        color: activity.textColor
                    }
                }
                ColumnLayout {
                    spacing: 2
                    Text {
                        text: activity.formatDuration(activity.idleSeconds)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                        font.bold: true
                        color: activity.textColor
                    }
                    Text {
                        text: "idle"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        opacity: 0.5
                        color: activity.textColor
                    }
                }
            }

            Text {
                visible: activity.topApps.length > 0
                text: "Top Apps heute"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                opacity: 0.5
                color: activity.textColor
            }

            Repeater {
                model: activity.topApps

                RowLayout {
                    id: appRow
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: appRow.modelData.app
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        color: activity.textColor
                    }
                    Text {
                        text: activity.formatDuration(appRow.modelData.seconds)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        opacity: 0.6
                        color: activity.textColor
                    }
                }
            }
        }
    }
}
