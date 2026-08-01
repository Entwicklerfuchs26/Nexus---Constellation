import QtQuick

Item {
    id: slider

    property real value: 0
    readonly property real minValue: -12
    readonly property real maxValue: 12
    property color trackColor: "#333333"
    property color fillColor: "#c6b22b"
    property color textColor: "#ffffff"
    property string label: ""

    implicitWidth: 28
    implicitHeight: 116

    readonly property real _range: maxValue - minValue
    readonly property real _norm: Math.max(0, Math.min(1, (value - minValue) / _range))

    function _setFromY(y) {
        var norm = 1 - Math.max(0, Math.min(1, y / track.height))
        slider.value = Math.round((slider.minValue + norm * slider._range) * 2) / 2
    }

    Rectangle {
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: 5
        height: parent.height - 16
        radius: 2.5
        color: Qt.rgba(slider.trackColor.r, slider.trackColor.g, slider.trackColor.b, 0.35)

        Rectangle {
            // Nulllinie
            anchors.horizontalCenter: parent.horizontalCenter
            y: track.height * (1 - (0 - slider.minValue) / slider._range) - 1
            width: 11
            height: 1
            color: slider.textColor
            opacity: 0.35
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 5
            radius: 2.5
            height: track.height * slider._norm
            color: slider.fillColor
        }

        Rectangle {
            width: 16
            height: 8
            radius: 3
            color: slider.fillColor
            anchors.horizontalCenter: parent.horizontalCenter
            y: track.height * (1 - slider._norm) - height / 2
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            preventStealing: true
            cursorShape: Qt.SizeVerCursor
            onPositionChanged: function (mouse) { if (pressed) slider._setFromY(mouse.y) }
            onPressed: function (mouse) { slider._setFromY(mouse.y) }
        }
    }

    Text {
        anchors.top: track.bottom
        anchors.topMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        text: slider.label
        font.family: "JetBrains Mono"
        font.pixelSize: 8
        opacity: 0.6
        color: slider.textColor
    }
}
