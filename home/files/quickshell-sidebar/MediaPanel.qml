import QtQuick
import QtQuick.Layouts

Rectangle {
    id: panel

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"
    property color surfaceColor: "#15130b"
    property color outlineColor: "#96917b"

    readonly property var tabNames: ["Apple Music", "Jellyfin", "YouTube", "AniList"]
    property int activeTabIndex: 0

    radius: 16
    color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.9)
    border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
    border.width: 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: panel.tabNames

                Rectangle {
                    id: tabBtn
                    required property string modelData
                    required property int index
                    radius: 8
                    color: panel.activeTabIndex === index
                        ? panel.accentColor
                        : Qt.rgba(panel.textColor.r, panel.textColor.g, panel.textColor.b, tabMouse.containsMouse ? 0.12 : 0.06)
                    Layout.preferredWidth: tabLabel.implicitWidth + 14
                    Layout.preferredHeight: 24

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: tabBtn.modelData
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: panel.activeTabIndex === tabBtn.index
                        color: panel.activeTabIndex === tabBtn.index ? panel.accentTextColor : panel.textColor
                        opacity: panel.activeTabIndex === tabBtn.index ? 1 : 0.65
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.activeTabIndex = tabBtn.index
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(panel.outlineColor.r, panel.outlineColor.g, panel.outlineColor.b, 0.3)
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: panel.activeTabIndex

            AppleMusicTab { textColor: panel.textColor; accentColor: panel.accentColor; accentTextColor: panel.accentTextColor }
            JellyfinTab { textColor: panel.textColor; accentColor: panel.accentColor; accentTextColor: panel.accentTextColor }
            YouTubeTab { textColor: panel.textColor; accentColor: panel.accentColor; accentTextColor: panel.accentTextColor }
            AniListTab { textColor: panel.textColor; accentColor: panel.accentColor; accentTextColor: panel.accentTextColor }
        }

        MpvControls { textColor: panel.textColor; accentColor: panel.accentColor }
    }
}
