import QtQuick

Item {
    id: chart

    property var values: []
    property var labels: []
    property var isTarget: []
    property color barColor: "#ffffff"
    property color targetColorA: "#ffffff"
    property color targetColorB: "#ffffff"
    property color subTextColor: "#aaaaaa"
    property int labelEvery: 1

    signal barClicked(int index)

    readonly property real labelAreaHeight: labels.length > 0 ? 16 : 0

    readonly property real maxValue: {
        var m = 1
        for (var i = 0; i < values.length; i++) {
            if (values[i] > m) m = values[i]
        }
        return m
    }

    Row {
        id: barsRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.bottomMargin: chart.labelAreaHeight
        spacing: 4

        Repeater {
            model: chart.values.length
            delegate: Item {
                id: col
                required property int index
                width: (barsRow.width - Math.max(0, chart.values.length - 1) * barsRow.spacing) / Math.max(1, chart.values.length)
                height: barsRow.height

                readonly property bool isTargetBar: chart.isTarget.length > col.index && chart.isTarget[col.index] === true

                Rectangle {
                    id: bar
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(3, col.width * 0.55)
                    radius: 3
                    color: col.isTargetBar ? "transparent" : chart.barColor
                    gradient: col.isTargetBar ? targetGrad : null

                    property real level: chart.maxValue > 0 ? Math.min(1, chart.values[col.index] / chart.maxValue) : 0
                    Behavior on level { NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }
                    height: Math.max(3, level * col.height)

                    Gradient {
                        id: targetGrad
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: chart.targetColorA }
                        GradientStop { position: 1.0; color: chart.targetColorB }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chart.barClicked(col.index)
                }
            }
        }
    }

    Row {
        visible: chart.labels.length > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: chart.labelAreaHeight
        spacing: 4

        Repeater {
            model: chart.labels.length
            delegate: Text {
                required property int index
                width: (barsRow.width - Math.max(0, chart.labels.length - 1) * 4) / Math.max(1, chart.labels.length)
                horizontalAlignment: Text.AlignHCenter
                text: (index % Math.max(1, chart.labelEvery) === 0) ? chart.labels[index] : ""
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                opacity: 0.6
                color: chart.subTextColor
            }
        }
    }
}
