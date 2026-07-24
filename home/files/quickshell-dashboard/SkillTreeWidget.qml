import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: skill
    anchors.fill: parent

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    property bool configured: false
    property string webUrl: ""
    property string localCmd: ""

    Process { id: launcher }

    function openWeb() {
        if (!skill.webUrl) return
        launcher.exec(["xdg-open", skill.webUrl])
    }

    function openLocal() {
        if (!skill.localCmd) return
        launcher.exec(["bash", "-c", skill.localCmd])
    }

    CredentialsLoader {
        id: creds
        onCredentialsLoaded: {
            skill.webUrl = creds.isPlaceholder(creds.skillTreeUrl, "SKILLTREE_URL") ? "" : creds.skillTreeUrl
            skill.localCmd = creds.isPlaceholder(creds.skillTreeLocalCmd, "SKILLTREE_LOCAL_CMD") ? "" : creds.skillTreeLocalCmd
            skill.configured = skill.webUrl.length > 0 || skill.localCmd.length > 0
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Text {
            visible: !skill.configured
            text: "Skill Tree nicht konfiguriert"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: skill.textColor
        }

        RowLayout {
            visible: skill.configured
            spacing: 10

            Rectangle {
                visible: skill.webUrl.length > 0
                radius: 8
                color: Qt.rgba(skill.accentColor.r, skill.accentColor.g, skill.accentColor.b, webMouse.containsMouse ? 0.9 : 0.75)
                Layout.preferredWidth: webLabel.implicitWidth + 24
                Layout.preferredHeight: 30

                Text {
                    id: webLabel
                    anchors.centerIn: parent
                    text: "→ Web"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    font.bold: true
                    color: skill.accentTextColor
                }

                MouseArea {
                    id: webMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: skill.openWeb()
                }
            }

            Rectangle {
                visible: skill.localCmd.length > 0
                radius: 8
                color: Qt.rgba(skill.textColor.r, skill.textColor.g, skill.textColor.b, localMouse.containsMouse ? 0.16 : 0.08)
                Layout.preferredWidth: localLabel.implicitWidth + 24
                Layout.preferredHeight: 30

                Text {
                    id: localLabel
                    anchors.centerIn: parent
                    text: "→ Lokal"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    font.bold: true
                    color: skill.textColor
                }

                MouseArea {
                    id: localMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: skill.openLocal()
                }
            }
        }
    }
}
