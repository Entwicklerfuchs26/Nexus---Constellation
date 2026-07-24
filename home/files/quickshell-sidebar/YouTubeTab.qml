import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: tab

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    property bool toolsChecked: false
    property bool toolsMissing: false
    property bool searching: false
    property var results: []

    function _shQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function formatDuration(sec) {
        if (!sec || sec <= 0) return "—"
        var m = Math.floor(sec / 60)
        var s = Math.floor(sec % 60)
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function search(query) {
        var q = query.trim()
        if (!q || tab.searching) return
        tab.searching = true
        tab.results = []
        searchProc.command = ["bash", "-c",
            "if ! command -v yt-dlp >/dev/null 2>&1; then echo MISSING_TOOLS; exit 0; fi\n"
            + "timeout 20 yt-dlp " + tab._shQuote("ytsearch5:" + q)
            + " --dump-json --no-playlist --flat-playlist 2>/dev/null"]
        searchProc.running = true
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                tab.searching = false
                var text = this.text.trim()
                if (text.indexOf("MISSING_TOOLS") === 0) {
                    tab.toolsMissing = true
                    return
                }
                var lines = text.split("\n").filter(function (l) { return l.trim().length > 0 })
                var list = []
                for (var i = 0; i < lines.length; i++) {
                    try {
                        var d = JSON.parse(lines[i])
                        list.push({
                            title: d.title || "(ohne Titel)",
                            channel: d.channel || d.uploader || "—",
                            duration: tab.formatDuration(d.duration),
                            thumbnail: (d.thumbnails && d.thumbnails.length > 0) ? d.thumbnails[d.thumbnails.length - 1].url : (d.thumbnail || ""),
                            url: d.webpage_url || d.url || ("https://www.youtube.com/watch?v=" + d.id)
                        })
                    } catch (e) {
                        console.log("YouTube-Tab: Parse-Fehler", e)
                    }
                }
                tab.results = list
            }
        }
    }

    Process { id: mpvLauncher }

    function openInMpv(url) {
        mpvLauncher.exec(["bash", "-c",
            "mpv --no-border --ontop --geometry=640x360+1270+10 --input-ipc-server=/tmp/mpvsocket " + tab._shQuote(url)])
    }

    Component.onCompleted: {
        toolCheck.command = ["bash", "-c", "command -v yt-dlp >/dev/null 2>&1 && command -v mpv >/dev/null 2>&1 && echo OK || echo MISSING"]
        toolCheck.running = true
    }

    Process {
        id: toolCheck
        stdout: StdioCollector {
            onStreamFinished: {
                tab.toolsChecked = true
                tab.toolsMissing = this.text.trim() !== "OK"
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            visible: tab.toolsChecked && tab.toolsMissing
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "yt-dlp und/oder mpv fehlen — nach Rebuild verfügbar"
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            opacity: 0.5
            color: tab.textColor
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !tab.toolsMissing
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: 8
                color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.08)

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: tab.textColor
                    clip: true
                    selectByMouse: true
                    onAccepted: tab.search(searchInput.text)
                }
            }

            Rectangle {
                radius: 8
                color: Qt.rgba(tab.accentColor.r, tab.accentColor.g, tab.accentColor.b, tab.searching ? 0.4 : (searchMouse.containsMouse ? 0.9 : 0.75))
                Layout.preferredWidth: 50
                Layout.preferredHeight: 28

                Text {
                    anchors.centerIn: parent
                    text: tab.searching ? "…" : "Suche"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.bold: true
                    color: tab.accentTextColor
                }

                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !tab.searching
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tab.search(searchInput.text)
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !tab.toolsMissing
            clip: true
            contentWidth: width
            contentHeight: resultColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: resultColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: tab.results

                    Rectangle {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 6
                        color: rowMouse.containsMouse ? Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.08) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 64
                                Layout.preferredHeight: 36
                                radius: 4
                                color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.1)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: row.modelData.thumbnail
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: row.modelData.thumbnail.length > 0
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.title
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    color: tab.textColor
                                }
                                Text {
                                    text: row.modelData.channel + " · " + row.modelData.duration
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    opacity: 0.5
                                    color: tab.textColor
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tab.openInMpv(row.modelData.url)
                        }
                    }
                }
            }
        }
    }
}
