import QtQuick
import QtQuick.Layouts

Item {
    id: chat
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"
    property color errorColor: "#ba1a1a"

    readonly property string baseUrl: "http://192.168.1.26:3001"

    property bool checking: true
    property bool reachable: false
    property bool sending: false
    property var messages: []

    function checkHealth() {
        chat.checking = true
        var xhr = new XMLHttpRequest()
        xhr.timeout = 5000
        xhr.ontimeout = function () { chat.checking = false; chat.reachable = false }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            chat.checking = false
            chat.reachable = (xhr.status >= 200 && xhr.status < 300)
        }
        xhr.open("GET", chat.baseUrl + "/health")
        xhr.send()
    }

    function sendMessage(text) {
        var trimmed = text.trim()
        if (!trimmed || chat.sending) return

        var history = chat.messages.map(function (m) { return { role: m.role, content: m.content } })
        history.push({ role: "user", content: trimmed })

        chat.messages = chat.messages.concat([{ role: "user", content: trimmed }])
        chat.sending = true

        var xhr = new XMLHttpRequest()
        xhr.timeout = 30000
        xhr.ontimeout = function () {
            chat.sending = false
            chat.messages = chat.messages.concat([{ role: "error", content: "Zeitüberschreitung — Antwort kam nicht rechtzeitig." }])
        }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            chat.sending = false
            if (xhr.status < 200 || xhr.status >= 300) {
                chat.messages = chat.messages.concat([{ role: "error", content: "Fehler (" + xhr.status + ")" }])
                return
            }
            try {
                var d = JSON.parse(xhr.responseText)
                var reply = d.choices && d.choices[0] && d.choices[0].message ? d.choices[0].message.content : "(leere Antwort)"
                chat.messages = chat.messages.concat([{ role: "assistant", content: reply }])
            } catch (e) {
                console.log("Sojus-Chat-Widget: Parse-Fehler", e)
                chat.messages = chat.messages.concat([{ role: "error", content: "Antwort konnte nicht gelesen werden." }])
            }
        }
        xhr.open("POST", chat.baseUrl + "/v1/chat/completions")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({ model: "sojus", messages: history, stream: false }))
    }

    Component.onCompleted: checkHealth()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            visible: chat.checking
            text: "Prüfe Verbindung…"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: chat.textColor
        }

        ColumnLayout {
            visible: !chat.checking && !chat.reachable
            spacing: 8

            Text {
                text: "Sojus nicht erreichbar"
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                opacity: 0.6
                color: chat.textColor
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(chat.textColor.r, chat.textColor.g, chat.textColor.b, retryMouse.containsMouse ? 0.14 : 0.08)
                Layout.preferredWidth: retryLabel.implicitWidth + 20
                Layout.preferredHeight: 26

                Text {
                    id: retryLabel
                    anchors.centerIn: parent
                    text: "Erneut versuchen"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: chat.textColor
                }

                MouseArea {
                    id: retryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chat.checkHealth()
                }
            }
        }

        ColumnLayout {
            visible: !chat.checking && chat.reachable
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Flickable {
                id: historyFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: historyColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                onContentHeightChanged: contentY = Math.max(0, contentHeight - height)

                ColumnLayout {
                    id: historyColumn
                    width: parent.width
                    spacing: 6

                    Text {
                        visible: chat.messages.length === 0
                        text: "Noch keine Nachrichten"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        opacity: 0.35
                        color: chat.textColor
                    }

                    Repeater {
                        model: chat.messages

                        ColumnLayout {
                            id: msgRow
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: msgRow.modelData.role === "user" ? "Du" : msgRow.modelData.role === "error" ? "Fehler" : "Sojus"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                opacity: 0.5
                                color: msgRow.modelData.role === "error" ? chat.errorColor : chat.textColor
                            }

                            Text {
                                Layout.fillWidth: true
                                text: msgRow.modelData.content
                                wrapMode: Text.WordWrap
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                color: chat.textColor
                            }
                        }
                    }

                    Text {
                        visible: chat.sending
                        text: "Sojus tippt…"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        opacity: 0.5
                        color: chat.textColor
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: Qt.rgba(chat.textColor.r, chat.textColor.g, chat.textColor.b, 0.08)

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        color: chat.textColor
                        clip: true
                        selectByMouse: true
                        onAccepted: {
                            chat.sendMessage(input.text)
                            input.text = ""
                        }
                    }
                }

                Rectangle {
                    radius: 8
                    color: Qt.rgba(chat.accentColor.r, chat.accentColor.g, chat.accentColor.b, chat.sending ? 0.4 : (sendMouse.containsMouse ? 0.9 : 0.75))
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 32

                    Text {
                        anchors.centerIn: parent
                        text: "Senden"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.bold: true
                        color: chat.accentTextColor
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !chat.sending
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            chat.sendMessage(input.text)
                            input.text = ""
                        }
                    }
                }
            }
        }
    }
}
