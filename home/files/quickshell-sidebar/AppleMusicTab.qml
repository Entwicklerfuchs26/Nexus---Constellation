import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: tab

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    property bool ready: false
    property bool isAppleMusic: false
    property string playerName: ""
    property string status: ""
    property string title: ""
    property string artist: ""
    property string coverUrl: ""
    property real positionSec: 0
    property real lengthSec: 0
    property bool shuffleOn: false
    property real volume: 1.0

    readonly property string _delim: "###F###"

    function formatTime(sec) {
        if (!sec || sec < 0) sec = 0
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    readonly property string _pollScript: "
        players=$(timeout 5 playerctl -l 2>/dev/null)
        target=\"\"
        for p in $players; do
            case \"$p\" in
                *[Cc]ider*|*[Aa]pple*[Mm]usic*|*AppleMusic*) target=\"$p\"; break ;;
            esac
        done
        if [ -z \"$target\" ]; then target=$(echo \"$players\" | head -1); fi
        if [ -z \"$target\" ]; then
            echo 'NONE'
        else
            echo \"PLAYER:$target\"
            timeout 5 playerctl -p \"$target\" metadata --format '{{status}}###F###{{title}}###F###{{artist}}###F###{{mpris:artUrl}}###F###{{position}}###F###{{mpris:length}}' 2>/dev/null
            echo '###SHUFFLE###'
            timeout 5 playerctl -p \"$target\" shuffle 2>/dev/null
            echo '###VOL###'
            timeout 5 playerctl -p \"$target\" volume 2>/dev/null
        fi
    "

    function _handleOutput(text) {
        tab.ready = true
        var trimmed = text.trim()
        if (trimmed.indexOf("NONE") === 0) {
            tab.playerName = ""
            return
        }

        var lines = trimmed.split("\n")
        var playerLine = lines[0] || ""
        tab.playerName = playerLine.indexOf("PLAYER:") === 0 ? playerLine.substring(7) : ""
        tab.isAppleMusic = /cider|apple\s*music/i.test(tab.playerName)

        var rest = lines.slice(1).join("\n")
        var parts = rest.split("###SHUFFLE###")
        var metaLine = (parts[0] || "").trim()
        var afterShuffle = (parts[1] || "").split("###VOL###")
        var shuffleText = (afterShuffle[0] || "").trim()
        var volText = (afterShuffle[1] || "").trim()

        var fields = metaLine.split(tab._delim)
        tab.status = fields[0] || ""
        tab.title = fields[1] || ""
        tab.artist = fields[2] || ""
        tab.coverUrl = fields[3] || ""
        tab.positionSec = (parseInt(fields[4]) || 0) / 1000000
        tab.lengthSec = (parseInt(fields[5]) || 0) / 1000000
        tab.shuffleOn = shuffleText === "On"
        var vol = parseFloat(volText)
        tab.volume = isNaN(vol) ? 1.0 : vol
    }

    Process {
        id: poller
        command: ["bash", "-c", tab._pollScript]
        stdout: StdioCollector {
            onStreamFinished: tab._handleOutput(this.text)
        }
    }

    Process { id: ctlProc }
    Process { id: launcher }

    function control(action) {
        if (!tab.playerName) return
        ctlProc.exec(["bash", "-c", "timeout 5 playerctl -p " + tab.playerName + " " + action])
    }

    function toggleShuffle() {
        if (!tab.playerName) return
        ctlProc.exec(["bash", "-c", "timeout 5 playerctl -p " + tab.playerName + " shuffle toggle"])
    }

    function setVolume(v) {
        if (!tab.playerName) return
        tab.volume = v
        ctlProc.exec(["bash", "-c", "timeout 5 playerctl -p " + tab.playerName + " volume " + v.toFixed(2)])
    }

    function startCider() {
        // Cider ist in nixpkgs "broken" - läuft stattdessen als Flatpak (sh.cider.Cider,
        // installiert 2026-07-24). Meldet sich als MPRIS-Player "cider" an, per
        // playerctl -l bestätigt.
        launcher.exec(["hyprctl", "dispatch", "exec", "flatpak run sh.cider.Cider"])
    }

    Component.onCompleted: poller.running = true
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: poller.running = true
    }

    Text {
        anchors.centerIn: parent
        visible: !tab.ready
        text: "Lädt…"
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        opacity: 0.35
        color: tab.textColor
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: tab.ready && tab.playerName === ""
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Apple Music nicht geöffnet"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.6
            color: tab.textColor
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            radius: 8
            color: Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, startMouse.containsMouse ? 0.9 : 0.75)
            Layout.preferredWidth: startLabel.implicitWidth + 20
            Layout.preferredHeight: 28

            Text {
                id: startLabel
                anchors.centerIn: parent
                text: "Cider starten"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.bold: true
                color: tab.accentTextColor
            }

            MouseArea {
                id: startMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tab.startCider()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: tab.ready && tab.playerName !== ""
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 80
                height: 80
                radius: 8
                color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.08)
                clip: true

                Image {
                    anchors.fill: parent
                    source: tab.coverUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: tab.coverUrl.length > 0
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: tab.title || "(unbekannt)"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    color: tab.textColor
                }
                Text {
                    Layout.fillWidth: true
                    text: tab.artist || "—"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    opacity: 0.65
                    elide: Text.ElideRight
                    color: tab.textColor
                }
                Text {
                    visible: !tab.isAppleMusic
                    text: tab.playerName
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    opacity: 0.4
                    color: tab.textColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.15)

                    Rectangle {
                        width: parent.width * (tab.lengthSec > 0 ? Math.min(1, tab.positionSec / tab.lengthSec) : 0)
                        height: parent.height
                        radius: 2
                        color: tab.accentColor
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignRight
                    text: tab.formatTime(tab.positionSec) + " / " + tab.formatTime(tab.lengthSec)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    opacity: 0.5
                    color: tab.textColor
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            Text {
                text: "⏮"; font.pixelSize: 18; color: tab.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.control("previous") }
            }
            Text {
                text: tab.status === "Playing" ? "⏸" : "▶"; font.pixelSize: 18; color: tab.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.control("play-pause") }
            }
            Text {
                text: "⏭"; font.pixelSize: 18; color: tab.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.control("next") }
            }
            Text {
                text: "🔀"; font.pixelSize: 14; opacity: tab.shuffleOn ? 1 : 0.4
                color: tab.shuffleOn ? tab.accentColor : tab.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.toggleShuffle() }
            }

            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 4
                radius: 2
                color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.15)

                Rectangle {
                    width: parent.width * Math.min(1, tab.volume)
                    height: parent.height
                    radius: 2
                    color: tab.textColor
                    opacity: 0.6
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: function (mouse) { tab.setVolume(Math.max(0, Math.min(1, mouse.x / width))) }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
