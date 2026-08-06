import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: calendar
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color subTextColor: "#aaaaaa"
    property color accentColor: "#c6b22b"
    property color boxColor: "#201d13"
    property color errorColor: "#ba1a1a"
    property bool active: true

    property bool configured: false
    property var selectedDate: calendar._todayMidnight()
    property var dayBuckets: ({})
    property var fetchRangeStart: null
    property var fetchRangeEnd: null
    property var _pendingRangeStart: null
    property var _pendingRangeEnd: null
    property var nowTick: new Date()

    readonly property int hourHeight: 48
    readonly property int gridPad: 8
    readonly property var currentDay: calendar.dayBuckets[calendar._isoDate(calendar.selectedDate)] || { allDay: [], timed: [] }

    Timer {
        interval: 30000
        running: calendar.active
        repeat: true
        onTriggered: calendar.nowTick = new Date()
    }

    // ── Datums-Helfer ────────────────────────────────────────────────────
    function _pad2(n) { return (n < 10 ? "0" : "") + n }
    function _isoDate(d) { return d.getFullYear() + "-" + calendar._pad2(d.getMonth() + 1) + "-" + calendar._pad2(d.getDate()) }
    function _todayMidnight() { var d = new Date(); d.setHours(0, 0, 0, 0); return d }
    function _addDays(d, n) { var r = new Date(d); r.setDate(r.getDate() + n); return r }
    function _sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }
    function _nowMinutes() { var n = calendar.nowTick; return n.getHours() * 60 + n.getMinutes() }

    function headerLabel() {
        var today = calendar._todayMidnight()
        if (calendar._sameDay(calendar.selectedDate, today)) return "Heute"
        if (calendar._sameDay(calendar.selectedDate, calendar._addDays(today, 1))) return "Morgen"
        if (calendar._sameDay(calendar.selectedDate, calendar._addDays(today, -1))) return "Gestern"
        return Qt.formatDate(calendar.selectedDate, "dddd")
    }

    function navPrev() { calendar.selectDay(calendar._addDays(calendar.selectedDate, -1)) }
    function navNext() { calendar.selectDay(calendar._addDays(calendar.selectedDate, 1)) }

    function selectDay(d) {
        calendar.selectedDate = d
        if (!calendar.fetchRangeStart || d < calendar.fetchRangeStart || d > calendar.fetchRangeEnd) {
            calendar.fetchEvents(d)
        }
        Qt.callLater(calendar._scrollToRelevant)
    }

    function openInBrowser() {
        if (!calendar.configured) return
        var url = calendar._origin() + "/apps/calendar/timeGridDay/" + calendar._isoDate(calendar.selectedDate)
        launcher.exec(["xdg-open", url])
    }

    function _scrollToRelevant() {
        if (!timelineFlick.visible) return
        var totalHeight = calendar.hourHeight * 24
        if (calendar._sameDay(calendar.selectedDate, calendar._todayMidnight())) {
            var y = calendar.gridPad + (calendar._nowMinutes() / 1440) * totalHeight
            timelineFlick.contentY = Math.max(0, y - timelineFlick.height * 0.35)
        } else {
            var earliest = 7 * 60
            if (calendar.currentDay.timed.length > 0) earliest = calendar.currentDay.timed[0].startMin
            var y2 = calendar.gridPad + (earliest / 1440) * totalHeight
            timelineFlick.contentY = Math.max(0, y2 - 40)
        }
    }

    Process { id: launcher }

    // ── iCal-Parsing ─────────────────────────────────────────────────────
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

    function parseEvents(icalText) {
        var events = []
        var blocks = icalText.match(/BEGIN:VEVENT[\s\S]*?END:VEVENT/g) || []
        for (var i = 0; i < blocks.length; i++) {
            var block = blocks[i]
            var startMatch = block.match(/^DTSTART[^:\r\n]*:([^\r\n]*)/m)
            if (!startMatch) continue
            var start = calendar.parseICalDate(startMatch[1].trim())
            if (!start) continue
            var endMatch = block.match(/^DTEND[^:\r\n]*:([^\r\n]*)/m)
            var end = endMatch ? calendar.parseICalDate(endMatch[1].trim()) : null
            var summaryMatch = block.match(/^SUMMARY[^:\r\n]*:([^\r\n]*)/m)
            var summary = summaryMatch ? calendar.unescapeIcal(summaryMatch[1].trim()) : "(ohne Titel)"

            var endDate = end ? end.date : null
            if (!endDate) {
                endDate = new Date(start.date)
                if (start.allDay) endDate.setDate(endDate.getDate() + 1)
                else endDate.setMinutes(endDate.getMinutes() + 60)
            }
            events.push({ start: start.date, end: endDate, allDay: start.allDay, summary: summary })
        }
        events.sort(function (a, b) { return a.start - b.start })
        return events
    }

    // ── Tages-Buckets (inkl. Split mehrtägiger Termine) ─────────────────
    function _assignColumns(list) {
        var colEnds = []
        for (var i = 0; i < list.length; i++) {
            var ev = list[i]
            var placed = false
            for (var c = 0; c < colEnds.length; c++) {
                if (colEnds[c] <= ev.startMin) { ev.col = c; colEnds[c] = ev.endMin; placed = true; break }
            }
            if (!placed) { ev.col = colEnds.length; colEnds.push(ev.endMin) }
        }
        var maxCols = colEnds.length || 1
        for (var j = 0; j < list.length; j++) list[j].colCount = maxCols
    }

    function rebuildBuckets(events, rangeStart, rangeEndInclusive) {
        var buckets = {}
        var cursor = new Date(rangeStart)
        while (cursor <= rangeEndInclusive) {
            buckets[calendar._isoDate(cursor)] = { allDay: [], timed: [] }
            cursor.setDate(cursor.getDate() + 1)
        }
        for (var i = 0; i < events.length; i++) {
            var ev = events[i]
            if (ev.allDay) {
                var d = new Date(ev.start)
                while (d < ev.end) {
                    var key = calendar._isoDate(d)
                    if (buckets[key]) buckets[key].allDay.push(ev)
                    d.setDate(d.getDate() + 1)
                }
            } else {
                var segStart = new Date(ev.start)
                while (segStart < ev.end) {
                    var dayStart = new Date(segStart.getFullYear(), segStart.getMonth(), segStart.getDate())
                    var dayEnd = new Date(dayStart)
                    dayEnd.setDate(dayEnd.getDate() + 1)
                    var segEnd = ev.end < dayEnd ? ev.end : dayEnd
                    var bKey = calendar._isoDate(dayStart)
                    if (buckets[bKey]) {
                        buckets[bKey].timed.push({
                            summary: ev.summary,
                            start: segStart,
                            startMin: segStart.getHours() * 60 + segStart.getMinutes(),
                            endMin: (segEnd.getTime() === dayEnd.getTime()) ? 1440 : (segEnd.getHours() * 60 + segEnd.getMinutes())
                        })
                    }
                    segStart = segEnd
                }
            }
        }
        for (var key2 in buckets) {
            buckets[key2].timed.sort(function (a, b) { return a.startMin - b.startMin })
            calendar._assignColumns(buckets[key2].timed)
        }
        calendar.dayBuckets = buckets
        Qt.callLater(calendar._scrollToRelevant)
    }

    // ── CalDAV-Abruf (REPORT via curl/Process, XMLHttpRequest kann kein REPORT) ──
    function _origin() {
        return creds.caldavUrl.replace(/\/+$/, "")
    }

    function _shQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function fetchEvents(centerDate) {
        var calendars = creds.caldavCalendars
        if (calendars.length === 0) return

        var center = centerDate || calendar.selectedDate
        var rangeStart = calendar._addDays(center, -7)
        var rangeEndExclusive = calendar._addDays(center, 22)
        calendar.fetchRangeStart = rangeStart
        calendar.fetchRangeEnd = calendar._addDays(rangeEndExclusive, -1)
        calendar._pendingRangeStart = rangeStart
        calendar._pendingRangeEnd = calendar.fetchRangeEnd

        var pad = function (n) { return (n < 10 ? "0" : "") + n }
        var fmt = function (d) { return d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + "T000000Z" }

        var body = '<?xml version="1.0" encoding="utf-8" ?>'
            + '<C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">'
            + '<D:prop><D:getetag/><C:calendar-data/></D:prop>'
            + '<C:filter><C:comp-filter name="VCALENDAR"><C:comp-filter name="VEVENT">'
            + '<C:time-range start="' + fmt(rangeStart) + '" end="' + fmt(rangeEndExclusive) + '"/>'
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
        merged.sort(function (a, b) { return a.start - b.start })
        calendar.rebuildBuckets(merged, calendar._pendingRangeStart, calendar._pendingRangeEnd)
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
            if (calendar.configured) calendar.fetchEvents(calendar.selectedDate)
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: if (calendar.configured) calendar.fetchEvents(calendar.selectedDate)
    }

    // ── UI ───────────────────────────────────────────────────────────────
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
        spacing: 8
        visible: calendar.configured

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                radius: 8
                color: Qt.rgba(calendar.boxColor.r, calendar.boxColor.g, calendar.boxColor.b, 0.55)
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Text { anchors.centerIn: parent; text: "‹"; color: calendar.textColor; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: calendar.navPrev() }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: calendar.headerLabel()
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: 13
                    color: calendar.textColor
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(calendar.selectedDate, "dd. MMMM")
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    opacity: 0.55
                    color: calendar.textColor
                }
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(calendar.boxColor.r, calendar.boxColor.g, calendar.boxColor.b, 0.55)
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Text { anchors.centerIn: parent; text: "›"; color: calendar.textColor; font.pixelSize: 14 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: calendar.navNext() }
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(calendar.accentColor.r, calendar.accentColor.g, calendar.accentColor.b, openArea.containsMouse ? 0.35 : 0.18)
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Text { anchors.centerIn: parent; text: "↗"; color: calendar.textColor; font.pixelSize: 13 }
                MouseArea { id: openArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: calendar.openInBrowser() }
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: calendar.currentDay.allDay.length > 0
            spacing: 6

            Repeater {
                model: calendar.currentDay.allDay
                delegate: Rectangle {
                    required property var modelData
                    radius: 6
                    color: Qt.rgba(calendar.accentColor.r, calendar.accentColor.g, calendar.accentColor.b, 0.25)
                    width: chipText.implicitWidth + 14
                    height: chipText.implicitHeight + 8
                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: modelData.summary
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        color: calendar.textColor
                    }
                }
            }
        }

        Flickable {
            id: timelineFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: timelineCol.height
            Component.onCompleted: calendar._scrollToRelevant()

            Item {
                id: timelineCol
                width: timelineFlick.width
                height: calendar.hourHeight * 24 + calendar.gridPad * 2

                Repeater {
                    model: 25
                    delegate: Item {
                        required property int index
                        y: calendar.gridPad + index * calendar.hourHeight
                        width: timelineCol.width
                        height: 1

                        Text {
                            text: calendar._pad2(index) + ":00"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            opacity: 0.4
                            color: calendar.textColor
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 40
                            anchors.right: parent.right
                            height: 1
                            color: Qt.rgba(calendar.textColor.r, calendar.textColor.g, calendar.textColor.b, 0.08)
                        }
                    }
                }

                Repeater {
                    model: calendar.currentDay.timed
                    delegate: Rectangle {
                        id: evBlock
                        required property var modelData
                        readonly property real colWidth: (timelineCol.width - 44) / modelData.colCount
                        x: 44 + modelData.col * colWidth
                        y: calendar.gridPad + (modelData.startMin / 1440) * (calendar.hourHeight * 24)
                        width: Math.max(4, colWidth - 3)
                        height: Math.max(16, ((modelData.endMin - modelData.startMin) / 1440) * (calendar.hourHeight * 24))
                        radius: 5
                        color: Qt.rgba(calendar.accentColor.r, calendar.accentColor.g, calendar.accentColor.b, 0.32)
                        border.color: calendar.accentColor
                        border.width: 1
                        clip: true

                        Text {
                            anchors.fill: parent
                            anchors.margins: 4
                            text: Qt.formatTime(evBlock.modelData.start, "hh:mm") + " " + evBlock.modelData.summary
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: calendar.textColor
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    visible: calendar._sameDay(calendar.selectedDate, calendar._todayMidnight())
                    x: 40
                    y: calendar.gridPad + (calendar._nowMinutes() / 1440) * (calendar.hourHeight * 24) - 1
                    width: timelineCol.width - 40
                    height: 2
                    color: calendar.errorColor

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: calendar.errorColor
                        anchors.right: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: calendar.currentDay.timed.length === 0 && calendar.currentDay.allDay.length === 0
            text: "Keine Termine"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.4
            color: calendar.textColor
        }
    }
}
