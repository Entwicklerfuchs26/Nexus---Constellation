#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/sojus"
STATE_FILE="$CACHE_DIR/colorscheme"
OVERRIDE_FILE="$CACHE_DIR/colorscheme-override"
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

# --auto light|dark: vom systemd-Timer aufgerufen, respektiert Override
# ohne Argument: manueller Toggle (Waybar-Klick), setzt Override
if [ "${1:-}" = "--auto" ]; then
    target="${2:?Usage: toggle-theme.sh --auto light|dark}"
    if [ -f "$OVERRIDE_FILE" ]; then
        rm -f "$OVERRIDE_FILE"
        echo "Override aktiv, automatischer Wechsel zu '$target' uebersprungen. Override zurueckgesetzt."
        exit 0
    fi
else
    mode="$(current_mode)"
    if [ "$mode" = "light" ]; then target="dark"; else target="light"; fi
    touch "$OVERRIDE_FILE"
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

wallpaper_path="$(python3 -c "
import json
config = json.load(open('$CONFIG'))
wallpaper_dir = config['paths']['wallpaper']
status = json.loads(__import__('subprocess').check_output(['skwd', 'status']))
print(f\"{wallpaper_dir}/{status['current_wallpaper']}\")
")"
# skwd-daemons interner externalMatugenCommand-Lauf rendert das gtk4-Template
# (letztes Template in ~/.config/matugen/config.toml) nicht zuverlaessig mit,
# vermutlich bricht die interne Kette vorher ab. Deshalb hier explizit und
# vollstaendig selbst rendern, BEVOR skwd wall apply laeuft (das den
# Nautilus-Neustart triggert, der gtk.css erst dann liest).
matugen -c "$HOME/.config/matugen/config.toml" image "$wallpaper_path" \
    --source-color-index 0 -m "$target" -t "$scheme_type" -q

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
