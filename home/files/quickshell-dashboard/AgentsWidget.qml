import QtQuick
import QtQuick.Layouts

Item {
    id: agents
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color errorColor: "#ba1a1a"

    readonly property string healthUrl: "http://192.168.1.26:3001/health"

    property bool checking: false
    property bool reachable: false
    property bool checked: false
    property string version: ""
    property var mcpStatus: ({})

    function check() {
        agents.checking = true
        var xhr = new XMLHttpRequest()
        xhr.timeout = 5000
        xhr.ontimeout = function () {
            agents.checking = false
            agents.checked = true
            agents.reachable = false
        }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            agents.checking = false
            agents.checked = true
            if (xhr.status < 200 || xhr.status >= 300) {
                agents.reachable = false
                return
            }
            try {
                var d = JSON.parse(xhr.responseText)
                agents.version = d.version || ""
                agents.mcpStatus = d.mcp_status || {}
                agents.reachable = true
            } catch (e) {
                console.log("Agents-Widget: Parse-Fehler", e)
                agents.reachable = false
            }
        }
        xhr.open("GET", agents.healthUrl)
        xhr.send()
    }

    function _mcpEntries() {
        var out = []
        for (var name in agents.mcpStatus) out.push({ name: name, up: agents.mcpStatus[name] })
        out.sort(function (a, b) { return (a.up === b.up) ? 0 : (a.up ? 1 : -1) })
        return out
    }

    Component.onCompleted: check()
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: agents.check()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            visible: !agents.checked
            text: "Prüfe Verbindung…"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: agents.textColor
        }

        ColumnLayout {
            visible: agents.checked && !agents.reachable
            spacing: 8

            Text {
                text: "Sojus Core nicht erreichbar"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                opacity: 0.6
                color: agents.errorColor
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(agents.textColor.r, agents.textColor.g, agents.textColor.b, retryMouse.containsMouse ? 0.14 : 0.08)
                Layout.preferredWidth: retryLabel.implicitWidth + 20
                Layout.preferredHeight: 26

                Text {
                    id: retryLabel
                    anchors.centerIn: parent
                    text: agents.checking ? "…" : "Erneut prüfen"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: agents.textColor
                }

                MouseArea {
                    id: retryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: agents.check()
                }
            }
        }

        ColumnLayout {
            visible: agents.checked && agents.reachable
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                spacing: 8
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: agents.accentColor
                }
                Text {
                    text: "Online · v" + agents.version
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: agents.textColor
                }
            }

            Text {
                text: "MCP-Server (" + agents._mcpEntries().filter(function (e) { return e.up }).length + "/" + agents._mcpEntries().length + " aktiv)"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                opacity: 0.5
                color: agents.textColor
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: mcpColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: mcpColumn
                    width: parent.width
                    spacing: 3

                    Repeater {
                        model: agents._mcpEntries()

                        RowLayout {
                            id: mcpRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: mcpRow.modelData.up ? agents.accentColor : agents.errorColor
                            }

                            Text {
                                Layout.fillWidth: true
                                text: mcpRow.modelData.name
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11
                                opacity: mcpRow.modelData.up ? 0.75 : 1
                                color: agents.textColor
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
