import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: tab

    property color textColor: "#ffffff"
    property color accentColor: "#c6b22b"
    property color accentTextColor: "#383100"

    readonly property string apiUrl: "https://graphql.anilist.co"
    readonly property string authorizeUrl: "https://anilist.co/api/v2/oauth/authorize"

    property string token: ""
    property bool configured: false
    property bool loading: false
    property string errorText: ""
    property var entries: []

    Process { id: opener }

    function _gql(query, variables, onDone) {
        var xhr = new XMLHttpRequest()
        xhr.timeout = 8000
        xhr.ontimeout = function () { onDone(null) }
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status < 200 || xhr.status >= 300) { onDone(null); return }
            try { onDone(JSON.parse(xhr.responseText)) } catch (e) { onDone(null) }
        }
        xhr.open("POST", tab.apiUrl)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.setRequestHeader("Authorization", "Bearer " + tab.token)
        xhr.send(JSON.stringify({ query: query, variables: variables || {} }))
    }

    function fetchList() {
        if (!tab.configured) return
        tab.loading = true
        tab.errorText = ""

        tab._gql("query { Viewer { id name } }", {}, function (viewerResp) {
            var userId = viewerResp && viewerResp.data && viewerResp.data.Viewer ? viewerResp.data.Viewer.id : null
            if (!userId) {
                tab.loading = false
                tab.errorText = "Konnte AniList-Account nicht laden"
                return
            }

            var listQuery = "query ($userId: Int) { MediaListCollection(userId: $userId, type: ANIME, status: CURRENT) "
                + "{ lists { entries { progress media { title { userPreferred } coverImage { medium } episodes siteUrl } } } } }"

            tab._gql(listQuery, { userId: userId }, function (listResp) {
                tab.loading = false
                var lists = listResp && listResp.data && listResp.data.MediaListCollection
                    ? listResp.data.MediaListCollection.lists : null
                if (!lists) {
                    tab.errorText = "Konnte Watching-Liste nicht laden"
                    return
                }
                var out = []
                for (var i = 0; i < lists.length; i++) {
                    var es = lists[i].entries || []
                    for (var j = 0; j < es.length; j++) {
                        out.push({
                            title: es[j].media.title.userPreferred,
                            cover: es[j].media.coverImage.medium,
                            progress: es[j].progress || 0,
                            episodes: es[j].media.episodes || 0,
                            url: es[j].media.siteUrl
                        })
                    }
                }
                tab.entries = out
            })
        })
    }

    function openEntry(url) {
        if (!url) return
        opener.exec(["xdg-open", url])
    }

    function openAuthorize() {
        opener.exec(["xdg-open", tab.authorizeUrl])
    }

    CredentialsLoader {
        id: creds
        onCredentialsLoaded: {
            tab.token = creds.isPlaceholder(creds.anilistToken, "ANILIST_TOKEN") ? "" : creds.anilistToken
            tab.configured = tab.token.length > 0
            if (tab.configured) tab.fetchList()
        }
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        onTriggered: if (tab.configured) tab.fetchList()
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: !tab.configured
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "AniList nicht konfiguriert"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            opacity: 0.5
            color: tab.textColor
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            radius: 8
            color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, authMouse.containsMouse ? 0.14 : 0.08)
            Layout.preferredWidth: authLabel.implicitWidth + 20
            Layout.preferredHeight: 26

            Text {
                id: authLabel
                anchors.centerIn: parent
                text: "AniList autorisieren"
                font.family: "JetBrains Mono"
                font.pixelSize: 10
                color: tab.textColor
            }

            MouseArea {
                id: authMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tab.openAuthorize()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: tab.configured
        spacing: 6

        Text {
            visible: tab.loading
            text: "Lädt…"
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            opacity: 0.4
            color: tab.textColor
        }

        Text {
            visible: tab.errorText.length > 0
            text: tab.errorText
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            opacity: 0.5
            color: tab.textColor
        }

        Text {
            visible: !tab.loading && tab.errorText.length === 0 && tab.entries.length === 0
            text: "Nichts in Bearbeitung"
            font.family: "JetBrains Mono"
            font.pixelSize: 11
            opacity: 0.4
            color: tab.textColor
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: entryColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: entryColumn
                width: parent.width
                spacing: 2

                Repeater {
                    model: tab.entries

                    Rectangle {
                        id: row
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 6
                        color: rowMouse.containsMouse ? Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.08) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 38
                                radius: 4
                                color: Qt.rgba(tab.textColor.r, tab.textColor.g, tab.textColor.b, 0.1)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: row.modelData.cover
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: row.modelData.cover.length > 0
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.title
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    color: tab.textColor
                                }
                                Text {
                                    text: "Episode " + row.modelData.progress + "/" + (row.modelData.episodes > 0 ? row.modelData.episodes : "?")
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    opacity: 0.5
                                    color: tab.textColor
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tab.openEntry(row.modelData.url)
                        }
                    }
                }
            }
        }
    }
}
