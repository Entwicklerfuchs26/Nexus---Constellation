import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: player

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    Layout.fillWidth: true
    Layout.preferredHeight: player.active ? 182 : 0
    visible: player.active

    property bool active: false
    property string status: ""
    property string title: ""
    property string artist: ""
    property string coverUrl: ""
    property real positionSec: 0
    property real lengthSec: 0
    property string playerName: ""
    property string outputDevice: ""

    readonly property string _delim: "###F###"

    // Waehlt den ersten Player mit tatsaechlich geladenem Titel (playerctl
    // pickt ohne -p sonst manchmal einen leeren/falschen Player, z.B.
    // "skwd-music" ohne Track statt der aktiven Vivaldi-Wiedergabe).
    readonly property string _pickPlayer: "p=''; for c in $(timeout 3 playerctl -l 2>/dev/null); do "
        + "t=$(timeout 2 playerctl -p \"$c\" metadata title 2>/dev/null); "
        + "if [ -n \"$t\" ]; then p=\"$c\"; break; fi; done; "
        + "[ -z \"$p\" ] && p=$(timeout 3 playerctl -l 2>/dev/null | head -1); "

    function control(action) {
        ctlProc.exec(["bash", "-c", player._pickPlayer + "timeout 5 playerctl -p \"$p\" " + action])
    }

    function seekTo(fraction) {
        console.log("[nexus-seek] seekTo called, fraction=" + fraction + " lengthSec=" + player.lengthSec)
        if (player.lengthSec <= 0) return
        var target = Math.max(0, Math.min(1, fraction)) * player.lengthSec
        console.log("[nexus-seek] target=" + target.toFixed(1))
        ctlProc.exec(["bash", "-c", player._pickPlayer + "timeout 5 playerctl -p \"$p\" position " + target.toFixed(1)])
    }

    function _fmtTime(sec) {
        var s = Math.max(0, Math.round(sec))
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    function _handleOutput(text) {
        var trimmed = text.trim()
        if (!trimmed) {
            player.active = false
            return
        }
        var parts = trimmed.split(player._delim)
        if (parts.length < 7) {
            player.active = false
            return
        }
        player.status = parts[0]
        player.title = parts[1]
        player.artist = parts[2]
        player.coverUrl = parts[3]
        player.positionSec = (parseFloat(parts[4]) || 0) / 1000000
        player.lengthSec = (parseFloat(parts[5]) || 0) / 1000000
        player.playerName = parts[6]
        player.active = true
    }

    Process {
        id: poller
        command: ["bash", "-c",
            player._pickPlayer + "[ -z \"$p\" ] && exit 0; "
            + "timeout 5 playerctl -p \"$p\" metadata --format '{{status}}" + player._delim + "{{title}}" + player._delim
            + "{{artist}}" + player._delim + "{{mpris:artUrl}}" + player._delim
            + "{{position}}" + player._delim + "{{mpris:length}}" + player._delim
            + "{{playerName}}' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: player._handleOutput(this.text)
        }
    }
    Process { id: ctlProc }

    Process {
        id: devicePoller
        command: ["bash", "-c",
            "timeout 5 pactl list sinks 2>/dev/null | awk -v s=\"$(timeout 5 pactl get-default-sink)\" "
            + "'/^Sink #/{name=\"\"} /^\\tName: /{name=$2} name==s && /^\\t(Description|Beschreibung): /"
            + "{ sub(/^\\t[^:]+: /,\"\"); print; exit }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text.trim()
                if (t) player.outputDevice = t
            }
        }
    }

    Component.onCompleted: { poller.running = true; devicePoller.running = true }
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: poller.running = true
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: devicePoller.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6
        visible: player.active

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                id: coverMask
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64

                // Leucht-Ring hinter dem Cover, an die Referenz angelehnt
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: width / 2
                    color: "transparent"
                    border.width: 8
                    border.color: Qt.rgba(player.accentColor.r, player.accentColor.g, player.accentColor.b, 0.35)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 0.6
                        blurMax: 24
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: player.accentColor
                }

                Image {
                    id: coverImg
                    anchors.fill: parent
                    anchors.margins: 3
                    source: player.coverUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                Rectangle {
                    id: maskShape
                    anchors.fill: coverImg
                    radius: width / 2
                    visible: false
                }
                MultiEffect {
                    anchors.fill: coverImg
                    source: coverImg
                    maskEnabled: true
                    maskSource: maskShape
                    visible: coverImg.status === Image.Ready
                }
                Rectangle {
                    anchors.fill: coverImg
                    radius: width / 2
                    visible: coverImg.status !== Image.Ready
                    color: Qt.rgba(player.accentColor.r, player.accentColor.g, player.accentColor.b, 0.18)
                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pixelSize: 22
                        color: player.accentColor
                    }
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
                    text: player.artist ? ("VON " + player.artist.toUpperCase()) : "—"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    opacity: 0.6
                    elide: Text.ElideRight
                    color: player.textColor
                }

                RowLayout {
                    Layout.topMargin: 2
                    spacing: 4

                    Rectangle {
                        visible: player.outputDevice.length > 0
                        radius: 7
                        color: Qt.rgba(player.textColor.r, player.textColor.g, player.textColor.b, 0.08)
                        Layout.preferredWidth: deviceLabel.implicitWidth + 12
                        Layout.preferredHeight: 15
                        Text {
                            id: deviceLabel
                            anchors.centerIn: parent
                            text: "󰂯 " + player.outputDevice
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                            opacity: 0.7
                            color: player.textColor
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        visible: player.playerName.length > 0
                        radius: 7
                        color: Qt.rgba(player.textColor.r, player.textColor.g, player.textColor.b, 0.08)
                        Layout.preferredWidth: sourceLabel.implicitWidth + 12
                        Layout.preferredHeight: 15
                        Text {
                            id: sourceLabel
                            anchors.centerIn: parent
                            text: "VIA " + player.playerName
                            font.family: "JetBrains Mono"
                            font.pixelSize: 8
                            opacity: 0.7
                            color: player.textColor
                        }
                    }
                }
            }
        }

        Item {
            id: seekTrack
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            Layout.topMargin: 4

            readonly property real _fraction: player.lengthSec > 0 ? Math.min(1, player.positionSec / player.lengthSec) : 0

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: Qt.rgba(player.textColor.r, player.textColor.g, player.textColor.b, 0.18)

                Rectangle {
                    width: parent.width * seekTrack._fraction
                    height: parent.height
                    radius: 3
                    color: player.accentColor
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: player.accentColor
                border.width: 2
                border.color: player.accentTextColor
                anchors.verticalCenter: parent.verticalCenter
                x: seekTrack._fraction * (seekTrack.width - width)
                Behavior on x { NumberAnimation { duration: 300 } }
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -4
                anchors.bottomMargin: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    console.log("[nexus-seek] click mouse.x=" + mouse.x + " width=" + seekTrack.width)
                    player.seekTo(mouse.x / seekTrack.width)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: player._fmtTime(player.positionSec)
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                opacity: 0.5
                color: player.textColor
            }
            Item { Layout.fillWidth: true }
            Text {
                text: player._fmtTime(player.lengthSec)
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                opacity: 0.5
                color: player.textColor
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            spacing: 18

            Text {
                text: "⏮"
                font.pixelSize: 16
                color: player.textColor
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: player.control("previous") }
            }

            Rectangle {
                radius: 16
                color: player.accentColor
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Text {
                    anchors.centerIn: parent
                    text: player.status === "Playing" ? "⏸" : "▶"
                    font.pixelSize: 14
                    color: player.accentTextColor
                }
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
