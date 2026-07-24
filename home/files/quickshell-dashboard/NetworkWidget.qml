import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: net
    anchors.fill: parent

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"

    property bool ready: false
    property string ifaceName: ""
    property string ifaceType: ""
    property string connectionName: ""
    property bool vpnActive: false
    property real rxBytesPerSec: 0
    property real txBytesPerSec: 0

    property var _prevSamples: ({})

    readonly property string _pollScript: "
        timeout 5 cat /proc/net/dev
        echo '###SPLIT###'
        timeout 5 nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null
        echo '###SPLIT###'
        timeout 5 nmcli -t -f NAME,TYPE connection show --active 2>/dev/null
    "

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / 1024 / 1024).toFixed(1) + " MB/s"
        return (bytesPerSec / 1024 / 1024 / 1024).toFixed(2) + " GB/s"
    }

    function _parseNetDev(text) {
        var result = {}
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var m = lines[i].match(/^\s*([a-zA-Z0-9@_.-]+):\s*(.+)$/)
            if (!m) continue
            var nums = m[2].trim().split(/\s+/).map(Number)
            if (nums.length < 9) continue
            result[m[1]] = { rx: nums[0], tx: nums[8] }
        }
        return result
    }

    function _handleOutput(text) {
        var blocks = text.split("###SPLIT###")
        if (blocks.length < 3) return

        var samples = net._parseNetDev(blocks[0])
        var now = Date.now()
        var best = null
        var bestDelta = -1

        for (var iface in samples) {
            if (iface === "lo") continue
            var prev = net._prevSamples[iface]
            var cur = samples[iface]
            if (prev) {
                var dt = (now - prev.ts) / 1000
                if (dt <= 0) continue
                var rxRate = Math.max(0, (cur.rx - prev.rx) / dt)
                var txRate = Math.max(0, (cur.tx - prev.tx) / dt)
                var total = rxRate + txRate
                if (total > bestDelta) {
                    bestDelta = total
                    best = { iface: iface, rx: rxRate, tx: txRate }
                }
            }
            samples[iface].ts = now
        }
        net._prevSamples = samples

        if (best) {
            net.ifaceName = best.iface
            net.rxBytesPerSec = best.rx
            net.txBytesPerSec = best.tx
        }

        var deviceLines = blocks[1].trim().split("\n")
        net.ifaceType = ""
        net.connectionName = ""
        for (var d = 0; d < deviceLines.length; d++) {
            var parts = deviceLines[d].split(":")
            if (parts.length < 4) continue
            if (parts[0] === net.ifaceName) {
                net.ifaceType = parts[1]
                net.connectionName = parts.slice(3).join(":")
                break
            }
        }

        var activeLines = blocks[2].trim().split("\n")
        var vpn = false
        for (var a = 0; a < activeLines.length; a++) {
            if (/vpn|wireguard|tun/i.test(activeLines[a])) { vpn = true; break }
        }
        net.vpnActive = vpn
        net.ready = true
    }

    Process {
        id: poller
        command: ["bash", "-c", net._pollScript]
        stdout: StdioCollector {
            onStreamFinished: net._handleOutput(this.text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poller.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            visible: !net.ready
            text: "Lädt…"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: net.textColor
        }

        Text {
            visible: net.ready && net.ifaceName === ""
            text: "Keine aktive Verbindung"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: net.textColor
        }

        ColumnLayout {
            visible: net.ready && net.ifaceName !== ""
            spacing: 10

            RowLayout {
                spacing: 8
                Text {
                    text: net.ifaceType === "wifi" ? "📶" : "🔌"
                    font.pixelSize: 16
                }
                Text {
                    text: (net.connectionName || net.ifaceName) + " · " + net.ifaceName
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    opacity: 0.75
                    color: net.textColor
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: net.vpnActive
                    text: "VPN"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.bold: true
                    color: net.accentColor
                }
            }

            RowLayout {
                spacing: 24

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "↓ " + net.formatSpeed(net.rxBytesPerSec)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                        font.bold: true
                        color: net.textColor
                    }
                    Text {
                        text: "Download"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        opacity: 0.5
                        color: net.textColor
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "↑ " + net.formatSpeed(net.txBytesPerSec)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                        font.bold: true
                        color: net.textColor
                    }
                    Text {
                        text: "Upload"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        opacity: 0.5
                        color: net.textColor
                    }
                }
            }
        }
    }
}
