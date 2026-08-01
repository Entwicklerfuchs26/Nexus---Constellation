import QtQuick
import QtQuick.Layouts

Rectangle {
    id: panel

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"
    property color surfaceColor: "#15130b"
    property color outlineColor: "#96917b"

    radius: 16
    color: Qt.rgba(surfaceColor.r, surfaceColor.g, surfaceColor.b, 0.9)
    border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
    border.width: 1
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        NowPlayingHeader { textColor: panel.textColor; accentColor: panel.accentColor; accentTextColor: panel.accentTextColor }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(panel.outlineColor.r, panel.outlineColor.g, panel.outlineColor.b, 0.3)
        }

        EqualizerTab {
            Layout.fillWidth: true
            Layout.fillHeight: true
            textColor: panel.textColor
            accentColor: panel.accentColor
            accentTextColor: panel.accentTextColor
        }

        MpvControls { textColor: panel.textColor; accentColor: panel.accentColor }
    }
}
