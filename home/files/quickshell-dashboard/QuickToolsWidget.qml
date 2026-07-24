import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: tools
    anchors.fill: parent

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    readonly property int pomodoroTotal: 25 * 60
    property int pomodoroRemaining: pomodoroTotal
    property bool pomodoroRunning: false
    property bool pomodoroDone: false

    // Screenshot/Farbpicker sind interaktiv (Nutzer zieht eine Auswahl) — bewusst
    // OHNE 5s-Timeout, ein "timeout 5" würde die Auswahl mitten in der Bedienung killen.
    Process { id: shotProc }
    Process { id: pickerProc }
    Process { id: notifyProc }

    function takeScreenshot() {
        shotProc.exec(["bash", "-c", "grimblast copy area"])
    }

    function pickColor() {
        pickerProc.exec(["bash", "-c", "hyprpicker -a"])
    }

    function formatTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    function pomodoroStart() {
        if (tools.pomodoroRemaining <= 0) tools.pomodoroRemaining = tools.pomodoroTotal
        tools.pomodoroDone = false
        tools.pomodoroRunning = true
    }

    function pomodoroPause() {
        tools.pomodoroRunning = false
    }

    function pomodoroReset() {
        tools.pomodoroRunning = false
        tools.pomodoroDone = false
        tools.pomodoroRemaining = tools.pomodoroTotal
    }

    Timer {
        id: pomodoroTicker
        interval: 1000
        running: tools.pomodoroRunning
        repeat: true
        onTriggered: {
            if (tools.pomodoroRemaining > 0) tools.pomodoroRemaining -= 1
            if (tools.pomodoroRemaining === 0) {
                tools.pomodoroRunning = false
                tools.pomodoroDone = true
                notifyProc.exec(["timeout", "5", "notify-send", "Pomodoro", "fertig!"])
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 18

        RowLayout {
            spacing: 10

            Rectangle {
                radius: height / 2
                height: 32
                color: Qt.rgba(tools.textColor.r, tools.textColor.g, tools.textColor.b, shotMouse.containsMouse ? 0.16 : 0.08)
                Layout.preferredWidth: shotLabel.implicitWidth + 24

                Text {
                    id: shotLabel
                    anchors.centerIn: parent
                    text: "📸 Screenshot"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: tools.textColor
                }

                MouseArea {
                    id: shotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tools.takeScreenshot()
                }
            }

            Rectangle {
                radius: height / 2
                height: 32
                color: Qt.rgba(tools.textColor.r, tools.textColor.g, tools.textColor.b, pickMouse.containsMouse ? 0.16 : 0.08)
                Layout.preferredWidth: pickLabel.implicitWidth + 24

                Text {
                    id: pickLabel
                    anchors.centerIn: parent
                    text: "🎨 Farbe"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: tools.textColor
                }

                MouseArea {
                    id: pickMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tools.pickColor()
                }
            }
        }

        ColumnLayout {
            spacing: 8

            RowLayout {
                spacing: 8

                Rectangle {
                    visible: tools.pomodoroRunning
                    width: 8
                    height: 8
                    radius: 4
                    color: tools.accentColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: tools.pomodoroDone ? "Fertig! 🍅" : tools.formatTime(tools.pomodoroRemaining)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 26
                    font.bold: true
                    color: tools.textColor
                }
            }

            RowLayout {
                spacing: 8

                Rectangle {
                    visible: !tools.pomodoroRunning
                    radius: height / 2
                    height: 26
                    color: Qt.rgba(tools.accentColor.r, tools.accentColor.g, tools.accentColor.b, startMouse.containsMouse ? 0.9 : 0.75)
                    Layout.preferredWidth: startLabel.implicitWidth + 20

                    Text {
                        id: startLabel
                        anchors.centerIn: parent
                        text: "Start"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        font.bold: true
                        color: tools.accentTextColor
                    }

                    MouseArea {
                        id: startMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tools.pomodoroStart()
                    }
                }

                Rectangle {
                    visible: tools.pomodoroRunning
                    radius: height / 2
                    height: 26
                    color: Qt.rgba(tools.textColor.r, tools.textColor.g, tools.textColor.b, pauseMouse.containsMouse ? 0.16 : 0.08)
                    Layout.preferredWidth: pauseLabel.implicitWidth + 20

                    Text {
                        id: pauseLabel
                        anchors.centerIn: parent
                        text: "Pause"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        color: tools.textColor
                    }

                    MouseArea {
                        id: pauseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tools.pomodoroPause()
                    }
                }

                Rectangle {
                    radius: height / 2
                    height: 26
                    color: Qt.rgba(tools.textColor.r, tools.textColor.g, tools.textColor.b, resetMouse.containsMouse ? 0.16 : 0.08)
                    Layout.preferredWidth: resetLabel.implicitWidth + 20

                    Text {
                        id: resetLabel
                        anchors.centerIn: parent
                        text: "Reset"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                        color: tools.textColor
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: tools.pomodoroReset()
                    }
                }
            }
        }
    }
}
