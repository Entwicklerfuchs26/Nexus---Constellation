import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: player
    anchors.fill: parent

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"

    property bool active: false
    property string status: ""
    property string title: ""
    property string artist: ""
    property string coverUrl: ""

    readonly property string _delim: "###F###"

    function _handleOutput(text) {
        var trimmed = text.trim()
        if (!trimmed) {
            player.active = false
            return
        }
        var parts = trimmed.split(player._delim)
        if (parts.length < 4) {
            player.active = false
            return
        }
        player.status = parts[0]
        player.title = parts[1]
        player.artist = parts[2]
        player.coverUrl = parts[3]
        player.active = true
    }

    Process {
        id: poller
        command: ["bash", "-c", "timeout 5 playerctl metadata --format '{{status}}" + player._delim + "{{title}}" + player._delim + "{{artist}}" + player._delim + "{{mpris:artUrl}}' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: player._handleOutput(this.text)
        }
    }

    Process { id: ctlProc }

    function control(action) {
        ctlProc.exec(["bash", "-c", "timeout 5 playerctl " + action])
    }

    Component.onCompleted: poller.running = true
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: poller.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            visible: !player.active
            text: "Kein Media Player aktiv"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: player.textColor
        }

        RowLayout {
            visible: player.active
            Layout.fillWidth: true
            spacing: 14

            Item {
                id: coverMask
                width: 56
                height: 56
                visible: player.coverUrl.length > 0

                Image {
                    id: coverImg
                    anchors.fill: parent
                    source: player.coverUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                Rectangle {
                    id: maskShape
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: coverImg
                    maskEnabled: true
                    maskSource: maskShape
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: player.title || "(ohne Titel)"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    color: player.textColor
                }
                Text {
                    Layout.fillWidth: true
                    text: player.artist || "—"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    opacity: 0.6
                    elide: Text.ElideRight
                    color: player.textColor
                }

                RowLayout {
                    spacing: 14
                    Layout.topMargin: 4

                    Text {
                        text: "⏮"
                        font.pixelSize: 16
                        color: player.textColor
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: player.control("previous") }
                    }
                    Text {
                        text: player.status === "Playing" ? "⏸" : "▶"
                        font.pixelSize: 16
                        color: player.textColor
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: player.control("play-pause") }
                    }
                    Text {
                        text: "⏭"
                        font.pixelSize: 16
                        color: player.textColor
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: player.control("next") }
                    }
                }
            }
        }
    }
}
