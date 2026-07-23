import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    // Entweder glyph (Emoji/Nerd-Font-Text) oder iconName (Icon-Theme-Lookup) setzen.
    property string glyph: ""
    property string iconName: ""
    property string tooltipText: ""
    property color hoverColor: "#ffffff"
    property color foregroundColor: "#ffffff"

    signal clicked()

    implicitWidth: 40
    implicitHeight: 40

    Rectangle {
        id: hoverBg
        anchors.fill: parent
        radius: 10
        color: hoverColor
        opacity: mouseArea.containsMouse ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
        visible: root.glyph !== ""
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: 18
        color: root.foregroundColor
    }

    IconImage {
        visible: root.iconName !== ""
        anchors.centerIn: parent
        width: 24
        height: 24
        source: root.iconName !== "" ? Quickshell.iconPath(root.iconName) : ""
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
