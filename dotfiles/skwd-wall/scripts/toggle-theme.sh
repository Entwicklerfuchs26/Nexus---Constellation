#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="$HOME/.cache/sojus"
STATE_FILE="$CACHE_DIR/colorscheme"
OVERRIDE_FILE="$CACHE_DIR/colorscheme-override"
CONFIG="$HOME/.config/skwd-wall/config.json"

mkdir -p "$CACHE_DIR"

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

case "$target" in
    dark)  scheme_type="scheme-fidelity" ;;
    light) scheme_type="scheme-expressive" ;;
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
# skwd-daemon liefert beim ersten Apply nach einem Mode-Wechsel manchmal noch
# Farben vom vorherigen Rendering (Race mit der Wallpaper-Transition-Animation).
# Ein zweiter, identischer Call direkt danach ist reproduzierbar korrekt.
skwd wall apply "{\"path\":\"$wallpaper_path\"}" > /dev/null
sleep 0.5
skwd wall apply "{\"path\":\"$wallpaper_path\"}"

echo "$target" > "$STATE_FILE"
echo "Theme umgeschaltet auf: $target ($scheme_type, Wallpaper: $wallpaper_path)"
