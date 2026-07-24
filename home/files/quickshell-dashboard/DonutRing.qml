import QtQuick

Item {
    id: ring

    property real value: 0
    property color ringColor: "#ffffff"
    property color trackColor: "#33ffffff"
    property color textColor: "#ffffff"
    property string label: ""
    property string valueText: ""
    property string subText: ""

    implicitWidth: 96
    implicitHeight: 96

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var cx = width / 2
            var cy = height / 2
            var radius = Math.min(width, height) / 2 - 6
            var lineWidth = 8
            var clamped = Math.min(Math.max(ring.value, 0), 100)
            var startAngle = -Math.PI / 2
            var endAngle = startAngle + Math.PI * 2 * (clamped / 100)

            ctx.lineWidth = lineWidth
            ctx.lineCap = "round"

            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, Math.PI * 2, false)
            ctx.strokeStyle = ring.trackColor
            ctx.stroke()

            if (clamped > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, radius, startAngle, endAngle, false)
                ctx.strokeStyle = ring.ringColor
                ctx.stroke()
            }
        }
    }

    onValueChanged: canvas.requestPaint()
    onRingColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.valueText
            font.family: "JetBrains Mono"
            font.pixelSize: 16
            font.bold: true
            color: ring.textColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.subText
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            opacity: 0.65
            color: ring.textColor
            visible: ring.subText.length > 0
        }
    }

    Text {
        anchors.top: parent.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: ring.label
        font.family: "JetBrains Mono"
        font.pixelSize: 11
        font.bold: true
        opacity: 0.8
        color: ring.textColor
    }
}
