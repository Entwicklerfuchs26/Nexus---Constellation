import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: focusRoot
    anchors.fill: parent

    // ── Farben (vom Dashboard über die Matugen-Quelle gebunden) ────────────
    property color textColor: "#ffffff"
    property color subTextColor: "#aaaaaa"
    property color accentColor: "#c6b22b"
    property color accent2Color: "#8caaee"
    property color baseColor: "#15130b"
    property color boxColor: "#201d13"
    property color peachColor: "#f5a97f"
    property real cardOpacity: 0.55
    property bool active: true

    function _hueShift(base, hue) {
        return Qt.hsva(hue, Math.max(0.35, base.hsvSaturation), Math.max(0.55, base.hsvValue), 1.0)
    }
    readonly property color greenColor: focusRoot._hueShift(focusRoot.accentColor, 0.33)

    // ── Pfade (fest, gleiche Konvention wie der focustime-daemon-Nix-Unit) ──
    readonly property string runDir: "/tmp/focustime"
    readonly property string stateDir: "/home/fuchs/.local/state/focustime"

    // ── Navigations-Zustand ──────────────────────────────────────────────
    property string mode: "day"          // "day" | "week" | "appDetail"
    property string selectedDate: focusRoot._todayIso()
    property string selectedApp: ""
    property string selectedAppName: ""
    property var statsData: null

    function _pad2(n) { return (n < 10 ? "0" : "") + n }
    function _todayIso() {
        var d = new Date()
        return d.getFullYear() + "-" + focusRoot._pad2(d.getMonth() + 1) + "-" + focusRoot._pad2(d.getDate())
    }
    function _addDays(iso, n) {
        var parts = iso.split("-")
        var d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
        d.setDate(d.getDate() + n)
        return d.getFullYear() + "-" + focusRoot._pad2(d.getMonth() + 1) + "-" + focusRoot._pad2(d.getDate())
    }
    function _fmtShort(iso) {
        var parts = iso.split("-")
        var months = ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
        return parseInt(parts[2]) + ". " + months[parseInt(parts[1]) - 1]
    }
    function fmtDur(totalSeconds) {
        var s = Math.max(0, Math.round(totalSeconds))
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        if (h > 0) return h + "h " + m + "min"
        return m + "min"
    }

    readonly property bool isToday: focusRoot.selectedDate === focusRoot._todayIso()
    readonly property bool useLiveJson: focusRoot.mode !== "appDetail" && focusRoot.isToday && focusRoot.selectedApp === ""

    function headerTitle() {
        if (focusRoot.mode === "appDetail") {
            return focusRoot.selectedAppName + " – " + focusRoot._fmtShort(focusRoot.selectedDate)
        }
        if (focusRoot.mode === "week") {
            return focusRoot.statsData ? focusRoot.statsData.week_range : "…"
        }
        return focusRoot.isToday ? "Today" : focusRoot._fmtShort(focusRoot.selectedDate)
    }

    function openApp(cls, name) {
        focusRoot.selectedApp = cls
        focusRoot.selectedAppName = name
        focusRoot.mode = "appDetail"
    }
    function goBack() {
        focusRoot.mode = "day"
        focusRoot.selectedApp = ""
        focusRoot.selectedAppName = ""
    }
    function toggleWeekMode() {
        focusRoot.mode = (focusRoot.mode === "week") ? "day" : "week"
    }
    function navPrev() {
        var step = focusRoot.mode === "week" ? 7 : 1
        focusRoot.selectedDate = focusRoot._addDays(focusRoot.selectedDate, -step)
    }
    function navNext() {
        var step = focusRoot.mode === "week" ? 7 : 1
        focusRoot.selectedDate = focusRoot._addDays(focusRoot.selectedDate, step)
    }
    function selectDay(iso) {
        focusRoot.selectedDate = iso
        focusRoot.mode = "day"
        focusRoot.selectedApp = ""
        focusRoot.selectedAppName = ""
    }

    function _applyStats(text) {
        var trimmed = (text || "").trim()
        if (!trimmed) return
        try {
            var d = JSON.parse(trimmed)
            if (d && !d.error) focusRoot.statsData = d
        } catch (e) {
            console.log("FocusTime: JSON-Parse-Fehler:", e)
        }
    }

    Process {
        id: liveProc
        command: ["cat", focusRoot.runDir + "/live.json"]
        stdout: StdioCollector {
            onStreamFinished: focusRoot._applyStats(this.text)
        }
    }

    Process {
        id: queryProc
        stdout: StdioCollector {
            onStreamFinished: focusRoot._applyStats(this.text)
        }
    }

    function _fetchNow() {
        if (focusRoot.useLiveJson) {
            if (!liveProc.running) liveProc.running = true
        } else if (!queryProc.running) {
            var args = ["get_stats.py", focusRoot.selectedDate]
            if (focusRoot.selectedApp !== "") args = args.concat(["--app", focusRoot.selectedApp])
            args = args.concat(["--db-dir", focusRoot.stateDir])
            queryProc.command = args
            queryProc.running = true
        }
    }

    onSelectedDateChanged: focusRoot._fetchNow()
    onSelectedAppChanged: focusRoot._fetchNow()
    onModeChanged: focusRoot._fetchNow()

    Timer {
        interval: focusRoot.useLiveJson ? 1000 : 5000
        running: focusRoot.active
        repeat: true
        triggeredOnStart: true
        onTriggered: focusRoot._fetchNow()
    }

    // ── Kartenhintergrund (translucent, ueber cardOpacity regelbar) ─────────
    Rectangle {
        anchors.fill: parent
        radius: 4
        color: "transparent"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // ── Header ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                visible: focusRoot.mode === "appDetail"
                radius: 8
                color: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: focusRoot.textColor
                    font.pixelSize: 15
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: focusRoot.goBack() }
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: focusRoot.textColor
                    font.pixelSize: 15
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: focusRoot.navPrev() }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: focusRoot.headerTitle()
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: 15
                color: focusRoot.textColor
                elide: Text.ElideRight
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: focusRoot.textColor
                    font.pixelSize: 15
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: focusRoot.navNext() }
            }

            Rectangle {
                visible: focusRoot.mode !== "appDetail"
                radius: 8
                color: Qt.rgba(focusRoot.accentColor.r, focusRoot.accentColor.g, focusRoot.accentColor.b, focusRoot.mode === "week" ? 0.35 : 0.15)
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: focusRoot.textColor
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: focusRoot.toggleWeekMode() }
            }
        }

        // ── Tagesansicht ─────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: focusRoot.mode === "day"

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                Layout.maximumHeight: 76
                spacing: 10

                FocusStatBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    textColor: focusRoot.textColor
                    boxColor: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                    label: "Daily average"
                    value: focusRoot.statsData ? focusRoot.statsData.average : 0
                }
                FocusStatBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    textColor: focusRoot.textColor
                    boxColor: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                    label: "Total"
                    value: focusRoot.statsData ? focusRoot.statsData.total : 0
                }
                FocusStatBox {
                    id: trendBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    textColor: focusRoot.textColor
                    boxColor: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                    label: "Vs. gestern"
                    readonly property int diff: focusRoot.statsData ? (focusRoot.statsData.total - focusRoot.statsData.yesterday) : 0
                    valueOverride: {
                        if (!focusRoot.statsData) return "…"
                        if (focusRoot.statsData.total === 0 && focusRoot.statsData.yesterday === 0) return "No data"
                        if (diff === 0) return "Same time"
                        return focusRoot.fmtDur(Math.abs(diff))
                    }
                    trendUp: diff > 0
                    trendColor: diff > 0 ? focusRoot.peachColor : focusRoot.greenColor
                    showTrend: focusRoot.statsData && diff !== 0 && !(focusRoot.statsData.total === 0 && focusRoot.statsData.yesterday === 0)
                }
            }

            // Wochen-Chart + Monats-Heatmap nebeneinander (kompakter, an Referenz-Proportionen angelehnt)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 190
                Layout.maximumHeight: 190
                spacing: 12

                FocusBarChart {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true
                    values: focusRoot.statsData ? focusRoot.statsData.week.map(function (w) { return w.total }) : []
                    labels: focusRoot.statsData ? focusRoot.statsData.week.map(function (w) { return w.day }) : []
                    isTarget: focusRoot.statsData ? focusRoot.statsData.week.map(function (w) { return w.is_target }) : []
                    barColor: Qt.rgba(focusRoot.accentColor.r, focusRoot.accentColor.g, focusRoot.accentColor.b, 0.55)
                    targetColorA: focusRoot.accentColor
                    targetColorB: focusRoot.accent2Color
                    subTextColor: focusRoot.subTextColor
                    onBarClicked: function (index) {
                        if (focusRoot.statsData && focusRoot.statsData.week[index]) {
                            focusRoot.selectDay(focusRoot.statsData.week[index].date)
                        }
                    }
                }

                GridLayout {
                    id: monthGrid
                    Layout.fillWidth: true
                    Layout.preferredWidth: 100
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 3
                    columnSpacing: 3

                    readonly property real monthMax: {
                        var m = 1
                        var arr = focusRoot.statsData ? focusRoot.statsData.month : []
                        for (var i = 0; i < arr.length; i++) if (arr[i].total > m) m = arr[i].total
                        return m
                    }

                    Repeater {
                        model: focusRoot.statsData ? focusRoot.statsData.month : []
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 3
                            visible: modelData.total >= 0
                            color: Qt.rgba(focusRoot.accentColor.r, focusRoot.accentColor.g, focusRoot.accentColor.b,
                                            modelData.total > 0 ? Math.min(0.9, 0.15 + 0.75 * (modelData.total / monthGrid.monthMax)) : 0.08)
                            border.width: modelData.date === focusRoot.selectedDate ? 1 : 0
                            border.color: focusRoot.textColor

                            Text {
                                anchors.centerIn: parent
                                visible: parent.visible
                                text: modelData.date ? parseInt(modelData.date.split("-")[2]) : ""
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                color: focusRoot.textColor
                                opacity: 0.85
                            }
                            MouseArea {
                                anchors.fill: parent
                                visible: parent.visible
                                cursorShape: Qt.PointingHandCursor
                                onClicked: focusRoot.selectDay(modelData.date)
                            }
                        }
                    }
                }
            }

            // App-Liste — scrollbar, waehrend Header/Statboxen/Charts oben fix bleiben
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                model: focusRoot.statsData ? focusRoot.statsData.apps : []

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 30
                    radius: 8
                    color: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity * 0.7)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 8

                        Image {
                            id: appIcon
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            source: modelData.icon ? "image://icon/" + modelData.icon : ""
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                        Text {
                            visible: !appIcon.visible
                            text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            color: focusRoot.textColor
                            opacity: 0.6
                        }
                        Text {
                            text: modelData.name
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            color: focusRoot.textColor
                            Layout.preferredWidth: 110
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 2.5
                            color: Qt.rgba(focusRoot.textColor.r, focusRoot.textColor.g, focusRoot.textColor.b, 0.1)
                            Rectangle {
                                width: parent.width * Math.min(1, modelData.percent / 100)
                                height: parent.height
                                radius: 2.5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: focusRoot.accentColor }
                                    GradientStop { position: 1.0; color: focusRoot.accent2Color }
                                }
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                            }
                        }
                        Text {
                            text: focusRoot.fmtDur(modelData.seconds)
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            opacity: 0.7
                            color: focusRoot.textColor
                            Layout.preferredWidth: 55
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: focusRoot.openApp(modelData.class, modelData.name)
                    }
                }

                Text {
                    anchors.top: parent.top
                    visible: focusRoot.statsData && focusRoot.statsData.apps.length === 0
                    text: "Keine Daten"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    opacity: 0.4
                    color: focusRoot.textColor
                }
            }
        }

        // ── Wochenansicht ────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: focusRoot.mode === "week"

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                Layout.maximumHeight: 76
                spacing: 10

                FocusStatBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    textColor: focusRoot.textColor
                    boxColor: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                    label: "Daily average"
                    value: focusRoot.statsData ? focusRoot.statsData.average : 0
                }
                FocusStatBox {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    textColor: focusRoot.textColor
                    boxColor: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                    label: "Peak hours"
                    valueOverride: focusRoot.statsData ? focusRoot.statsData.peak_usage_str : "…"
                }
            }

            // 7x24 Heatmap
            ColumnLayout {
                id: heatmapCol
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3

                readonly property real heatMax: {
                    var m = 1
                    var grid = focusRoot.statsData ? focusRoot.statsData.week_heatmap : []
                    for (var i = 0; i < grid.length; i++)
                        for (var j = 0; j < grid[i].length; j++)
                            if (grid[i][j] > m) m = grid[i][j]
                    return m
                }

                Repeater {
                    model: focusRoot.statsData ? focusRoot.statsData.week : []
                    delegate: RowLayout {
                        id: dayRow
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 3

                        Text {
                            text: dayRow.modelData.day
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            opacity: 0.6
                            color: focusRoot.textColor
                            Layout.preferredWidth: 18
                        }

                        Repeater {
                            model: 24
                            delegate: Rectangle {
                                required property int index
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 2
                                readonly property real v: {
                                    var grid = focusRoot.statsData ? focusRoot.statsData.week_heatmap : []
                                    var row = grid[dayRow.index]
                                    return row ? row[index] : 0
                                }
                                color: Qt.rgba(focusRoot.accentColor.r, focusRoot.accentColor.g, focusRoot.accentColor.b,
                                                v > 0 ? Math.min(0.95, 0.12 + 0.8 * (v / heatmapCol.heatMax)) : 0.06)
                            }
                        }
                    }
                }
            }

            // Wochen-Top-Apps
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                spacing: 4
                clip: true

                Repeater {
                    model: focusRoot.statsData ? focusRoot.statsData.week_apps.slice(0, 4) : []
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: modelData.name
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            color: focusRoot.textColor
                            Layout.preferredWidth: 120
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5
                            radius: 2.5
                            color: Qt.rgba(focusRoot.textColor.r, focusRoot.textColor.g, focusRoot.textColor.b, 0.1)
                            Rectangle {
                                width: parent.width * Math.min(1, modelData.percent / 100)
                                height: parent.height
                                radius: 2.5
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: focusRoot.accentColor }
                                    GradientStop { position: 1.0; color: focusRoot.accent2Color }
                                }
                            }
                        }
                        Text {
                            text: focusRoot.fmtDur(modelData.seconds)
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            opacity: 0.7
                            color: focusRoot.textColor
                            Layout.preferredWidth: 55
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }

        // ── App-Detailansicht ────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: focusRoot.mode === "appDetail"

            FocusStatBox {
                Layout.fillWidth: true
                Layout.preferredHeight: 76
                Layout.maximumHeight: 76
                textColor: focusRoot.textColor
                boxColor: Qt.rgba(focusRoot.boxColor.r, focusRoot.boxColor.g, focusRoot.boxColor.b, focusRoot.cardOpacity)
                label: focusRoot.selectedAppName
                value: focusRoot.statsData ? focusRoot.statsData.total : 0
            }

            FocusBarChart {
                Layout.fillWidth: true
                Layout.fillHeight: true
                values: focusRoot.statsData ? focusRoot.statsData.hourly : []
                labels: {
                    var arr = []
                    for (var i = 0; i < 48; i++) arr.push(focusRoot._pad2(Math.floor(i / 2)))
                    return arr
                }
                labelEvery: 2
                isTarget: []
                barColor: Qt.rgba(focusRoot.accentColor.r, focusRoot.accentColor.g, focusRoot.accentColor.b, 0.6)
                targetColorA: focusRoot.accentColor
                targetColorB: focusRoot.accent2Color
                subTextColor: focusRoot.subTextColor
            }
        }
    }

    // ── Intro-Animation ──────────────────────────────────────────────────
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Component.onCompleted: {
        focusRoot.opacity = 1
        focusRoot._fetchNow()
    }
}
