import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: sysUsage
    anchors.fill: parent

    property color textColor: "#ffffff"
    property color subTextColor: "#aaaaaa"
    property color accentColor: "#c6b22b"
    property color baseColor: "#15130b"
    property color contrastTextColor: "#000000"
    property bool active: true
    property real tileOpacity: 0.55

    function _hueShift(base, hue) {
        return Qt.hsva(hue, Math.max(0.35, base.hsvSaturation), Math.max(0.55, base.hsvValue), 1.0)
    }
    readonly property color netRxColor: sysUsage._hueShift(sysUsage.accentColor, 0.36)
    readonly property color netTxColor: sysUsage._hueShift(sysUsage.accentColor, 0.07)

    function formatBytes(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        if (bytesPerSec < 1024 * 1024 * 1024) return (bytesPerSec / 1024 / 1024).toFixed(1) + " MB/s"
        return (bytesPerSec / 1024 / 1024 / 1024).toFixed(2) + " GB/s"
    }

    // ── globale Wellenphase, von allen Kacheln geteilt ──────────────────────
    property real wavePhase: 0
    NumberAnimation on wavePhase {
        from: 0; to: Math.PI * 2
        duration: 1800
        loops: Animation.Infinite
        running: sysUsage.active
    }

    // ── SysData: CPU/RAM/GPU/NET via nexus-sys-fetcher (eigenes Skript) ────
    property real cpuPercent: 0
    property real ramPercent: 0
    property real ramUsedGb: 0
    property real gpuPercent: 0
    property real vramUsedGb: 0
    property real vramTotalGb: 0
    property real rxBytesPerSec: 0
    property real txBytesPerSec: 0
    property real linkDownMbps: 0
    property real linkUpMbps: 0
    property real cpuTempC: 0
    property real gpuTempC: 0

    function formatLinkSpeed(mbps) {
        if (mbps <= 0) return ""
        if (mbps >= 1000) return (mbps / 1000).toFixed(mbps % 1000 === 0 ? 0 : 1) + " Gbit/s"
        return mbps.toFixed(0) + " Mbit/s"
    }

    function formatTemp(c) {
        return c > 0 ? Math.round(c) + "°" : "n/a"
    }

    function _handleSysOutput(text) {
        var line = (text || "").trim().split("\n").pop()
        if (!line) return
        var parts = line.split("|")
        if (parts.length < 12) return
        sysUsage.cpuPercent = parseFloat(parts[0]) || 0
        sysUsage.ramPercent = parseFloat(parts[1]) || 0
        sysUsage.ramUsedGb = parseFloat(parts[2]) || 0
        sysUsage.gpuPercent = parseFloat(parts[3]) || 0
        sysUsage.vramUsedGb = parseFloat(parts[4]) || 0
        sysUsage.vramTotalGb = parseFloat(parts[5]) || 0
        sysUsage.rxBytesPerSec = Math.max(0, parseFloat(parts[6]) || 0)
        sysUsage.txBytesPerSec = Math.max(0, parseFloat(parts[7]) || 0)
        sysUsage.linkDownMbps = parseFloat(parts[8]) || 0
        sysUsage.linkUpMbps = parseFloat(parts[9]) || 0
        sysUsage.cpuTempC = parseFloat(parts[10]) || 0
        sysUsage.gpuTempC = parseFloat(parts[11]) || 0
    }

    Process {
        id: sysPoller
        command: ["nexus-sys-fetcher"]
        stdout: StdioCollector {
            onStreamFinished: sysUsage._handleSysOutput(this.text)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!sysPoller.running) sysPoller.running = true
    }

    // ── DISK separat, alle 60s (df -h ~) ────────────────────────────────────
    property real diskPercent: 0
    property string diskUsed: ""
    property string diskTotal: ""

    function _handleDiskOutput(text) {
        var lines = text.trim().split("\n")
        if (lines.length < 2) return
        var parts = lines[1].trim().split(/\s+/)
        if (parts.length < 4) return
        sysUsage.diskUsed = parts[1]
        sysUsage.diskTotal = parts[2]
        var pct = parseInt(parts[3].replace("%", ""))
        sysUsage.diskPercent = isNaN(pct) ? 0 : pct
    }

    Process {
        id: diskPoller
        command: ["bash", "-c", "timeout 5 df -h ~ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: sysUsage._handleDiskOutput(this.text)
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskPoller.running = true
    }

    GridLayout {
        anchors.fill: parent
        columns: 3
        rowSpacing: 14
        columnSpacing: 14

        LiquidSquare {
            Layout.row: 0; Layout.column: 0
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: ""
            titleText: "CPU"
            value: sysUsage.cpuPercent / 100
            valueText: Math.round(sysUsage.cpuPercent) + "%"
            fillColor: Qt.lighter(sysUsage.accentColor, 1.4)
            baseColor: sysUsage.baseColor
            textColor: sysUsage.textColor
            subTextColor: sysUsage.subTextColor
            contrastTextColor: sysUsage.contrastTextColor
            tileOpacity: sysUsage.tileOpacity
            wavePhase: sysUsage.wavePhase
            active: sysUsage.active
        }

        LiquidSquare {
            Layout.row: 0; Layout.column: 1
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: ""
            titleText: "RAM"
            value: sysUsage.ramPercent / 100
            valueText: sysUsage.ramUsedGb.toFixed(1) + "G"
            fillColor: Qt.lighter(sysUsage.accentColor, 1.2)
            baseColor: sysUsage.baseColor
            textColor: sysUsage.textColor
            subTextColor: sysUsage.subTextColor
            contrastTextColor: sysUsage.contrastTextColor
            tileOpacity: sysUsage.tileOpacity
            wavePhase: sysUsage.wavePhase
            active: sysUsage.active
        }

        LiquidSquare {
            Layout.row: 0; Layout.column: 2
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: ""
            titleText: "GPU"
            value: sysUsage.gpuPercent / 100
            valueText: Math.round(sysUsage.gpuPercent) + "%"
            subText: sysUsage.vramUsedGb.toFixed(1) + "G / " + sysUsage.vramTotalGb.toFixed(1) + "G"
            fillColor: sysUsage.accentColor
            baseColor: sysUsage.baseColor
            textColor: sysUsage.textColor
            subTextColor: sysUsage.subTextColor
            contrastTextColor: sysUsage.contrastTextColor
            tileOpacity: sysUsage.tileOpacity
            wavePhase: sysUsage.wavePhase
            active: sysUsage.active
        }

        LiquidSquare {
            Layout.row: 1; Layout.column: 0
            Layout.fillWidth: true; Layout.fillHeight: true
            icon: ""
            titleText: "DISK"
            value: sysUsage.diskPercent / 100
            valueText: Math.round(sysUsage.diskPercent) + "%"
            subText: sysUsage.diskUsed + " / " + sysUsage.diskTotal
            fillColor: Qt.darker(sysUsage.accentColor, 1.2)
            baseColor: sysUsage.baseColor
            textColor: sysUsage.textColor
            subTextColor: sysUsage.subTextColor
            contrastTextColor: sysUsage.contrastTextColor
            tileOpacity: sysUsage.tileOpacity
            wavePhase: sysUsage.wavePhase
            active: sysUsage.active
        }

        LiquidSquare {
            id: netTile
            Layout.row: 1; Layout.column: 1
            Layout.fillWidth: true; Layout.fillHeight: true
            useLiquid: false
            icon: ""
            titleText: "NET"
            baseColor: sysUsage.baseColor
            textColor: sysUsage.textColor
            subTextColor: sysUsage.subTextColor
            tileOpacity: sysUsage.tileOpacity
            active: sysUsage.active

            ColumnLayout {
                anchors.fill: parent
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: "↓"
                        color: sysUsage.netRxColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: sysUsage.formatBytes(sysUsage.rxBytesPerSec)
                        color: netTile.textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: sysUsage.linkDownMbps > 0
                    text: sysUsage.formatLinkSpeed(sysUsage.linkDownMbps) + " verfügbar"
                    color: netTile.subTextColor
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    opacity: 0.65
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 6
                    Text {
                        text: "↑"
                        color: sysUsage.netTxColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: sysUsage.formatBytes(sysUsage.txBytesPerSec)
                        color: netTile.textColor
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
                Text {
                    Layout.fillWidth: true
                    visible: sysUsage.linkUpMbps > 0
                    text: sysUsage.formatLinkSpeed(sysUsage.linkUpMbps) + " verfügbar"
                    color: netTile.subTextColor
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    opacity: 0.65
                    elide: Text.ElideRight
                }
            }
        }

        LiquidSquare {
            Layout.row: 1; Layout.column: 2
            Layout.fillWidth: true; Layout.fillHeight: true
            useLiquid: false
            icon: ""
            titleText: "TEMP"
            baseColor: sysUsage.baseColor
            textColor: sysUsage.textColor
            subTextColor: sysUsage.subTextColor
            tileOpacity: sysUsage.tileOpacity
            active: sysUsage.active

            ColumnLayout {
                anchors.fill: parent
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: "CPU"; font.family: "JetBrains Mono"; font.pixelSize: 10; opacity: 0.6; color: sysUsage.textColor }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: sysUsage.formatTemp(sysUsage.cpuTempC)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        font.bold: true
                        color: sysUsage.textColor
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: "GPU"; font.family: "JetBrains Mono"; font.pixelSize: 10; opacity: 0.6; color: sysUsage.textColor }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: sysUsage.formatTemp(sysUsage.gpuTempC)
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                        font.bold: true
                        color: sysUsage.textColor
                    }
                }
            }
        }
    }
}
