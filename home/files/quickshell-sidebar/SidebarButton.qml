import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Entweder glyph (Emoji/Nerd-Font-Text) oder iconName (Icon-Theme-Lookup) setzen.
    property string glyph: ""
    property string iconName: ""
    property string tooltipText: ""
    property color hoverColor: "#ffffff"
    property color foregroundColor: "#ffffff"
    property color labelColor: "#ffffff"

    signal clicked()

    readonly property bool hovered: mouseArea.containsMouse

    implicitWidth: iconArea.width
    implicitHeight: 40

    Rectangle {
        id: hoverBg
        anchors.left: parent.left
        width: iconArea.width
        height: parent.height
        radius: 10
        color: root.hoverColor
        opacity: root.hovered ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Item {
        id: iconArea
        width: 40
        height: 40
        scale: root.hovered ? 1.12 : 1.0
        opacity: root.hovered ? 1.0 : 0.85
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

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
    }

    MouseArea {
        id: mouseArea
        anchors.left: parent.left
        width: iconArea.width
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
