// Screen-Coach Overlay — durchsichtiges Layer-Shell-Fenster, das einen
// pulsierenden Ring + Pfeil + Textblase an eine Bildschirmkoordinate malt.
// Liest sein Ziel aus /tmp/screen-coach/target.json (vom screen-coach-Skript
// geschrieben). Klick-durchlässig; schließt sich nach einem Timeout selbst.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
  id: root
  property string runDir: "/tmp/screen-coach"
  property var t: null

  FileView {
    id: tf
    path: root.runDir + "/target.json"
    watchChanges: true
    onLoaded: root.parse()
    onFileChanged: tf.reload()
  }
  function parse() {
    try { root.t = JSON.parse(tf.text()); }
    catch (e) { root.t = null; }
  }
  Component.onCompleted: { tf.reload(); root.parse(); }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData
      visible: root.t !== null && modelData.name === root.t.mon

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "screen-coach"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      color: "transparent"
      anchors { top: true; bottom: true; left: true; right: true }
      mask: Region {}  // nichts fängt Input -> komplett klick-durchlässig

      property real sc: root.t && root.t.scale ? root.t.scale : 1
      property bool hasPoint: root.t !== null && root.t.x >= 0 && root.t.y >= 0
      property real tx: hasPoint ? root.t.x / sc : width / 2
      property real ty: hasPoint ? root.t.y / sc : height / 2

      // Pulsierender Highlight-Ring auf dem Zielelement
      Rectangle {
        visible: win.hasPoint
        width: 96; height: 96; radius: 48
        x: win.tx - width / 2
        y: win.ty - height / 2
        color: "transparent"
        border.color: "#ffcc00"
        border.width: 5
        SequentialAnimation on scale {
          loops: Animation.Infinite
          NumberAnimation { from: 0.65; to: 1.1; duration: 650; easing.type: Easing.InOutQuad }
          NumberAnimation { from: 1.1; to: 0.65; duration: 650; easing.type: Easing.InOutQuad }
        }
      }

      // Pfeil von der Textblase zum Ring (einfache Linie mit Spitze via Canvas)
      Canvas {
        id: arrow
        anchors.fill: parent
        visible: win.hasPoint
        onPaint: {
          if (!win.hasPoint) return;
          var ctx = getContext("2d");
          ctx.reset();
          var below = win.ty > win.height / 2;
          var sx = win.tx;
          var sy = below ? win.ty - 62 - 14 : win.ty + 62 + 14; // Blasenkante
          var ex = win.tx;
          var ey = below ? win.ty - 54 : win.ty + 54;           // Ringkante
          ctx.strokeStyle = "#ffcc00";
          ctx.fillStyle = "#ffcc00";
          ctx.lineWidth = 5;
          ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(ex, ey); ctx.stroke();
          // Pfeilspitze
          var dir = below ? -1 : 1;
          ctx.beginPath();
          ctx.moveTo(ex, ey);
          ctx.lineTo(ex - 9, ey - dir * 14);
          ctx.lineTo(ex + 9, ey - dir * 14);
          ctx.closePath(); ctx.fill();
        }
        Connections {
          target: root
          function onTChanged() { arrow.requestPaint(); }
        }
      }

      // Textblase mit dem Hinweis
      Rectangle {
        id: bubble
        visible: root.t !== null && root.t.label && root.t.label.length > 0
        color: "#f21e1e2e"
        radius: 12
        border.color: "#ffcc00"
        border.width: 2
        width: Math.min(lbl.implicitWidth + 28, win.width - 40)
        height: lbl.implicitHeight + 20
        x: Math.min(Math.max(win.tx - width / 2, 16), win.width - width - 16)
        y: !win.hasPoint ? (win.height / 2 - height / 2)
           : (win.ty > win.height / 2 ? win.ty - 62 - height : win.ty + 62)
        Text {
          id: lbl
          anchors.centerIn: parent
          width: win.width - 60
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          color: "white"
          font.pixelSize: 22
          font.bold: true
          text: root.t ? (root.t.label || "") : ""
        }
      }

      // Selbst-Schließen nach Timeout
      Timer {
        running: root.t !== null
        interval: (root.t && root.t.ttl ? root.t.ttl : 10) * 1000
        onTriggered: Qt.quit()
      }
    }
  }
}
