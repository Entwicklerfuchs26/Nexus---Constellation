import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: mpv
    visible: mpv.running
    Layout.fillWidth: true
    Layout.preferredHeight: mpv.running ? 32 : 0

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"

    property bool running: false
    property bool paused: false

    readonly property string socketPath: "/tmp/mpvsocket"

    function _sendAndPoll(cmd) {
        var script = "test -S " + mpv.socketPath
            + " && echo '" + cmd + "' | timeout 3 socat - " + mpv.socketPath + " 2>/dev/null || echo ''"
        ipcProc.command = ["bash", "-c", script]
        ipcProc.running = true
    }

    function poll() {
        mpv._sendAndPoll('{"command":["get_property","pause"]}')
    }

    function togglePause() {
        mpv._sendAndPoll('{"command":["set_property","pause",' + (!mpv.paused) + ']}')
    }

    function stop() {
        mpv._sendAndPoll('{"command":["quit"]}')
    }

    function fullscreen() {
        mpv._sendAndPoll('{"command":["set_property","fullscreen",true]}')
    }

    Process {
        id: ipcProc
        stdout: StdioCollector {
            onStreamFinished: {
                var trimmed = this.text.trim()
                if (!trimmed) {
                    mpv.running = false
                    return
                }
                mpv.running = true
                try {
                    var d = JSON.parse(trimmed.split("\n")[0])
                    if (typeof d.data === "boolean") mpv.paused = d.data
                } catch (e) {
                    // Antwort auf set_property hat kein "data" - Status bleibt wie zuletzt bekannt.
                }
            }
        }
    }

    Component.onCompleted: mpv.poll()
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: mpv.poll()
    }

    Rectangle {
        anchors.fill: parent
        visible: mpv.running
        radius: 8
        color: Qt.rgba(mpv.textColor.r, mpv.textColor.g, mpv.textColor.b, 0.06)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 14

            Text {
                text: "▶ MPV"
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                opacity: 0.5
                color: mpv.textColor
            }

            Item { Layout.fillWidth: true }

            Text {
                text: mpv.paused ? "▶" : "⏸"
                font.pixelSize: 14
                color: mpv.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mpv.togglePause() }
            }
            Text {
                text: "⛶"
                font.pixelSize: 14
                color: mpv.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mpv.fullscreen() }
            }
            Text {
                text: "⏹"
                font.pixelSize: 14
                color: mpv.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mpv.stop() }
            }
        }
    }
}
