import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Scope {
    id: root

    property bool open: false

    // Waybar blendet sich aus/ein, solange das Dashboard offen ist (SIGUSR1 = toggle,
    // per waybar-Doku Default-Aktion; SIGUSR2 ist bereits fürs Matugen-Reload belegt).
    Process {
        id: waybarToggle
    }
    // QML cached ein Image unter gleichbleibender source-URL, auch wenn sich die
    // Datei auf der Platte ändert (current.jpg wird bei jedem Wallpaper-Wechsel
    // überschrieben) - daher beim Öffnen ein Cache-Busting-Suffix hochzählen.
    property int _wallpaperReloadKey: 0
    onOpenChanged: {
        waybarToggle.exec(["pkill", "-USR1", "waybar"])
        if (root.open) root._wallpaperReloadKey++
    }

    // ── Matugen-Farben (live, reaktiv) ──────────────────────────────────────
    // Gleiche Quelle/Architektur wie die Sidebar (Sidebar.qml).
    QtObject {
        id: colors
        property color surface: "#15130b"
        property color surfaceText: "#e8e2d3"
        property color surfaceVariant: "#4a4739"
        property color surfaceContainer: "#201d13"
        property color outline: "#96917b"
        property color primary: "#c6b22b"
        property color primaryText: "#383100"
        property color secondary: "#c6b22b"
        property color tertiary: "#a9a9ff"
        property color error: "#ba1a1a"
    }

    function _applyColors(text) {
        var trimmed = (text || "").trim()
        if (!trimmed) return
        try {
            var d = JSON.parse(trimmed)
            var pick = function (v, fallback) {
                return (typeof v === "string" && v.length > 0 && v.indexOf("{{") === -1) ? v : fallback
            }
            colors.surface = pick(d.surface, colors.surface)
            colors.surfaceText = pick(d.surfaceText, colors.surfaceText)
            colors.surfaceVariant = pick(d.surfaceVariant, colors.surfaceVariant)
            colors.surfaceContainer = pick(d.surfaceContainer, colors.surfaceContainer)
            colors.outline = pick(d.outline, colors.outline)
            colors.primary = pick(d.primary, colors.primary)
            colors.primaryText = pick(d.primaryText, colors.primaryText)
            colors.secondary = pick(d.secondary, colors.secondary)
            colors.tertiary = pick(d.tertiary, colors.tertiary)
            colors.error = pick(d.error, colors.error)
        } catch (e) {
            console.log("Dashboard: Fehler beim Parsen der Matugen-Farben:", e)
        }
    }

    FileView {
        id: colorsFile
        path: "/home/fuchs/.cache/skwd-wall/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._applyColors(text())
    }

    // ── Toggle per SUPER+D (hyprland.conf) via `quickshell ipc call` ────────
    IpcHandler {
        target: "dashboard"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    Component {
        id: dp1Layout
        GridLayout {
            columns: 2
            rowSpacing: 28
            columnSpacing: 28

            DashboardCard {
                title: "Kalender"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                CalendarWidget { textColor: colors.surfaceText }
            }
            DashboardCard {
                title: "Wetter"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                WeatherWidget { textColor: colors.surfaceText }
            }
            DashboardCard {
                title: "Tasks"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                TasksWidget { textColor: colors.surfaceText; accentColor: colors.primary }
            }
            DashboardCard {
                title: "News Hub"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                NewsHubWidget { textColor: colors.surfaceText; accentColor: colors.primary; accentTextColor: colors.primaryText }
            }
            DashboardCard {
                title: "Sojus Chat"; Layout.columnSpan: 2; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                SojusChatWidget { textColor: colors.surfaceText; accentColor: colors.primary; accentTextColor: colors.primaryText; errorColor: colors.error }
            }

            DashboardCard {
                title: "Uhr & Datum"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                ClockWidget { textColor: colors.surfaceText }
            }
            DashboardCard {
                title: "Updates"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                UpdateWidget { textColor: colors.surfaceText; accentColor: colors.primary; accentTextColor: colors.primaryText; warnColor: colors.tertiary }
            }
            DashboardCard {
                title: "Sojus-Agenten"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                AgentsWidget { textColor: colors.surfaceText; accentColor: colors.primary; errorColor: colors.error }
            }
            DashboardCard {
                title: "Skill Tree"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                SkillTreeWidget { textColor: colors.surfaceText; accentColor: colors.primary; accentTextColor: colors.primaryText }
            }
        }
    }

    Component {
        id: dp3Layout
        ColumnLayout {
            spacing: 28

            DashboardCard {
                id: focusTimeCard
                Layout.fillWidth: true
                Layout.preferredHeight: 610
                title: "FocusTime"; textColor: colors.surfaceText
                color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, focusTimeWidget.cardOpacity)
                border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                FocusTimeWidget {
                    id: focusTimeWidget
                    textColor: colors.surfaceText
                    subTextColor: colors.outline
                    accentColor: colors.primary
                    accent2Color: colors.secondary
                    baseColor: colors.surface
                    boxColor: colors.surfaceContainer
                    peachColor: colors.tertiary
                    cardOpacity: 0.55
                    active: root.open
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                columns: 2
                rowSpacing: 28
                columnSpacing: 28

                DashboardCard {
                    title: "Speicherplatz"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                    DiskWidget { textColor: colors.surfaceText; accentColor: colors.primary; warnColor: colors.tertiary; dangerColor: colors.error }
                }
                DashboardCard {
                    title: "System Usage"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                    SystemUsageWidget {
                        textColor: colors.surfaceText
                        subTextColor: colors.outline
                        accentColor: colors.primary
                        baseColor: colors.surface
                        contrastTextColor: colors.primaryText
                        active: root.open
                    }
                }
            }
        }
    }

    Component {
        id: hdmiLayout
        ColumnLayout {
            spacing: 28

            DashboardCard {
                title: "Zwischenablage"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                ClipboardWidget { textColor: colors.surfaceText }
            }
            DashboardCard {
                title: "Schnellzugriff"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                QuickToolsWidget { textColor: colors.surfaceText; accentColor: colors.primary; accentTextColor: colors.primaryText }
            }
            DashboardCard {
                title: "Now Playing"; textColor: colors.surfaceText; color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 0.65); border.color: Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.15); border.width: 1
                NowPlayingWidget { textColor: colors.surfaceText; accentColor: colors.primary }
            }
        }
    }

    Variants {
        // HDMI-A-1 (XP-Pen-Tablet) ist nicht dauerhaft angeschlossen — Quickshell.screens
        // spiegelt live nur tatsächlich verbundene Outputs, daher reicht der reine
        // Namens-Filter: kein Fenster/keine Widgets, solange der Monitor fehlt.
        model: Quickshell.screens.filter(function (s) { return s.name === "DP-1" || s.name === "DP-3" || s.name === "HDMI-A-1" })

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "nexus-dashboard"
            // Zu: hinter allen Fenstern wenn geschlossen (Bottom), vor allen wenn offen (Overlay).
            WlrLayershell.layer: root.open ? WlrLayer.Overlay : WlrLayer.Bottom
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            color: "transparent"

            // Geschlossen: Maske auf 0x0 -> komplett klick-durchlässig zum Desktop.
            mask: Region {
                x: 0
                y: 0
                width: root.open ? panel.width : 0
                height: root.open ? panel.height : 0
            }

            Shortcut {
                sequence: "Escape"
                enabled: root.open
                onActivated: root.open = false
            }

            Item {
                anchors.fill: parent
                opacity: root.open ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Image {
                    id: wallpaper
                    anchors.fill: parent
                    source: "file:///home/fuchs/.cache/skwd-wall/wallpaper/current.jpg?" + root._wallpaperReloadKey
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 64
                        autoPaddingEnabled: false
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.4)
                }

                Loader {
                    anchors.fill: parent
                    anchors.margins: 48
                    sourceComponent: panel.modelData.name === "DP-1" ? dp1Layout
                        : panel.modelData.name === "DP-3" ? dp3Layout
                        : hdmiLayout
                }
            }
        }
    }
}
