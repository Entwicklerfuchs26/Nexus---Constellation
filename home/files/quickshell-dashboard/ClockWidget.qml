import QtQuick

Item {
    id: clock
    anchors.fill: parent

    property color textColor: "#ffffff"
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.now = new Date()
    }

    Column {
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.now, "hh:mm:ss")
            font.family: "JetBrains Mono"
            font.pixelSize: 44
            font.bold: true
            color: clock.textColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.now, "dddd, d. MMMM yyyy")
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            opacity: 0.75
            color: clock.textColor
        }
    }
}
