#!/usr/bin/env bash
STATE="$HOME/.cache/sojus/workspace-labels.json"
mkdir -p "$(dirname "$STATE")"
[ -f "$STATE" ] || echo '{}' > "$STATE"
export STATE

python3 -c "
import json, os, subprocess
try:
    with open(os.environ['STATE']) as f:
        state = json.load(f)
except Exception:
    state = {}
ws = json.loads(subprocess.run(['hyprctl', 'activeworkspace', '-j'], capture_output=True, text=True).stdout)
ws_id = str(ws.get('id', ''))
label = state.get(ws_id, '')
if label:
    print(json.dumps({'text': label, 'tooltip': f'Workspace {ws_id}: {label}\n(Rechtsklick: löschen)', 'class': 'named'}))
else:
    print(json.dumps({'text': '_', 'tooltip': f'Workspace {ws_id} benennen (Klick)', 'class': 'empty'}))
"
