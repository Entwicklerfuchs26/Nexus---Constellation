import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: upd
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"
    property color warnColor: "#a9a9ff"

    readonly property int staleDaysThreshold: 30

    property bool loading: false
    property string errorText: ""
    property var inputs: []

    property bool updateRunning: false
    // "" | "running" | "done" | "error"
    property string updateStatus: ""

    function checkMetadata() {
        upd.loading = true
        upd.errorText = ""
        metaProc.running = true
    }

    function _handleMetadata(text) {
        upd.loading = false
        try {
            var d = JSON.parse(text)
            var root = d.locks.root
            var nodes = d.locks.nodes
            var inputMap = nodes[root].inputs || {}
            var now = Date.now() / 1000
            var list = []
            for (var name in inputMap) {
                var ref = inputMap[name]
                var nodeId = Array.isArray(ref) ? ref[ref.length - 1] : ref
                var node = nodes[nodeId]
                if (!node || !node.locked || !node.locked.lastModified) continue
                var ageDays = Math.floor((now - node.locked.lastModified) / 86400)
                list.push({ name: name, ageDays: ageDays, stale: ageDays > upd.staleDaysThreshold })
            }
            list.sort(function (a, b) { return b.ageDays - a.ageDays })
            upd.inputs = list
        } catch (e) {
            upd.errorText = "Konnte flake.lock nicht lesen"
            console.log("Update-Widget: Parse-Fehler", e)
        }
    }

    Process {
        id: metaProc
        command: ["bash", "-c", "timeout 5 nix flake metadata /etc/nixos/nixos-config --json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: upd._handleMetadata(this.text)
        }
    }

    function runUpdate() {
        if (upd.updateRunning) return
        upd.updateRunning = true
        upd.updateStatus = "running"
        updateProc.running = true
    }

    // Bewusst OHNE 5s-Timeout: "nix flake update" holt reale Netzwerk-Updates für
    // mehrere Inputs und darf länger laufen. Der Button-State ("läuft…") macht das
    // sichtbar, es hängt also nicht unbemerkt.
    Process {
        id: updateProc
        command: ["bash", "-c", "nix flake update --flake /etc/nixos/nixos-config 2>&1; echo ___EXIT:$?___"]
        stdout: StdioCollector {
            onStreamFinished: {
                upd.updateRunning = false
                upd.updateStatus = this.text.indexOf("___EXIT:0___") !== -1 ? "done" : "error"
                if (upd.updateStatus === "done") upd.checkMetadata()
            }
        }
    }

    Component.onCompleted: checkMetadata()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Flake-Inputs"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                opacity: 0.5
                color: upd.textColor
            }

            Rectangle {
                radius: 6
                color: Qt.rgba(upd.textColor.r, upd.textColor.g, upd.textColor.b, checkMouse.containsMouse ? 0.14 : 0.08)
                Layout.preferredWidth: checkLabel.implicitWidth + 16
                Layout.preferredHeight: 20

                Text {
                    id: checkLabel
                    anchors.centerIn: parent
                    text: upd.loading ? "…" : "Prüfen"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    color: upd.textColor
                }

                MouseArea {
                    id: checkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: upd.checkMetadata()
                }
            }
        }

        Text {
            visible: upd.errorText.length > 0
            text: upd.errorText
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.6
            color: upd.textColor
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: inputColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: inputColumn
                width: parent.width
                spacing: 4

                Repeater {
                    model: upd.inputs

                    RowLayout {
                        id: inputRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: inputRow.modelData.stale ? upd.warnColor : upd.accentColor
                        }

                        Text {
                            Layout.fillWidth: true
                            text: inputRow.modelData.name
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: upd.textColor
                        }

                        Text {
                            text: inputRow.modelData.ageDays + "d"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            opacity: inputRow.modelData.stale ? 1 : 0.5
                            color: inputRow.modelData.stale ? upd.warnColor : upd.textColor
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 8
            color: Qt.rgba(upd.accentColor.r, upd.accentColor.g, upd.accentColor.b, upd.updateRunning ? 0.5 : (updateMouse.containsMouse ? 0.9 : 0.75))

            Text {
                anchors.centerIn: parent
                text: upd.updateStatus === "running" ? "Update läuft…"
                    : upd.updateStatus === "done" ? "✓ Aktualisiert"
                    : upd.updateStatus === "error" ? "✗ Fehlgeschlagen — erneut versuchen"
                    : "nix flake update"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.bold: true
                color: upd.accentTextColor
            }

            MouseArea {
                id: updateMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !upd.updateRunning
                cursorShape: Qt.PointingHandCursor
                onClicked: upd.runUpdate()
            }
        }
    }
}
