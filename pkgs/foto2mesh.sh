#!/usr/bin/env bash
# foto2mesh – Fotos in einem Ordner → texturiertes 3D-Modell (Meshroom/CUDA via Docker)
# Deklarativ via NixOS (modules/software/software.nix). Braucht docker (virtualisation.docker).
# Nutzung:
#   cd <ordner-mit-fotos>
#   foto2mesh                 # alle Bilder im aktuellen Ordner
#   foto2mesh <ordner>        # anderer Ordner
#   foto2mesh <ordner> <out>  # eigenes Ausgabe-Ziel
#   DRAFT=1 foto2mesh         # grob & schnell
set -euo pipefail

IMG_DIR="${1:-$PWD}"
IMG_DIR="$(cd "$IMG_DIR" && pwd)"
OUT="${2:-$IMG_DIR/mesh_output}"
IMAGE="alicevision/meshroom:2025.1.0-av3.3.0-ubuntu22.04-cuda12.1.1"

mapfile -t IMGS < <(find "$IMG_DIR" -maxdepth 1 -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \))
N=${#IMGS[@]}
if (( N < 10 )); then
  echo "❌ Nur $N Bilder in $IMG_DIR (mindestens ~10–20 nötig). Liegen die Fotos direkt im Ordner?"
  exit 1
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "ℹ️  Meshroom-Image fehlt – lade es einmalig (~17 GB) ..."
  docker pull "$IMAGE"
fi

mkdir -p "$OUT" "$IMG_DIR/.meshroom_cache"

DOWNSCALE_ARGS=()
if [[ "${DRAFT:-0}" == "1" ]]; then
  DOWNSCALE_ARGS=(--paramOverrides "FeatureExtraction.1:describerPreset=low")
  echo "⚡ DRAFT-Modus: grob & schnell"
fi

echo "📸 $N Bilder → Meshroom (RTX/CUDA). Dauer je nach Menge Minuten bis ~1 Std."
echo "   Eingabe: $IMG_DIR"
echo "   Ausgabe: $OUT"

docker run --rm --device nvidia.com/gpu=all \
  -v "$IMG_DIR":/input:ro \
  -v "$OUT":/output \
  -v "$IMG_DIR/.meshroom_cache":/cache \
  "$IMAGE" \
  /opt/Meshroom_bundle/meshroom_batch --input /input --output /output --cache /cache "${DOWNSCALE_ARGS[@]}"

echo ""
echo "✅ Fertig! Modell: $OUT/texturedMesh.obj"
echo "   In Blender öffnen:  File → Import → Wavefront (.obj)"
