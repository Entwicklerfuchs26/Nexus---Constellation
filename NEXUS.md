# Nexus — Desktop-Übersicht

Stand: 2026-07-24. NixOS-Flake-Konfiguration für den Hyprland-Desktop "nexus" (AMD Ryzen 7 3700X, RTX 2070 SUPER, 3 Monitore: DP-1 fest, DP-3 + HDMI-A-1 intermittierend angeschlossen).

## Was läuft wo

| Komponente | Technik | Autostart | Config-Quelle |
|---|---|---|---|
| Dashboard (Fullscreen-Overlay, SUPER+D) | Quickshell (`nexus-dashboard`) | `exec-once` in hyprland.conf | `home/files/quickshell-dashboard/` |
| Sidebar (App-Shortcuts, Hover-Ausklappen) | Quickshell (`nexus-sidebar`) | `exec-once` in hyprland.conf | `home/files/quickshell-sidebar/` |
| Waybar (Statusleiste oben) | eigener Prozess, ein Binary für alle Outputs | `exec-once` in hyprland.conf | `home/files/waybar-config.jsonc` + `waybar-style.css.templ` |
| Wallpaper/Theme | `awww-daemon` + `skwd-paper` (skwd-wall) | `exec-once` | `dotfiles/skwd-wall/` |
| ActivityWatch | `aw-server` (Rust) + `aw-watcher-afk` + `aw-watcher-window` | systemd `--user`, `WantedBy=graphical-session.target` | `home/activitywatch.nix` |

Alle drei Quickshell-/Waybar-Prozesse laufen **einmal** und bedienen automatisch jeden verbundenen Monitor (kein Prozess pro Output) — außer bei Hotplug-Problemen, siehe „Offene Punkte".

## Dashboard-Widgets

**DP-1** (2-Spalten-Grid):

| Widget | Datei | Datenquelle |
|---|---|---|
| Kalender | CalendarWidget.qml | CalDAV REPORT via `curl`/Process gegen mehrere Nextcloud-Kalender (`CALDAV_*`) |
| Tasks | TasksWidget.qml + TaskRow.qml | Vikunja REST API (`VIKUNJA_*`) |
| News Hub | NewsHubWidget.qml | n8n-Webhooks pro Tab (`NEWS_TAB_n_*`) |
| Sojus Chat | SojusChatWidget.qml | Sojus Core `/v1/chat/completions` (OpenAI-kompatibel) |
| System-Monitor | SystemMonitorWidget.qml + DonutRing.qml | `/proc/stat`, hwmon (k10temp), `nvidia-smi`, `/proc/meminfo` |

**DP-3** (2-Spalten-Grid):

| Widget | Datei | Datenquelle |
|---|---|---|
| Netzwerk | NetworkWidget.qml | `/proc/net/dev`-Delta, `nmcli` |
| Speicherplatz | DiskWidget.qml | `df -h` (/, /home, /mnt/\*, /run/media/\*) |
| Updates | UpdateWidget.qml | `nix flake metadata --json`, Button für `nix flake update` |
| Sojus-Agenten | AgentsWidget.qml | Sojus Core `/health` (zeigt MCP-Server-Status, kein Tasks/Jobs-Endpoint vorhanden) |
| Activity | ActivityWidget.qml | ActivityWatch REST API (`localhost:5600`) |

**HDMI-A-1** (nur wenn Monitor verbunden, automatisch per `Quickshell.screens`-Filter):

| Widget | Datei | Datenquelle |
|---|---|---|
| Zwischenablage | ClipboardWidget.qml | `cliphist list` / `decode` |
| Schnellzugriff | QuickToolsWidget.qml | `grimblast`, `hyprpicker`, Pomodoro-Timer (rein QML) |
| Now Playing | NowPlayingWidget.qml | `playerctl` |

Gemeinsame Bausteine: `DashboardCard.qml` (Karten-Rahmen), `CredentialsLoader.qml` (liest credentials.env), Farben aus `~/.cache/skwd-wall/colors.json` (live, per `FileView`).

## Credentials-Struktur

Datei: `~/.config/nexus/credentials.env` — **nicht** git-getrackt, **nicht** über home-manager verwaltet (reine Laufzeit-Datei, `chmod 600`). Wird per `FileView` mit `watchChanges: true` gelesen — Änderungen greifen automatisch, kein Quickshell-Neustart nötig (seit 2026-07-24).

```
CALDAV_URL=              # Nextcloud-Origin, OHNE Pfad
CALDAV_CALENDARS=        # kommagetrennte Kalender-Hrefs (von nc_calendar_list_calendars)
CALDAV_USER=
CALDAV_PASSWORD=
VIKUNJA_URL=
VIKUNJA_API_TOKEN=
NEWS_TAB_1_NAME= / NEWS_TAB_1_URL=   # bis NEWS_TAB_20, dynamisch erkannt
SKILLTREE_URL=
SKILLTREE_LOCAL_CMD=
```

Plan: perspektivisch durch agenix ersetzt — Ladeweg (FileView auf einen realen Dateipfad) bleibt dabei kompatibel.

## Keybinds (Auszug, hyprland.conf)

| Bind | Aktion |
|---|---|
| `SUPER+D` | Dashboard toggle (Quickshell IPC) |
| `SUPER+T` | Light/Dark-Theme-Toggle (skwd-wall) |
| `SUPER+N` / `SUPER+SHIFT+N` | Nix-Manager / Notification-Center |
| `SUPER+P` | Media-Toggle |
| `SUPER+S` | Screenshot (grim+slurp) |
| `SUPER+1..0` | Workspace 1–10 wechseln |
| `SUPER+SHIFT+1..0` | Fenster auf Workspace 1–10 verschieben |
| `SUPER+Q/C/F/V/R` | Terminal / Fenster schließen / Fullscreen / Floating / App-Launcher |

## Widgets ohne Rebuild neu starten

Reine `.qml`-Änderungen (kein `.nix` angefasst):

```bash
pkill -f "quickshell.*nexus-dashboard" && hyprctl dispatch exec "quickshell -c nexus-dashboard -n -d"
pkill -f "quickshell.*nexus-sidebar"   && hyprctl dispatch exec "quickshell -c nexus-sidebar -n -d"
```

**Nie** `setsid`/direkter Hintergrundstart aus einer Sandbox-Shell heraus — der Prozess braucht die echte Hyprland-Session-Umgebung, sonst fehlen Wayland-Variablen. Immer über `hyprctl dispatch exec`.

`credentials.env`-Änderungen brauchen **gar keinen** Neustart mehr (FileView-Watcher).

Bei `.nix`-Änderungen (neue Widget-Datei, neues Paket, neuer systemd-Service): `sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#nexus` — braucht ein interaktives Terminal, läuft nie automatisiert durch.

**Neue Widget-Datei anlegen:** immer 3 Schritte — `.qml` in `home/files/quickshell-dashboard/`, `git add` (Flake sieht nur getrackte Dateien), Zeile in `home/quickshell-dashboard.nix` ergänzen (kein Glob, jede Datei einzeln gelistet — schon zweimal vergessen worden, siehe Git-Historie).

## Was noch offen ist

Offene Punkte werden seit 24.08.2026 nicht mehr hier gepflegt, sondern als
Tasks im Vikunja-Projekt **"Nexus"** getrackt (Teil von IT → Eigene Hosts).
Diese Datei bleibt die Architektur-/Ist-Zustand-Doku; Vikunja ist die
Aufgabenliste dazu — auch für Sojus/Claude Code selbst gilt: bei
Nexus-Desktop-Themen dort nachschauen statt eine eigene Liste hier zu
führen.
