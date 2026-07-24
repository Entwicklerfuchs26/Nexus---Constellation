import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: news
    anchors.fill: parent
    clip: true

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    property var tabs: []
    property var entriesCache: []
    property int activeTabIndex: 0

    function timeAgo(iso) {
        var d = new Date(iso)
        if (isNaN(d.getTime())) return "—"
        var diffMin = Math.round((Date.now() - d.getTime()) / 60000)
        if (diffMin < 1) return "gerade eben"
        if (diffMin < 60) return "vor " + diffMin + "min"
        var diffH = Math.round(diffMin / 60)
        if (diffH < 24) return "vor " + diffH + "h"
        return "vor " + Math.round(diffH / 24) + "d"
    }

    function _sortByTimestampDesc(a, b) {
        return new Date(b.timestamp) - new Date(a.timestamp)
    }

    function fetchTab(index) {
        var tab = news.tabs[index]
        if (!tab || !tab.url) return

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log("News-Hub-Widget: HTTP-Fehler", xhr.status, tab.name)
                return
            }
            try {
                var data = JSON.parse(xhr.responseText)
                var list = Array.isArray(data) ? data.slice() : []
                list.sort(news._sortByTimestampDesc)
                var cache = news.entriesCache.slice()
                cache[index] = list
                news.entriesCache = cache
            } catch (e) {
                console.log("News-Hub-Widget: Parse-Fehler", e, tab.name)
            }
        }
        xhr.open("GET", tab.url)
        xhr.send()
    }

    function fetchAll() {
        for (var i = 0; i < news.tabs.length; i++) news.fetchTab(i)
    }

    function openEntry(url) {
        if (!url) return
        opener.exec(["xdg-open", url])
    }

    Process { id: opener }

    CredentialsLoader {
        id: creds
        onCredentialsLoaded: {
            news.tabs = creds.newsTabs
            news.entriesCache = news.tabs.map(function () { return [] })
            news.fetchAll()
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: news.fetchAll()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: news.tabs

                Rectangle {
                    id: tabBtn
                    required property var modelData
                    required property int index
                    radius: 8
                    color: news.activeTabIndex === index
                        ? news.accentColor
                        : Qt.rgba(news.textColor.r, news.textColor.g, news.textColor.b, tabMouse.containsMouse ? 0.12 : 0.06)
                    Layout.preferredWidth: tabLabel.implicitWidth + 20
                    Layout.preferredHeight: 26

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: tabBtn.modelData.name
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        font.bold: news.activeTabIndex === tabBtn.index
                        color: news.activeTabIndex === tabBtn.index ? news.accentTextColor : news.textColor
                        opacity: news.activeTabIndex === tabBtn.index ? 1 : 0.6
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: news.activeTabIndex = tabBtn.index
                    }
                }
            }

            // Fürs Erste ein Hinweis-Stub: neue Tabs werden über NEWS_TAB_N_NAME/_URL
            // in credentials.env angelegt (kein Eingabedialog im Scope von Schritt 9).
            Rectangle {
                id: addBtn
                radius: 8
                color: Qt.rgba(news.textColor.r, news.textColor.g, news.textColor.b, addMouse.containsMouse ? 0.12 : 0.06)
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    opacity: 0.6
                    color: news.textColor
                }

                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: console.log("News-Hub-Widget: neue Tabs über NEWS_TAB_N_NAME/_URL in credentials.env anlegen")
                }
            }

            Item { Layout.fillWidth: true }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(news.textColor.r, news.textColor.g, news.textColor.b, 0.12)
        }

        Text {
            visible: news.tabs.length === 0
            text: "Keine News-Tabs konfiguriert"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: news.textColor
        }

        Text {
            visible: news.tabs.length > 0 && !news.tabs[news.activeTabIndex].url
            text: "Feed nicht konfiguriert"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            opacity: 0.35
            color: news.textColor
        }

        Text {
            visible: news.tabs.length > 0 && !!news.tabs[news.activeTabIndex].url
                && (news.entriesCache[news.activeTabIndex] || []).length === 0
            text: "Keine Einträge"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.4
            color: news.textColor
        }

        Item {
            id: listArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: news.tabs.length > 0 && !!news.tabs[news.activeTabIndex].url

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.rightMargin: 6
                clip: true
                contentWidth: width
                contentHeight: entryColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: entryColumn
                    width: flick.width
                    spacing: 0

                    Repeater {
                        model: news.entriesCache[news.activeTabIndex] || []

                        ColumnLayout {
                            id: entryDelegate
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                visible: entryDelegate.index > 0
                                color: Qt.rgba(news.textColor.r, news.textColor.g, news.textColor.b, 0.08)
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: entryRow.implicitHeight + 14
                                color: entryMouse.containsMouse
                                    ? Qt.rgba(news.textColor.r, news.textColor.g, news.textColor.b, 0.06)
                                    : "transparent"

                                RowLayout {
                                    id: entryRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 4
                                    spacing: 10

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: entryDelegate.modelData.title || "(ohne Titel)"
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            color: news.textColor
                                        }

                                        Text {
                                            text: (entryDelegate.modelData.source || "—") + " · " + news.timeAgo(entryDelegate.modelData.timestamp)
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 10
                                            opacity: 0.5
                                            color: news.textColor
                                        }
                                    }
                                }

                                MouseArea {
                                    id: entryMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: news.openEntry(entryDelegate.modelData.url)
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: flick.contentHeight > flick.height
                width: 3
                radius: 1.5
                color: Qt.rgba(news.textColor.r, news.textColor.g, news.textColor.b, 0.25)
                anchors.right: parent.right
                y: flick.contentHeight > 0 ? flick.height * (flick.contentY / flick.contentHeight) : 0
                height: flick.contentHeight > 0 ? Math.max(20, flick.height * (flick.height / flick.contentHeight)) : 0
            }
        }
    }
}
