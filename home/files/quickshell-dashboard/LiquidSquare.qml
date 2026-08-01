import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile

    property real value: 0
    property color fillColor: "#ffffff"
    property color baseColor: "#15130b"
    property color textColor: "#ffffff"
    property color subTextColor: "#aaaaaa"
    property color contrastTextColor: "#000000"
    property real tileOpacity: 0.55
    property real wavePhase: 0
    property bool active: true
    property bool useLiquid: true

    property string icon: ""
    property string titleText: ""
    property string valueText: ""
    property string subText: ""

    default property alias body: bodyArea.data

    radius: 12
    color: Qt.rgba(tile.baseColor.r, tile.baseColor.g, tile.baseColor.b, tile.tileOpacity)
    border.width: 1
    border.color: Qt.rgba(tile.textColor.r, tile.textColor.g, tile.textColor.b, 0.08)
    clip: true

    property real level: tile.value
    Behavior on level {
        NumberAnimation { duration: 800; easing.type: Easing.OutQuint }
    }

    readonly property real liquidTopY: tile.height * (1 - Math.min(1, Math.max(0, tile.level)))

    function _repaint() {
        if (tile.useLiquid && tile.active && tile.value > 0) liquidCanvas.requestPaint()
    }

    onWavePhaseChanged: tile._repaint()
    onLevelChanged: tile._repaint()
    onWidthChanged: tile._repaint()
    onHeightChanged: tile._repaint()

    Canvas {
        id: liquidCanvas
        anchors.fill: parent
        visible: tile.useLiquid
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            if (!tile.useLiquid) return

            var w = width
            var h = height
            var r = tile.radius

            ctx.save()
            ctx.beginPath()
            ctx.moveTo(r, 0)
            ctx.lineTo(w - r, 0)
            ctx.quadraticCurveTo(w, 0, w, r)
            ctx.lineTo(w, h - r)
            ctx.quadraticCurveTo(w, h, w - r, h)
            ctx.lineTo(r, h)
            ctx.quadraticCurveTo(0, h, 0, h - r)
            ctx.lineTo(0, r)
            ctx.quadraticCurveTo(0, 0, r, 0)
            ctx.closePath()
            ctx.clip()

            var level = Math.min(1, Math.max(0, tile.level))
            var topY = h * (1 - level)
            var showWave = level > 0.01 && level < 0.99
            var amplitude = showWave ? Math.min(5, h * 0.035) : 0
            var waveLength = Math.max(20, w / 1.4)

            ctx.beginPath()
            ctx.moveTo(0, h + 1)
            ctx.lineTo(0, topY)

            var steps = 24
            var prevX = 0
            var prevY = topY + amplitude * Math.sin(tile.wavePhase)
            for (var i = 1; i <= steps; i++) {
                var x = (w / steps) * i
                var y = topY + amplitude * Math.sin((x / waveLength) * Math.PI * 2 + tile.wavePhase)
                var midX = (prevX + x) / 2
                ctx.bezierCurveTo(midX, prevY, midX, y, x, y)
                prevX = x
                prevY = y
            }

            ctx.lineTo(w, h + 1)
            ctx.closePath()

            var gradient = ctx.createLinearGradient(0, topY, 0, h)
            var lightC = Qt.lighter(tile.fillColor, 1.25)
            gradient.addColorStop(0, Qt.rgba(lightC.r, lightC.g, lightC.b, 0.95))
            gradient.addColorStop(1, Qt.rgba(tile.fillColor.r, tile.fillColor.g, tile.fillColor.b, 0.95))
            ctx.fillStyle = gradient
            ctx.fill()

            ctx.restore()
        }
    }

    // Kopf: Icon + Titel
    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 6

        Text {
            visible: tile.icon.length > 0
            text: tile.icon
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: tile.textColor
            opacity: 0.85
        }
        Text {
            text: tile.titleText
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            font.bold: true
            opacity: 0.75
            color: tile.textColor
        }
        Item { Layout.fillWidth: true }
    }

    // Normale Textebene (valueText/subText), sichtbar über dem Basis-Hintergrund.
    Item {
        id: normalLabel
        anchors.fill: parent
        anchors.margins: 12
        visible: tile.useLiquid

        Text {
            id: normalValue
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: tile.valueText
            font.family: "JetBrains Mono"
            font.pixelSize: 20
            font.bold: true
            color: tile.textColor
        }
        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: tile.subText
            font.family: "JetBrains Mono"
            font.pixelSize: 10
            opacity: 0.7
            color: tile.subTextColor
            visible: tile.subText.length > 0
        }
    }

    // Kontrastebene: identischer Text in Kontrastfarbe, geclippt auf die Füllhöhe,
    // damit die Beschriftung auch über der hellen Flüssigkeit lesbar bleibt.
    Item {
        id: contrastMask
        visible: tile.useLiquid
        x: 0
        y: tile.liquidTopY
        width: tile.width
        height: Math.max(0, tile.height - tile.liquidTopY)
        clip: true

        Item {
            x: 0
            y: -tile.liquidTopY
            width: tile.width
            height: tile.height

            Item {
                anchors.fill: parent
                anchors.margins: 12

                Text {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    text: tile.valueText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 20
                    font.bold: true
                    color: tile.contrastTextColor
                }
                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    text: tile.subText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    opacity: 0.7
                    color: tile.contrastTextColor
                    visible: tile.subText.length > 0
                }
            }
        }
    }

    // Frei belegbarer Inhalt (z.B. NET-Kachel), wenn useLiquid=false.
    Item {
        id: bodyArea
        anchors.top: parent.top
        anchors.topMargin: 30
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        visible: !tile.useLiquid
    }

    Component.onCompleted: tile._repaint()
}
