import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: tab

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    property bool configured: false
    property string baseUrl: ""
    property string apiKey: ""
    property string userId: ""

    property bool checked: false
    property bool hasSession: false
    property string sessionId: ""
    property string itemId: ""
    property string itemName: ""
    property bool isPaused: false
    property real positionSec: 0
    property real durationSec: 0

    function formatTime(sec) {
        if (!sec || sec < 0) sec = 0
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function _origin() {
        return tab.baseUrl.replace(/\/+$/, "")
    }

    function fetchSession() {
        if (!tab.configured) return
        var xhr = new XMLHttpRequest()
        xhr.timeout = 5000
        xhr.ontimeout = function () { tab.checked = true }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            tab.checked = true
            if (xhr.status < 200 || xhr.status >= 300) { tab.hasSession = false; return }
            try {
                var sessions = JSON.parse(xhr.responseText)
                var match = null
                for (var i = 0; i < sessions.length; i++) {
                    var s = sessions[i]
                    if (s.UserId === tab.userId && s.NowPlayingItem) { match = s; break }
                }
                if (!match) { tab.hasSession = false; return }
                tab.hasSession = true
                tab.sessionId = match.Id
                tab.itemId = match.NowPlayingItem.Id
                tab.itemName = match.NowPlayingItem.Name || "(ohne Titel)"
                tab.isPaused = !!(match.PlayState && match.PlayState.IsPaused)
                var posTicks = (match.PlayState && match.PlayState.PositionTicks) || 0
                var durTicks = match.NowPlayingItem.RunTimeTicks || 0
                tab.positionSec = posTicks / 10000000
                tab.durationSec = durTicks / 10000000
            } catch (e) {
                console.log("Jellyfin-Tab: Parse-Fehler", e)
                tab.hasSession = false
            }
        }
        xhr.open("GET", tab._origin() + "/Sessions?api_key=" + tab.apiKey)
        xhr.send()
    }

    function sendCommand(cmd) {
        if (!tab.sessionId) return
        var xhr = new XMLHttpRequest()
        xhr.timeout = 5000
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            tab.fetchSession()
        }
        xhr.open("POST", tab._origin() + "/Sessions/" + tab.sessionId + "/Playing/" + cmd + "?api_key=" + tab.apiKey)
        xhr.send()
    }

    function openInMpv() {
        if (!tab.itemId) return
        var url = tab._origin() + "/Videos/" + tab.itemId + "/stream?api_key=" + tab.apiKey + "&static=true"
        mpvLauncher.exec(["bash", "-c",
            "mpv --no-border --ontop --geometry=640x360+1270+10 --input-ipc-server=/tmp/mpvsocket " + JSON.stringify(url)])
    }

    Process { id: mpvLauncher }

    CredentialsLoader {
        id: creds
        onCredentialsLoaded: {
            tab.baseUrl = creds.jellyfinUrl
            tab.apiKey = creds.jellyfinApiKey
            tab.userId = creds.jellyfinUserId
            tab.configured = tab.baseUrl.length > 0 && tab.apiKey.length > 0 && tab.userId.length > 0
            if (tab.configured) tab.fetchSession()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: if (tab.configured) tab.fetchSession()
    }

    Text {
        anchors.centerIn: parent
        visible: !tab.configured
        text: "Jellyfin nicht konfiguriert"
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        opacity: 0.5
        color: tab.textColor
    }

    Text {
        anchors.centerIn: parent
        visible: tab.configured && tab.checked && !tab.hasSession
        text: "Keine aktive Wiedergabe"
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        opacity: 0.4
        color: tab.textColor
    }

    ColumnLayout {
        anchors.fill: parent
        visible: tab.configured && tab.hasSession
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: tab.itemName
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                color: tab.textColor
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.15)

                Rectangle {
                    width: parent.width * (tab.durationSec > 0 ? Math.min(1, tab.positionSec / tab.durationSec) : 0)
                    height: parent.height
                    radius: 2
                    color: tab.accentColor
                }
            }

            Text {
                Layout.alignment: Qt.AlignRight
                text: tab.formatTime(tab.positionSec) + " / " + tab.formatTime(tab.durationSec)
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                opacity: 0.5
                color: tab.textColor
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            Text {
                text: "⏮"; font.pixelSize: 18; color: tab.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.sendCommand("PreviousTrack") }
            }
            Text {
                text: tab.isPaused ? "▶" : "⏸"; font.pixelSize: 18; color: tab.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.sendCommand(tab.isPaused ? "Unpause" : "Pause") }
            }
            Text {
                text: "⏭"; font.pixelSize: 18; color: tab.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.sendCommand("NextTrack") }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            radius: 8
            color: Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, mpvMouse.containsMouse ? 0.9 : 0.75)
            Layout.preferredWidth: mpvLabel.implicitWidth + 20
            Layout.preferredHeight: 26

            Text {
                id: mpvLabel
                anchors.centerIn: parent
                text: "In MPV öffnen"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.bold: true
                color: tab.accentTextColor
            }

            MouseArea {
                id: mpvMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tab.openInMpv()
            }
        }

        Item { Layout.fillHeight: true }
    }
}
