import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: monitor
    anchors.fill: parent

    property color textColor: "#ffffff"
    property color ringColor: "#c6b22b"
    property color trackColor: "#33ffffff"

    property real cpuPercent: 0
    property real cpuTemp: 0
    property real gpuPercent: 0
    property real gpuTemp: 0
    property real vramUsedMb: 0
    property real vramTotalMb: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0

    property var _prevCpu: null

    readonly property string _pollScript: "
        timeout 5 cat /proc/stat | head -1
        echo '###SPLIT###'
        for d in /sys/class/hwmon/hwmon*; do
            n=$(timeout 5 cat \"$d/name\" 2>/dev/null)
            if [ \"$n\" = \"k10temp\" ]; then timeout 5 cat \"$d/temp1_input\"; break; fi
        done
        echo '###SPLIT###'
        timeout 5 nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null
        echo '###SPLIT###'
        timeout 5 grep -E '^(MemTotal|MemAvailable):' /proc/meminfo
    "

    function _parseCpuLine(line) {
        // "cpu  user nice system idle iowait irq softirq steal guest guest_nice"
        var parts = line.trim().split(/\s+/).slice(1).map(Number)
        var idle = parts[3] + (parts[4] || 0)
        var total = parts.reduce(function (a, b) { return a + b }, 0)
        return { idle: idle, total: total }
    }

    function _handleOutput(text) {
        var blocks = text.split("###SPLIT###")
        if (blocks.length < 4) return

        var cpuLine = blocks[0].trim()
        if (cpuLine.length > 0) {
            var sample = monitor._parseCpuLine(cpuLine)
            if (monitor._prevCpu !== null) {
                var idleDelta = sample.idle - monitor._prevCpu.idle
                var totalDelta = sample.total - monitor._prevCpu.total
                if (totalDelta > 0) {
                    monitor.cpuPercent = Math.max(0, Math.min(100, 100 * (1 - idleDelta / totalDelta)))
                }
            }
            monitor._prevCpu = sample
        }

        var tempRaw = blocks[1].trim()
        if (tempRaw.length > 0) {
            monitor.cpuTemp = parseFloat(tempRaw) / 1000
        }

        var gpuLine = blocks[2].trim()
        if (gpuLine.length > 0) {
            var gpuParts = gpuLine.split(",").map(function (s) { return parseFloat(s.trim()) })
            monitor.gpuPercent = gpuParts[0]
            monitor.vramUsedMb = gpuParts[1]
            monitor.vramTotalMb = gpuParts[2]
            monitor.gpuTemp = gpuParts[3]
        }

        var memLines = blocks[3].trim().split("\n")
        var memTotalKb = 0
        var memAvailKb = 0
        for (var i = 0; i < memLines.length; i++) {
            var m = memLines[i].match(/^(\w+):\s*(\d+)/)
            if (!m) continue
            if (m[1] === "MemTotal") memTotalKb = parseInt(m[2])
            if (m[1] === "MemAvailable") memAvailKb = parseInt(m[2])
        }
        if (memTotalKb > 0) {
            monitor.ramTotalGb = memTotalKb / 1048576
            monitor.ramUsedGb = (memTotalKb - memAvailKb) / 1048576
        }
    }

    Process {
        id: poller
        command: ["bash", "-c", monitor._pollScript]
        stdout: StdioCollector {
            onStreamFinished: monitor._handleOutput(this.text)
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poller.running = true
    }

    RowLayout {
        anchors.fill: parent
        spacing: 18

        DonutRing {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            value: monitor.cpuPercent
            ringColor: monitor.ringColor
            trackColor: monitor.trackColor
            textColor: monitor.textColor
            label: "CPU"
            valueText: Math.round(monitor.cpuPercent) + "%"
            subText: Math.round(monitor.cpuTemp) + "°C"
        }

        DonutRing {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            value: monitor.gpuPercent
            ringColor: monitor.ringColor
            trackColor: monitor.trackColor
            textColor: monitor.textColor
            label: "GPU"
            valueText: Math.round(monitor.gpuPercent) + "%"
            subText: Math.round(monitor.gpuTemp) + "°C · " + Math.round(monitor.vramUsedMb / 1024 * 10) / 10 + "G"
        }

        DonutRing {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            value: monitor.ramTotalGb > 0 ? (monitor.ramUsedGb / monitor.ramTotalGb * 100) : 0
            ringColor: monitor.ringColor
            trackColor: monitor.trackColor
            textColor: monitor.textColor
            label: "RAM"
            valueText: Math.round(monitor.ramUsedGb * 10) / 10 + "G"
            subText: Math.round(monitor.ramTotalGb) + "G ges."
        }
    }
}
