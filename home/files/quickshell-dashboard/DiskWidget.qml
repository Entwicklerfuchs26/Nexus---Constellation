import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: disk
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color warnColor: "#a9a9ff"
    property color dangerColor: "#ba1a1a"

    property bool ready: false
    property var partitions: []

    readonly property string _pollScript: "
        timeout 5 df -h --output=target,used,size,pcent \
            -x tmpfs -x devtmpfs -x proc -x sysfs -x cgroup2 -x overlay -x squashfs -x efivarfs -x fuse.portal 2>/dev/null
    "

    function _relevant(target) {
        return target === "/" || target === "/home"
            || target.indexOf("/run/media/") === 0
            || target.indexOf("/mnt/") === 0
            || target.indexOf("/media/") === 0
    }

    function _handleOutput(text) {
        var lines = text.trim().split("\n")
        var result = []
        for (var i = 1; i < lines.length; i++) {
            var parts = lines[i].trim().split(/\s+/)
            if (parts.length < 4) continue
            var target = parts[0]
            if (!disk._relevant(target)) continue
            var pct = parseInt(parts[3].replace("%", ""))
            result.push({
                target: target,
                used: parts[1],
                size: parts[2],
                pct: isNaN(pct) ? 0 : pct
            })
        }
        disk.partitions = result
        disk.ready = true
    }

    Process {
        id: poller
        command: ["bash", "-c", disk._pollScript]
        stdout: StdioCollector {
            onStreamFinished: disk._handleOutput(this.text)
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poller.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            visible: !disk.ready
            text: "Lädt…"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: disk.textColor
        }

        Text {
            visible: disk.ready && disk.partitions.length === 0
            text: "Keine Partitionen gefunden"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: disk.textColor
        }

        Repeater {
            model: disk.partitions

            ColumnLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.target
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                        color: disk.textColor
                    }
                    Text {
                        text: row.modelData.used + " / " + row.modelData.size + " (" + row.modelData.pct + "%)"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        opacity: 0.6
                        color: disk.textColor
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Qt.rgba(disk.textColor.r, disk.textColor.g, disk.textColor.b, 0.12)

                    Rectangle {
                        width: parent.width * Math.min(1, row.modelData.pct / 100)
                        height: parent.height
                        radius: 3
                        color: row.modelData.pct >= 95 ? disk.dangerColor
                            : row.modelData.pct >= 80 ? disk.warnColor
                            : disk.accentColor
                    }
                }
            }
        }
    }
}
