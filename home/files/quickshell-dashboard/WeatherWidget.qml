import QtQuick
import QtQuick.Layouts

Item {
    id: weather
    anchors.fill: parent

    property color textColor: "#ffffff"

    readonly property real latitude: 50.9592
    readonly property real longitude: 13.9394

    property bool loaded: false
    property real currentTemp: 0
    property int currentCode: 0
    property var dailyDates: []
    property var dailyCodes: []
    property var dailyMax: []
    property var dailyMin: []

    function weatherIcon(code) {
        if (code === 0) return "☀️"
        if (code === 1) return "🌤️"
        if (code === 2) return "⛅"
        if (code === 3) return "☁️"
        if (code === 45 || code === 48) return "🌫️"
        if (code === 51 || code === 53 || code === 55 || code === 56 || code === 57) return "🌦️"
        if (code === 61 || code === 63 || code === 65 || code === 66 || code === 67) return "🌧️"
        if (code === 71 || code === 73 || code === 75 || code === 77) return "❄️"
        if (code === 80 || code === 81 || code === 82) return "🌧️"
        if (code === 85 || code === 86) return "🌨️"
        if (code === 95 || code === 96 || code === 99) return "⛈️"
        return "🌡️"
    }

    function weatherText(code) {
        if (code === 0) return "Klar"
        if (code === 1) return "Überw. klar"
        if (code === 2) return "Teils bewölkt"
        if (code === 3) return "Bedeckt"
        if (code === 45 || code === 48) return "Nebel"
        if (code === 51 || code === 53 || code === 55) return "Niesel"
        if (code === 56 || code === 57) return "Gefr. Niesel"
        if (code === 61 || code === 63 || code === 65) return "Regen"
        if (code === 66 || code === 67) return "Gefr. Regen"
        if (code === 71 || code === 73 || code === 75 || code === 77) return "Schnee"
        if (code === 80 || code === 81 || code === 82) return "Schauer"
        if (code === 85 || code === 86) return "Schneeschauer"
        if (code === 95 || code === 96 || code === 99) return "Gewitter"
        return "—"
    }

    function dayLabel(dayIndex) {
        if (dayIndex === 1) return "Morgen"
        return Qt.formatDate(new Date(weather.dailyDates[dayIndex]), "ddd")
    }

    function fetchWeather() {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,weather_code"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=Europe%2FBerlin&forecast_days=4"

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) {
                console.log("Wetter-Widget: HTTP-Fehler", xhr.status)
                return
            }
            try {
                var d = JSON.parse(xhr.responseText)
                weather.currentTemp = d.current.temperature_2m
                weather.currentCode = d.current.weather_code
                weather.dailyDates = d.daily.time
                weather.dailyCodes = d.daily.weather_code
                weather.dailyMax = d.daily.temperature_2m_max
                weather.dailyMin = d.daily.temperature_2m_min
                weather.loaded = true
            } catch (e) {
                console.log("Wetter-Widget: Parse-Fehler", e)
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    Component.onCompleted: fetchWeather()
    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: weather.fetchWeather()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: weather.loaded ? weather.weatherIcon(weather.currentCode) : "…"
                font.pixelSize: 42
            }

            ColumnLayout {
                spacing: 2

                Text {
                    text: weather.loaded ? Math.round(weather.currentTemp) + "°C" : "—"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 30
                    font.bold: true
                    color: weather.textColor
                }

                Text {
                    text: weather.loaded ? weather.weatherText(weather.currentCode) : "Lädt…"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    opacity: 0.75
                    color: weather.textColor
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.alignment: Qt.AlignTop
                text: "Pirna"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                opacity: 0.5
                color: weather.textColor
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: weather.loaded && weather.dailyCodes.length > 3

            Repeater {
                model: 3

                ColumnLayout {
                    id: dayCol
                    required property int index
                    readonly property int dayIndex: index + 1
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: weather.loaded ? weather.dayLabel(dayCol.dayIndex) : ""
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        opacity: 0.7
                        color: weather.textColor
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: weather.loaded ? weather.weatherIcon(weather.dailyCodes[dayCol.dayIndex]) : ""
                        font.pixelSize: 20
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: weather.loaded
                            ? Math.round(weather.dailyMax[dayCol.dayIndex]) + "° / " + Math.round(weather.dailyMin[dayCol.dayIndex]) + "°"
                            : ""
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: weather.textColor
                    }
                }
            }
        }
    }
}
