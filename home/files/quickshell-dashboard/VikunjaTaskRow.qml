import QtQuick
import QtQuick.Layouts

RowLayout {
    id: taskRow
    required property var task
    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color highColor: "#ba1a1a"
    property color mediumColor: "#a9a9ff"
    signal toggleRequested()

    Layout.fillWidth: true
    spacing: 10
    opacity: taskRow.task.done ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

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

    Rectangle {
        visible: taskRow.task.priority > 0
        width: 8
        height: 8
        radius: 4
        color: taskRow.task.priority >= 3 ? taskRow.highColor
            : taskRow.task.priority === 2 ? taskRow.mediumColor
            : taskRow.accentColor
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
        text: taskRow.task.dueLabel || ""
        font.family: "JetBrains Mono"
        font.pixelSize: 10
        opacity: taskRow.task.overdue ? 0.9 : 0.55
        color: taskRow.task.overdue ? taskRow.highColor : taskRow.textColor
    }
}
