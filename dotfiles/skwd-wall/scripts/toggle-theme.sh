#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/sojus"
STATE_FILE="$CACHE_DIR/colorscheme"
CONFIG="$HOME/.config/skwd-wall/config.json"
LOCK_FILE="$CACHE_DIR/toggle.lock"

mkdir -p "$CACHE_DIR"

# Waehrend ein Wechsel laeuft (mehrere Sekunden) blockieren weitere Aufrufe
# sofort statt zu ueberlappen - verhindert Race-Zustaende zwischen zwei
# gleichzeitigen skwd/matugen-Laeufen.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Wechsel laeuft bereits, ignoriere Aufruf." >&2
    exit 0
fi

current_mode() {
    cat "$STATE_FILE" 2>/dev/null || echo "dark"
}

# --auto light|dark: vom systemd-Timer aufgerufen, schaltet immer (kein Override)
# ohne Argument: manueller Toggle (Waybar-Klick)
if [ "${1:-}" = "--auto" ]; then
    target="${2:?Usage: toggle-theme.sh --auto light|dark}"
else
    mode="$(current_mode)"
    if [ "$mode" = "light" ]; then target="dark"; else target="light"; fi
fi

# scheme-fidelity fuer beide Modi: bleibt nah an den tatsaechlichen
# Wallpaper-Farben (keine kuenstliche Hue-Rotation). scheme-expressive wurde
# verworfen, weil es die Primary-Farbe wallpaper-unabhaengig in Richtung Rot
# schiebt (siehe Feedback: "roter Schleier" trotz gruenem Wallpaper).
case "$target" in
    dark)  scheme_type="scheme-fidelity" ;;
    light) scheme_type="scheme-fidelity" ;;
    *) echo "Unbekannter Modus: $target" >&2; exit 1 ;;
esac

python3 - "$CONFIG" "$target" "$scheme_type" <<'EOF'
import json, sys
path, mode, scheme_type = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    config = json.load(f)
config.setdefault("matugen", {})
config["matugen"]["mode"] = mode
config["matugen"]["schemeType"] = scheme_type
with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
EOF

# "skwd status" liefert current_wallpaper seit einem Daemon-Update
# zuverlaessig als null zurueck. "skwd wall outputs" hat den tatsaechlichen
# Pfad im Feld outputs["*"]["path"], daher direkt von dort lesen.
wallpaper_path="$(python3 -c "
import json, subprocess
outputs = json.loads(subprocess.check_output(['skwd', 'wall', 'outputs']))['outputs']
print(outputs['*']['path'])
")"
# skwd-daemons interner externalMatugenCommand-Lauf rendert das gtk4-Template
# (letztes Template in ~/.config/matugen/config.toml) nicht zuverlaessig mit,
# vermutlich bricht die interne Kette vorher ab. Deshalb hier explizit und
# vollstaendig selbst rendern, BEVOR skwd wall apply laeuft (das den
# Nautilus-Neustart triggert, der gtk.css erst dann liest).
matugen -c "$HOME/.config/matugen/config.toml" image "$wallpaper_path" \
    --source-color-index 0 -m "$target" -t "$scheme_type" -q

# Hyprland liest col.active_border/col.inactive_border nur beim Start aus
# hyprland.conf - fuer Live-Updates ist ein expliziter hyprctl-keyword-Call
# noetig (macht apply-borders.sh). HYPRLAND_INSTANCE_SIGNATURE zur Sicherheit
# selbst setzen, falls dieses Skript mal ohne volle Session-Env laeuft.
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | head -1)}"
bash "$HOME/.config/matugen/apply-borders.sh"

# cava und kitty lesen ihre Config nicht automatisch neu, brauchen SIGUSR1.
pkill -USR1 cava 2>/dev/null || true
pkill -USR1 kitty 2>/dev/null || true

# skwd-daemon liefert beim ersten Apply nach einem Mode-Wechsel manchmal noch
# Farben vom vorherigen Rendering (Race mit der Wallpaper-Transition-Animation).
# Ein zweiter, identischer Call direkt danach ist reproduzierbar korrekt.
skwd wall apply "{\"path\":\"$wallpaper_path\"}" > /dev/null
sleep 0.5
skwd wall apply "{\"path\":\"$wallpaper_path\"}"

echo "$target" > "$STATE_FILE"

# Waybar-Toggle-Modul sofort aktualisieren statt auf den naechsten Poll zu
# warten (signal: 8 im custom/theme-toggle Modul in waybar-config.jsonc).
pkill -RTMIN+8 waybar 2>/dev/null || true

echo "Theme umgeschaltet auf: $target ($scheme_type, Wallpaper: $wallpaper_path)"
