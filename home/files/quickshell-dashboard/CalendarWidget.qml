import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: calendar
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"

    property bool configured: false
    property var days: []

    function unescapeIcal(s) {
        return s.replace(/\\n/gi, " ").replace(/\\,/g, ",").replace(/\\;/g, ";").replace(/\\\\/g, "\\")
    }

    function parseICalDate(raw) {
        var m = raw.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/)
        if (!m) return null
        if (m[4] === undefined) {
            return { date: new Date(+m[1], +m[2] - 1, +m[3]), allDay: true }
        }
        if (m[7] === "Z") {
            return { date: new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6])), allDay: false }
        }
        return { date: new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]), allDay: false }
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
    }

    function dayLabel(offset, date) {
        if (offset === 0) return "Heute"
        if (offset === 1) return "Morgen"
        return Qt.formatDate(date, "dddd")
    }

    function parseEvents(icalText) {
        var events = []
        var blocks = icalText.match(/BEGIN:VEVENT[\s\S]*?END:VEVENT/g) || []
        for (var i = 0; i < blocks.length; i++) {
            var block = blocks[i]
            var startMatch = block.match(/^DTSTART[^:\r\n]*:([^\r\n]*)/m)
            if (!startMatch) continue
            var start = calendar.parseICalDate(startMatch[1].trim())
            if (!start) continue
            var summaryMatch = block.match(/^SUMMARY[^:\r\n]*:([^\r\n]*)/m)
            var summary = summaryMatch ? calendar.unescapeIcal(summaryMatch[1].trim()) : "(ohne Titel)"
            events.push({ date: start.date, allDay: start.allDay, summary: summary })
        }
        events.sort(function (a, b) { return a.date - b.date })
        return events
    }

    function rebuildDays(events) {
        var today = new Date()
        today.setHours(0, 0, 0, 0)
        var buckets = []
        for (var offset = 0; offset < 4; offset++) {
            var d = new Date(today)
            d.setDate(d.getDate() + offset)
            buckets.push({ label: calendar.dayLabel(offset, d), date: d, events: [] })
        }
        for (var i = 0; i < events.length; i++) {
            for (var b = 0; b < buckets.length; b++) {
                if (calendar.sameDay(events[i].date, buckets[b].date)) {
                    buckets[b].events.push(events[i])
                    break
                }
            }
        }
        calendar.days = buckets
    }

    function _origin() {
        return creds.caldavUrl.replace(/\/+$/, "")
    }

    // Qt/QML's XMLHttpRequest rejects non-standard HTTP verbs ("Unsupported HTTP
    // method type"), so the CalDAV REPORT request has to go through curl via
    // Process instead (same rationale as CredentialsLoader's Process-based read).
    function _shQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function fetchEvents() {
        var calendars = creds.caldavCalendars
        if (calendars.length === 0) return

        var today = new Date()
        today.setHours(0, 0, 0, 0)
        var rangeEnd = new Date(today)
        rangeEnd.setDate(rangeEnd.getDate() + 4)

        var pad = function (n) { return (n < 10 ? "0" : "") + n }
        var fmt = function (d) { return d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + "T000000Z" }

        var body = '<?xml version="1.0" encoding="utf-8" ?>'
            + '<C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">'
            + '<D:prop><D:getetag/><C:calendar-data/></D:prop>'
            + '<C:filter><C:comp-filter name="VCALENDAR"><C:comp-filter name="VEVENT">'
            + '<C:time-range start="' + fmt(today) + '" end="' + fmt(rangeEnd) + '"/>'
            + '</C:comp-filter></C:comp-filter></C:filter>'
            + '</C:calendar-query>'

        var origin = calendar._origin()
        var auth = creds.caldavUser + ":" + creds.caldavPassword

        var script = ""
        for (var i = 0; i < calendars.length; i++) {
            var url = origin + calendars[i]
            script += "echo '___CAL_START___'\n"
            script += "timeout 5 curl -s -X REPORT " + calendar._shQuote(url)
                + " -H 'Depth: 1' -H 'Content-Type: application/xml; charset=utf-8'"
                + " -u " + calendar._shQuote(auth)
                + " --data " + calendar._shQuote(body) + "\n"
            script += "echo '___CAL_END___'\n"
        }

        fetcher.command = ["bash", "-c", script]
        fetcher.running = true
    }

    function _handleFetchOutput(text) {
        var blocks = text.split("___CAL_START___").slice(1).map(function (b) {
            return b.split("___CAL_END___")[0]
        })
        var merged = []
        for (var i = 0; i < blocks.length; i++) {
            try {
                merged = merged.concat(calendar.parseEvents(blocks[i]))
            } catch (e) {
                console.log("Kalender-Widget: Parse-Fehler", e)
            }
        }
        merged.sort(function (a, b) { return a.date - b.date })
        calendar.rebuildDays(merged)
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: calendar._handleFetchOutput(this.text)
        }
    }

    CredentialsLoader {
        id: creds
        onCredentialsLoaded: {
            calendar.configured = !creds.isPlaceholder(creds.caldavUrl, "CALDAV_URL") && creds.caldavCalendars.length > 0
            if (calendar.configured) calendar.fetchEvents()
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: if (calendar.configured) calendar.fetchEvents()
    }

    Text {
        anchors.centerIn: parent
        visible: !calendar.configured
        text: "Kalender nicht konfiguriert"
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        opacity: 0.35
        color: calendar.textColor
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        visible: calendar.configured

        Repeater {
            model: calendar.days

            ColumnLayout {
                id: dayCol
                required property var modelData
                Layout.fillWidth: true
                spacing: 3
                visible: modelData.events.length > 0

                Text {
                    text: dayCol.modelData.label
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.bold: true
                    opacity: 0.7
                    color: calendar.textColor
                }

                Repeater {
                    model: dayCol.modelData.events

                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: modelData.allDay ? "Ganztägig" : Qt.formatTime(modelData.date, "hh:mm")
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            opacity: 0.6
                            color: calendar.textColor
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            color: calendar.textColor
                        }
                    }
                }
            }
        }

        Text {
            visible: calendar.days.length > 0 && calendar.days.every(function (d) { return d.events.length === 0 })
            text: "Keine Termine"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.4
            color: calendar.textColor
        }
    }
}
