import QtQuick
import QtQuick.Layouts

Item {
    id: box

    property color textColor: "#ffffff"
    property color subTextColor: "#aaaaaa"
    property color boxColor: "#00000000"
    property string label: ""
    property real value: 0
    property string valueOverride: ""
    property string trendText: ""
    property color trendColor: "#ffffff"
    property bool trendUp: false
    property bool showTrend: false

    function formatDuration(totalSeconds) {
        var s = Math.max(0, Math.round(totalSeconds))
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        if (h > 0) return h + "h " + m + "min"
        return m + "min"
    }

    property real _animatedValue: 0
    Behavior on _animatedValue {
        NumberAnimation { duration: 850; easing.type: Easing.OutQuint }
    }
    onValueChanged: box._animatedValue = box.value
    Component.onCompleted: box._animatedValue = box.value

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: box.boxColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        Text {
            text: box.label
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            opacity: 0.6
            color: box.textColor
        }
        Text {
            text: box.valueOverride !== "" ? box.valueOverride : box.formatDuration(box._animatedValue)
            font.family: "JetBrains Mono"
            font.pixelSize: 22
            font.bold: true
            color: box.textColor
        }
        RowLayout {
            visible: box.showTrend
            spacing: 4
            Text {
                text: box.trendUp ? "▲" : "▼"
                color: box.trendColor
                font.pixelSize: 10
            }
            Text {
                text: box.trendText
                color: box.trendColor
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                opacity: 0.9
            }
        }
        Item { Layout.fillHeight: true }
    }
}
