import QtQuick
import QtWebEngine

// Rendert von Hermes generierte React/Recharts-JSX-Snippets lokal per
// WebEngineView (siehe home/files/quickshell-dashboard/sojus-renderer/).
// Kein Netzwerkzugriff nötig — die Renderer-Seite lädt nur lokale
// react/react-dom/recharts/babel-Bundles (CSP blockt zusätzlich jeden
// Fetch/XHR/Iframe-Versuch aus generiertem Code, siehe index.html).
Item {
    id: componentBubble
    property string jsxSource: ""
    property string title: "Diagramm"
    property color textColor: "#ffffff"
    property color subTextColor: "#aaaaaa"

    property bool codeVisible: false
    property real webViewHeight: 220

    width: parent ? parent.width : 300
    height: contentColumn.implicitHeight

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 6

        Row {
            id: headerRow
            spacing: 6

            Text {
                text: "</>"
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.bold: true
                opacity: codeMouse.containsMouse ? 1.0 : 0.6
                color: componentBubble.textColor

                MouseArea {
                    id: codeMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: componentBubble.codeVisible = !componentBubble.codeVisible
                }
            }

            Text {
                text: componentBubble.title
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                opacity: 0.7
                color: componentBubble.textColor
            }

            Text {
                visible: webView.loading
                text: "· lädt…"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                opacity: 0.5
                color: componentBubble.subTextColor
            }
        }

        Rectangle {
            width: parent.width
            height: componentBubble.webViewHeight
            radius: 8
            color: "#1e1e2e"
            clip: true

            WebEngineView {
                id: webView
                anchors.fill: parent
                url: "file:///home/fuchs/.local/share/sojus/renderer/index.html"
                backgroundColor: "#1e1e2e"

                onLoadingChanged: function (loadInfo) {
                    if (loadInfo.status === WebEngineView.LoadSucceededStatus) {
                        webView.runJavaScript("renderComponent(" + JSON.stringify(componentBubble.jsxSource) + ")")
                    }
                }

                // JS→QML-Kanal ohne WebChannel-Boilerplate: die Renderer-Seite
                // schreibt "height:<px>" in document.title, sobald sich die
                // Inhaltshöhe ändert (siehe reportHeightIfChanged() in
                // sojus-renderer/index.html). onTitleChanged ist der einzige
                // dafür in QML verfügbare, zuverlässige Trigger.
                onTitleChanged: {
                    var m = /^height:(\d+)$/.exec(webView.title)
                    if (m) {
                        var h = parseInt(m[1])
                        componentBubble.webViewHeight = Math.min(Math.max(h + 16, 120), 480)
                    }
                }
            }
        }

        Text {
            id: codeText
            visible: componentBubble.codeVisible
            width: parent.width
            wrapMode: Text.Wrap
            text: componentBubble.jsxSource
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            color: componentBubble.subTextColor
        }
    }
}
