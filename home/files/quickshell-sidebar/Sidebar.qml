import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Scope {
    id: root

    readonly property int collapsedWidth: 4
    // War 64 (reine Icon-Leiste) - jetzt breiter, damit beim Hover eines einzelnen
    // Icons das Label rechts daneben Platz hat (siehe SidebarButton.qml).
    readonly property int expandedWidth: 180
    readonly property int mediaPanelWidth: 380
    readonly property int mediaPanelHeight: 340

    // App-Shortcuts: hier konfigurierbar (Icon-Theme-Name + Exec-Kommando).
    readonly property var appShortcuts: [
        { iconName: "vivaldi-stable", exec: "vivaldi", tooltip: "Vivaldi" },
        { iconName: "vesktop", exec: "vesktop", tooltip: "Vesktop" },
        { iconName: "org.gnome.Nautilus", exec: "nautilus", tooltip: "Dateien" },
        { iconName: "steam", exec: "steam", tooltip: "Steam" },
        { iconName: "org.prismlauncher.PrismLauncher", exec: "prismlauncher", tooltip: "Prism Launcher" }
    ]

    // Bleibt fixiert (ausgefahren), solange das Media-Panel offen ist - direkt vom
    // ▶-Button getoggelt (kein eww/media-picker mehr, echtes Quickshell-Panel).
    property bool mediaPanelOpen: false

    // ── Matugen-Farben (live, reaktiv) ──────────────────────────────────────
    // Fallback-Palette entspricht skwd-wall/qml/Colors.qml, greift solange
    // matugen noch keinen aktuellen Theme-State geschrieben hat.
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
    }

    function _applyColors(text) {
        var trimmed = (text || "").trim()
        if (!trimmed) return
        try {
            var d = JSON.parse(trimmed)
            // "{{...}}" = matugen-Template noch nicht gerendert -> Fallback behalten.
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
        } catch (e) {
            console.log("Sidebar: Fehler beim Parsen der Matugen-Farben:", e)
        }
    }

    FileView {
        id: colorsFile
        path: "/home/fuchs/.cache/skwd-wall/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._applyColors(text())
    }

    Variants {
        model: Quickshell.screens.filter(function (s) { return s.name === "DP-1" })

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nexus-sidebar"

            anchors {
                top: true
                left: true
                bottom: true
            }

            exclusiveZone: 0
            // Die Wayland-Surface selbst bleibt IMMER auf voller Breite (Sidebar +
            // Media-Panel-Reserve) — animiert wird nur innerhalb per Rectangle-width +
            // Input-Mask. Grund: Bug 1 (Sidebar fährt beim Klicken auf Buttons ein) kam
            // daher, dass ein sich live änderndes implicitWidth auf der echten Layer-Shell-
            // Surface die Hit-Test-Geometrie kurz aus dem Tritt bringt. Mit fixer
            // Surface-Größe passiert jede Animation rein QML-intern, das ist robust -
            // gilt jetzt auch fürs Media-Panel, das aus der Sidebar rechts rausklappt.
            implicitWidth: root.expandedWidth + root.mediaPanelWidth
            color: "transparent"

            property bool hovered: hoverArea.hovered
            property bool expanded: hovered || root.mediaPanelOpen

            // Zwei kombinierte Teilbereiche sind klick-/hoverbar: die Sidebar-Leiste
            // (visualRect, volle Höhe) und - nur wenn offen - das Media-Panel daneben
            // (mediaPanelRect, nur seine eigene Höhe). Alles andere bleibt klick-
            // durchlässig zum Desktop dahinter.
            mask: Region {
                Region { item: visualRect }
                Region { item: mediaPanelRect }
            }

            Rectangle {
                id: visualRect
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: panel.expanded ? root.expandedWidth : root.collapsedWidth
                clip: true
                // Kräftigeres Glassmorphism: höhere Deckkraft + Schatten statt (in Quickshell
                // nicht ohne Weiteres verfügbarem) echtem Backdrop-Blur — in diesem Setup nutzt
                // auch Waybar keinen echten Blur-hinter-Fenstern-Effekt, nur Alpha+Radius.
                color: Qt.rgba(colors.surface.r, colors.surface.g, colors.surface.b, 1.0)
                border.color: Qt.rgba(colors.outline.r, colors.outline.g, colors.outline.b, 0.35)
                border.width: 1
                topRightRadius: 16
                // Unten sitzt die Leiste direkt am Bildschirmrand -> keine Rundung,
                // sonst wirkt sie dort "abgeschnitten"/schwebend statt flächenbündig.
                bottomRightRadius: 0

                onWidthChanged: panel.mask.changed()

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                Behavior on color { ColorAnimation { duration: 200 } }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, 0.5)
                    shadowBlur: 0.6
                    shadowHorizontalOffset: 2
                    shadowVerticalOffset: 0
                }

                // HoverHandler statt MouseArea: eine MouseArea würde von den
                // MouseAreas der SidebarButtons "verdeckt" (containsMouse wird an
                // deren Position false), HoverHandler ist genau für dieses
                // koexistierende Hover-Tracking gemacht und bleibt über der
                // gesamten Fläche zuverlässig aktiv, auch über den Buttons.
                HoverHandler {
                    id: hoverArea
                }

                ColumnLayout {
                    id: content
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 12
                    anchors.leftMargin: 12
                    width: root.expandedWidth - 24
                    spacing: 6
                    opacity: panel.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    SidebarButton {
                        Layout.alignment: Qt.AlignLeft
                        glyph: "🏠"
                        tooltipText: "Dashboard"
                        hoverColor: colors.primary
                        foregroundColor: colors.primary
                        labelColor: colors.surfaceText
                        onClicked: Quickshell.execDetached(["notify-send", "Dashboard", "Noch nicht implementiert"])
                    }

                    SidebarButton {
                        Layout.alignment: Qt.AlignLeft
                        glyph: "▶"
                        tooltipText: "Media Player"
                        hoverColor: colors.primary
                        foregroundColor: colors.primary
                        labelColor: colors.surfaceText
                        onClicked: root.mediaPanelOpen = !root.mediaPanelOpen
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignLeft
                        Layout.topMargin: 4
                        Layout.bottomMargin: 4
                        Layout.preferredWidth: 28
                        height: 1
                        color: colors.outline
                        opacity: 0.4
                    }

                    Repeater {
                        model: root.appShortcuts

                        SidebarButton {
                            required property var modelData
                            Layout.alignment: Qt.AlignLeft
                            iconName: modelData.iconName
                            tooltipText: modelData.tooltip
                            hoverColor: colors.primary
                            labelColor: colors.surfaceText
                            onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exec", modelData.exec])
                        }
                    }
                }
            }

            MediaPanel {
                id: mediaPanelRect
                anchors.top: parent.top
                anchors.topMargin: 58
                x: root.expandedWidth
                width: root.mediaPanelOpen ? root.mediaPanelWidth : 0
                height: root.mediaPanelHeight
                visible: width > 0
                clip: true

                onWidthChanged: panel.mask.changed()
                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                textColor: colors.surfaceText
                accentColor: colors.primary
                accentTextColor: colors.primaryText
                surfaceColor: colors.surface
                outlineColor: colors.outline
            }
        }
    }
}
