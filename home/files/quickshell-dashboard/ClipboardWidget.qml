import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: clip
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"

    property var entries: []

    function _shQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'"
    }

    function _handleOutput(text) {
        var lines = text.split("\n").filter(function (l) { return l.trim().length > 0 })
        var result = []
        for (var i = 0; i < lines.length; i++) {
            var tab = lines[i].indexOf("\t")
            if (tab === -1) continue
            var id = lines[i].substring(0, tab)
            var preview = lines[i].substring(tab + 1)
            result.push({ id: id, preview: preview })
        }
        clip.entries = result.slice(0, 15)
    }

    Process {
        id: lister
        command: ["bash", "-c", "timeout 5 cliphist list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: clip._handleOutput(this.text)
        }
    }

    Process { id: copier }

    function copyEntry(id) {
        copier.exec(["bash", "-c", "timeout 5 cliphist decode " + clip._shQuote(id) + " | wl-copy"])
    }

    Component.onCompleted: lister.running = true
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: lister.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            visible: clip.entries.length === 0
            text: "Zwischenablage leer"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: clip.textColor
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: entryColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: entryColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: clip.entries

                    Rectangle {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: rowText.implicitHeight + 10
                        radius: 6
                        color: rowMouse.containsMouse
                            ? Qt.rgba(clip.textColor.r, clip.textColor.g, clip.textColor.b, 0.08)
                            : "transparent"

                        Text {
                            id: rowText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 6
                            text: row.modelData.preview
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: clip.textColor
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clip.copyEntry(row.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
