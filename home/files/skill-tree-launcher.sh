#!/usr/bin/env bash
# Öffnet/schließt den Skill Tree (localhost:5173) im Vivaldi-App-Modus —
# SUPER+K togglet, ESC schließt zusätzlich während der Skill Tree fokussiert
# ist (siehe submap "skilltree" in hyprland.conf).
#
# Eigenes --user-data-dir nötig: Vivaldi ist Single-Instance pro Profil (der
# Nutzer hat i.d.R. schon eine Instanz mit --remote-debugging-port=9222 für
# die Vivaldi-MCP-Steuerung offen). Ohne eigenes Profil würde das Fenster nur
# an die laufende Instanz durchgereicht statt eine echte eigene zu öffnen.
#
# --class wird von Vivaldi im --app-Modus ignoriert (live verifiziert) — die
# Fensterklasse wird stattdessen aus der URL abgeleitet: für localhost:5173
# im eigenen Profil konsequent "vivaldi-localhost__-Default". Die Hyprland-
# Windowrule (skill-tree-fullscreen) und dieses Skript matchen deshalb auf
# diese abgeleitete Klasse, nicht auf den --class-Wert unten.
CLASS="vivaldi-localhost__-Default"

is_open() {
  hyprctl clients -j | python3 -c "
import json, sys
clients = json.load(sys.stdin)
sys.exit(0 if any(c['class'] == '$CLASS' for c in clients) else 1)
"
}

if is_open; then
  hyprctl dispatch closewindow "class:$CLASS"
  hyprctl dispatch submap reset
else
  vivaldi \
    --user-data-dir="$HOME/.local/share/skill-tree-vivaldi-profile" \
    --no-first-run --no-default-browser-check \
    --class="skill-tree" \
    --app="http://localhost:5173" &
  hyprctl dispatch submap skilltree
fi
