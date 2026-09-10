#!/usr/bin/env bash
set -euo pipefail
STATE="$HOME/.cache/sojus/workspace-labels.json"
[ -f "$STATE" ] || exit 0
export STATE

WS_ID=$(hyprctl activeworkspace -j | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
export WS_ID

python3 -c "
import json, os
try:
    with open(os.environ['STATE']) as f:
        state = json.load(f)
except Exception:
    state = {}
state.pop(os.environ['WS_ID'], None)
with open(os.environ['STATE'], 'w') as f:
    json.dump(state, f)
"

pkill -RTMIN+9 waybar 2>/dev/null || true
