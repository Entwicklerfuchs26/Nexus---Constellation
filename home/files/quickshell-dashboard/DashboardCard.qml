import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    property alias title: titleLabel.text
    property color textColor: "#ffffff"

    radius: 16
    Layout.fillWidth: true
    Layout.fillHeight: true

    Text {
        id: titleLabel
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 20
        font.pixelSize: 15
        font.bold: true
        color: card.textColor
    }

    Text {
        anchors.centerIn: parent
        text: "—"
        font.family: "JetBrains Mono"
        font.pixelSize: 13
        opacity: 0.35
        color: card.textColor
    }
}
