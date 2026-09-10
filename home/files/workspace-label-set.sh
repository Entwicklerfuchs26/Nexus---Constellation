#!/usr/bin/env bash
set -euo pipefail
STATE="$HOME/.cache/sojus/workspace-labels.json"
mkdir -p "$(dirname "$STATE")"
[ -f "$STATE" ] || echo '{}' > "$STATE"
export STATE

WS_ID=$(hyprctl activeworkspace -j | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
export WS_ID

CURRENT=$(python3 -c "
import json, os
try:
    with open(os.environ['STATE']) as f:
        state = json.load(f)
except Exception:
    state = {}
print(state.get(os.environ['WS_ID'], ''))
")

NEW=$(printf '%s' "$CURRENT" | wofi --dmenu --prompt "Workspace $WS_ID benennen (leer = löschen):") || exit 0
export NEW

python3 -c "
import json, os
try:
    with open(os.environ['STATE']) as f:
        state = json.load(f)
except Exception:
    state = {}
ws_id = os.environ['WS_ID']
new = os.environ.get('NEW', '').strip()
if new:
    state[ws_id] = new
else:
    state.pop(ws_id, None)
with open(os.environ['STATE'], 'w') as f:
    json.dump(state, f)
"

pkill -RTMIN+9 waybar 2>/dev/null || true
