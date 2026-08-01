#!/usr/bin/env python3
"""Nexus Equalizer — schreibt die PipeWire-filter-chain-Config mit neuen
Band-Gains und laedt PipeWire neu. Bewusst kein Live-Reglern-Ansatz: die
pw-cli-Props-Live-Kontrolle fuer filter-chain-Controls hat sich als nicht
zuverlaessig erwiesen, daher "Anwenden"-Button-Modell mit kurzer
Audio-Unterbrechung (~1-2s) beim Neuladen.

Aufruf: eq_apply.py <g1> <g2> ... <g10> [--preset <name>]
Gains in dB fuer die Baender 31/63/125/250/500/1000/2000/4000/8000/16000 Hz.
"""
import json
import os
import subprocess
import sys

BANDS = [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

CONF_PATH = os.path.expanduser("~/.config/pipewire/pipewire.conf.d/99-equalizer.conf")
STATE_DIR = os.path.expanduser("~/.local/state/nexus-eq")
STATE_PATH = os.path.join(STATE_DIR, "state.json")


def render_config(gains):
    nodes = []
    links = []
    for ch in ("L", "R"):
        for i, (freq, gain) in enumerate(zip(BANDS, gains), start=1):
            name = f"eq_b{i}_{ch}"
            nodes.append(
                f'                    {{ type = builtin, name = {name}, label = bq_peaking, '
                f'control = {{ Freq = {freq}, Q = 1.0, Gain = {gain} }} }}'
            )
        for i in range(1, len(BANDS)):
            links.append(
                f'                    {{ output = "eq_b{i}_{ch}:Out"  input = "eq_b{i + 1}_{ch}:In" }}'
            )

    nodes_str = "\n".join(nodes)
    links_str = "\n".join(links)
    last = len(BANDS)

    return f"""context.modules = [
    {{   name = libpipewire-module-filter-chain
        args = {{
            node.description = "Nexus Equalizer"
            media.name       = "Nexus Equalizer"
            filter.graph = {{
                nodes = [
{nodes_str}
                ]
                links = [
{links_str}
                ]
                inputs  = [ "eq_b1_L:In"  "eq_b1_R:In" ]
                outputs = [ "eq_b{last}_L:Out" "eq_b{last}_R:Out" ]
            }}
            audio.channels = 2
            audio.position = [ FL FR ]
            capture.props = {{
                node.name        = "nexus_eq_input"
                node.description = "Nexus Equalizer"
                media.class       = "Audio/Sink"
                audio.channels    = 2
                audio.position    = [ FL FR ]
            }}
            playback.props = {{
                node.name      = "nexus_eq_output"
                node.passive   = true
                audio.channels = 2
                audio.position = [ FL FR ]
            }}
        }}
    }}
]
"""


def main():
    args = sys.argv[1:]
    preset = "Custom"
    if "--preset" in args:
        idx = args.index("--preset")
        preset = args[idx + 1]
        args = args[:idx] + args[idx + 2:]

    if len(args) != len(BANDS):
        print(f"Erwarte {len(BANDS)} Gain-Werte, bekam {len(args)}", file=sys.stderr)
        sys.exit(1)
    gains = [float(a) for a in args]

    os.makedirs(os.path.dirname(CONF_PATH), exist_ok=True)
    with open(CONF_PATH, "w") as f:
        f.write(render_config(gains))

    os.makedirs(STATE_DIR, exist_ok=True)
    with open(STATE_PATH, "w") as f:
        json.dump({"gains": gains, "preset": preset}, f)

    subprocess.run(
        ["systemctl", "--user", "restart", "pipewire", "pipewire-pulse", "wireplumber"],
        check=False,
    )
    print("ok")


if __name__ == "__main__":
    main()
