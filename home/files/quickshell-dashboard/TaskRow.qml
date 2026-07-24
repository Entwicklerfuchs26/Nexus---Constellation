import QtQuick
import QtQuick.Layouts

RowLayout {
    id: taskRow
    required property var task
    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    signal toggleRequested()

    Layout.fillWidth: true
    spacing: 10

    Rectangle {
        width: 16
        height: 16
        radius: 4
        color: taskRow.task.done ? taskRow.accentColor : "transparent"
        border.color: taskRow.accentColor
        border.width: 1.5

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            onClicked: taskRow.toggleRequested()
        }
    }

    Text {
        Layout.fillWidth: true
        text: taskRow.task.title
        font.family: "JetBrains Mono"
        font.pixelSize: 12
        font.strikeout: taskRow.task.done
        opacity: taskRow.task.done ? 0.4 : 1
        elide: Text.ElideRight
        color: taskRow.textColor
    }

    Text {
        visible: taskRow.task.priority > 0
        text: "P" + taskRow.task.priority
        font.family: "JetBrains Mono"
        font.pixelSize: 10
        opacity: 0.6
        color: taskRow.textColor
    }

    Rectangle {
        radius: 8
        color: Qt.rgba(taskRow.accentColor.r, taskRow.accentColor.g, taskRow.accentColor.b, taskRow.task.done ? 0.15 : 0.25)
        Layout.preferredWidth: badgeText.implicitWidth + 14
        Layout.preferredHeight: badgeText.implicitHeight + 4

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: taskRow.task.done ? "erledigt" : "offen"
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            color: taskRow.textColor
        }
    }
}
