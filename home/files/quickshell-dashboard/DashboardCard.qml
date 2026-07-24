import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card

    property alias title: titleLabel.text
    property color textColor: "#ffffff"
    default property alias content: contentArea.data

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

    Item {
        id: contentArea
        anchors.top: titleLabel.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        anchors.topMargin: 8

        Text {
            anchors.centerIn: parent
            text: "—"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: card.textColor
            visible: contentArea.children.length === 0
        }
    }
}
