import Quickshell.Io
import QtQuick

Item {
    id: loader

    property string caldavUrl: ""
    property string caldavUser: ""
    property string caldavPassword: ""
    property var caldavCalendars: []
    property string vikunjaUrl: ""
    property string vikunjaApiToken: ""
    property var newsTabs: []
    property string skillTreeUrl: ""
    property string skillTreeLocalCmd: ""
    property bool loaded: false

    signal credentialsLoaded()

    function _parse(text) {
        var map = {}
        var lines = (text || "").split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0 || line.charAt(0) === "#") continue
            var eq = line.indexOf("=")
            if (eq === -1) continue
            map[line.substring(0, eq).trim()] = line.substring(eq + 1).trim()
        }
        loader.caldavUrl = map.CALDAV_URL || ""
        loader.caldavUser = map.CALDAV_USER || ""
        loader.caldavPassword = map.CALDAV_PASSWORD || ""
        loader.caldavCalendars = (map.CALDAV_CALENDARS || "").split(",")
            .map(function (s) { return s.trim() })
            .filter(function (s) { return s.length > 0 })
        loader.vikunjaUrl = map.VIKUNJA_URL || ""
        loader.vikunjaApiToken = map.VIKUNJA_API_TOKEN || ""
        var tabs = []
        for (var n = 1; n <= 20; n++) {
            var tabName = map["NEWS_TAB_" + n + "_NAME"]
            if (!tabName) continue
            tabs.push({ name: tabName, url: map["NEWS_TAB_" + n + "_URL"] || "" })
        }
        loader.newsTabs = tabs
        loader.skillTreeUrl = map.SKILLTREE_URL || ""
        loader.skillTreeLocalCmd = map.SKILLTREE_LOCAL_CMD || ""
        loader.loaded = true
        loader.credentialsLoaded()
    }

    // Bewusst per Process/bash statt FileView gelesen (siehe Auftrag) - liest den
    // aktuellen Dateiinhalt einmal beim Start. Sobald credentials.env später durch
    // agenix ersetzt wird, ändert sich an diesem Ladeweg nichts.
    Process {
        id: reader
        command: ["bash", "-c", "cat \"$HOME/.config/nexus/credentials.env\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: loader._parse(this.text)
        }
    }

    Component.onCompleted: reader.running = true

    function isPlaceholder(value, token) {
        return !value || value.indexOf(token) !== -1
    }
}
