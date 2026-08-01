import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: eqTab

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    readonly property var bandLabels: ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property string activePreset: "Flat"
    property bool dirty: false

    readonly property var presets: ({
        "Flat":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":    [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
        "Treble":  [0, 0, 0, 0, 0, 0, 2, 4, 5, 6],
        "Vocal":   [-2, -2, 0, 2, 4, 4, 2, 0, -1, -2],
        "Pop":     [-1, 0, 2, 3, 2, 0, -1, -1, 0, 1],
        "Rock":    [4, 3, 1, 0, -1, 0, 2, 3, 3, 3],
        "Jazz":    [3, 2, 0, 1, -1, -1, 0, 1, 2, 3],
        "Classic": [0, 0, 0, 0, 0, 0, -1, -1, -2, -3]
    })

    function applyPreset(name) {
        var p = eqTab.presets[name]
        if (!p) return
        eqTab.gains = p.slice()
        eqTab.activePreset = name
        eqTab.dirty = false
        eqTab._run(p, name)
    }

    function setBand(index, value) {
        var g = eqTab.gains.slice()
        g[index] = value
        eqTab.gains = g
        eqTab.activePreset = "Custom"
        eqTab.dirty = true
    }

    function applyCurrent() {
        eqTab._run(eqTab.gains, eqTab.activePreset)
        eqTab.dirty = false
    }

    function _run(gains, presetName) {
        var args = ["eq_apply.py"]
        for (var i = 0; i < gains.length; i++) args.push(String(gains[i]))
        args.push("--preset")
        args.push(presetName)
        applyProc.command = args
        applyProc.running = true
    }

    Process {
        id: applyProc
    }

    Process {
        id: loadProc
        command: ["cat", "/home/fuchs/.local/state/nexus-eq/state.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                var trimmed = this.text.trim()
                if (!trimmed) return
                try {
                    var d = JSON.parse(trimmed)
                    if (d.gains && d.gains.length === 10) eqTab.gains = d.gains
                    if (d.preset) eqTab.activePreset = d.preset
                } catch (e) {}
            }
        }
    }
    Component.onCompleted: loadProc.running = true

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Equalizer"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                font.bold: true
                color: eqTab.accentColor
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: 7
                color: Qt.rgba(eqTab.textColor.r, eqTab.textColor.g, eqTab.textColor.b, eqTab.dirty ? 0.06 : 0.12)
                Layout.preferredWidth: savedLabel.implicitWidth + 12
                Layout.preferredHeight: 16
                Text {
                    id: savedLabel
                    anchors.centerIn: parent
                    text: eqTab.dirty ? "Ungespeichert" : "Saved"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    opacity: 0.7
                    color: eqTab.textColor
                }
            }
            Text {
                text: eqTab.activePreset
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.bold: true
                color: eqTab.textColor
                opacity: 0.85
            }
        }

        Item {
            id: sliderArea
            Layout.fillWidth: true
            Layout.preferredHeight: 132

            // Frequenzgang-Linie ueber den Reglern, an die Referenz angelehnt.
            Canvas {
                id: curveCanvas
                anchors.fill: parent
                z: 10
                readonly property int _padBottom: 16
                readonly property int _n: eqTab.gains.length

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    if (_n < 2) return
                    var colWidth = width / _n
                    var trackHeight = height - _padBottom
                    var minV = -12, maxV = 12

                    ctx.beginPath()
                    for (var i = 0; i < _n; i++) {
                        var norm = (eqTab.gains[i] - minV) / (maxV - minV)
                        var x = colWidth * (i + 0.5)
                        var y = trackHeight * (1 - norm)
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = Qt.rgba(eqTab.accentColor.r, eqTab.accentColor.g, eqTab.accentColor.b, 0.55)
                    ctx.lineWidth = 2
                    ctx.lineJoin = "round"
                    ctx.lineCap = "round"
                    ctx.stroke()
                }

                Connections {
                    target: eqTab
                    function onGainsChanged() { curveCanvas.requestPaint() }
                }
                Component.onCompleted: requestPaint()
            }

            RowLayout {
                anchors.fill: parent
                spacing: 3

                Repeater {
                    model: 10
                    delegate: EqSlider {
                        id: sliderItem
                        required property int index
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        trackColor: eqTab.textColor
                        fillColor: eqTab.accentColor
                        textColor: eqTab.textColor
                        label: eqTab.bandLabels[index]

                        Component.onCompleted: sliderItem.value = eqTab.gains[sliderItem.index]
                        Connections {
                            target: eqTab
                            function onGainsChanged() { sliderItem.value = eqTab.gains[sliderItem.index] }
                        }
                        onValueChanged: {
                            if (Math.abs(sliderItem.value - eqTab.gains[sliderItem.index]) > 0.01) {
                                eqTab.setBand(sliderItem.index, sliderItem.value)
                            }
                        }
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: Object.keys(eqTab.presets)
                delegate: Rectangle {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: 6
                    color: eqTab.activePreset === modelData
                        ? eqTab.accentColor
                        : Qt.rgba(eqTab.textColor.r, eqTab.textColor.g, eqTab.textColor.b, presetMouse.containsMouse ? 0.12 : 0.06)

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        color: eqTab.activePreset === parent.modelData ? eqTab.accentTextColor : eqTab.textColor
                        opacity: eqTab.activePreset === parent.modelData ? 1 : 0.75
                    }
                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: eqTab.applyPreset(parent.modelData)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            radius: 8
            color: eqTab.dirty
                ? eqTab.accentColor
                : Qt.rgba(eqTab.textColor.r, eqTab.textColor.g, eqTab.textColor.b, applyMouse.containsMouse ? 0.12 : 0.06)

            Text {
                anchors.centerIn: parent
                text: eqTab.dirty ? "Anwenden" : "Angewendet"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                font.bold: eqTab.dirty
                color: eqTab.dirty ? eqTab.accentTextColor : eqTab.textColor
                opacity: eqTab.dirty ? 1 : 0.5
            }
            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: eqTab.dirty ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (eqTab.dirty) eqTab.applyCurrent()
            }
        }
    }
}
