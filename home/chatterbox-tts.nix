# Chatterbox TTS — systemd --user-Service für Sojus' Sprachausgabe.
#
# Warum venv+pip statt Nix-Package (anders als der Rest des Repos, siehe
# comfyui.nix): das PyPI-Paket chatterbox-tts==0.1.7 pinnt torch==2.6.0,
# transformers==5.2.0, diffusers==0.29.0 exakt — Versionen/Pakete, die es in
# nixpkgs (aktuell python3 = 3.14) so nicht gibt. Genau der Grund, warum die
# alte Config auf Docker auswich (siehe archivierte Vorgänger-Version dieses
# Moduls). Statt Docker: ein von `uv` verwalteter venv unter
# ~/.local/share/chatterbox-tts/venv (Python 3.12 für Wheel-Kompatibilität),
# von einem Bootstrap-Skript einmalig eingerichtet.
#
# GPU-Zugriff für den pip-Torch-Build läuft über
# LD_LIBRARY_PATH=/run/opengl-driver/lib (Standard-NixOS-Trick, damit
# unmodifizierte CUDA-Wheels libcuda.so.1 vom Treiber finden).
{ config, pkgs, ... }:

let
  serverScript = pkgs.writeText "chatterbox-tts-server.py" (builtins.readFile ./chatterbox-tts-server.py);

  bootstrap = pkgs.writeShellScriptBin "chatterbox-tts-run" ''
    set -euo pipefail

    DATA_DIR="$HOME/.local/share/chatterbox-tts"
    VENV_DIR="$DATA_DIR/venv"
    MARKER="$VENV_DIR/.install-complete"
    VOICES_DIR="$DATA_DIR/voices"

    mkdir -p "$VOICES_DIR"

    # Referenzstimme einmalig aus der alten devnen/Chatterbox-TTS-Server-
    # Config übernehmen (nur lesen/kopieren, NICHT die alte Checkout
    # anfassen — dort liegen uncommittete, ungesicherte Änderungen).
    SRC_VOICE="/home/fuchs/Chatterbox-TTS-Server/reference_audio/gojo_de_normal.wav"
    DST_VOICE="$VOICES_DIR/default.wav"
    if [ ! -f "$DST_VOICE" ]; then
      if [ -f "$SRC_VOICE" ]; then
        cp "$SRC_VOICE" "$DST_VOICE"
        echo "[chatterbox-tts] Referenzstimme aus alter Chatterbox-TTS-Server-Config übernommen."
      else
        echo "[chatterbox-tts] WARNUNG: keine Default-Referenzstimme gefunden ($SRC_VOICE fehlt). Bitte manuell unter $DST_VOICE ablegen."
      fi
    fi

    if [ ! -d "$VENV_DIR" ]; then
      echo "[chatterbox-tts] Erstelle venv unter $VENV_DIR..."
      ${pkgs.uv}/bin/uv venv --python ${pkgs.python312}/bin/python3.12 "$VENV_DIR"
    fi

    if [ ! -f "$MARKER" ]; then
      echo "[chatterbox-tts] Installiere chatterbox-tts (kann beim ersten Start einige Minuten dauern)..."
      # setuptools<81: chatterbox-tts' Watermarking-Dependency (resemble-perth)
      # importiert noch pkg_resources, das neuere setuptools-Versionen nicht
      # mehr mitbringen (live reproduziert: TypeError beim Instanziieren von
      # PerthImplicitWatermarker, weil der Import lautlos fehlschlägt).
      ${pkgs.uv}/bin/uv pip install --python "$VENV_DIR/bin/python" chatterbox-tts==0.1.7 "setuptools<81" fastapi uvicorn
      touch "$MARKER"
    fi

    # Eigener HF-Cache statt ~/.cache/huggingface: dessen hub/-Unterordner
    # gehört noch root (Altlast des früheren Docker-Setups), fuchs kann dort
    # nicht schreiben. Frisches Verzeichnis vermeidet einen sudo-chown.
    export HF_HOME="$DATA_DIR/hf-cache"
    mkdir -p "$HF_HOME"

    export CHATTERBOX_VOICES_DIR="$VOICES_DIR"
    exec "$VENV_DIR/bin/python" ${serverScript}
  '';
in
{
  home.packages = [ pkgs.uv ];

  systemd.user.services.chatterbox-tts = {
    Unit = {
      Description = "Chatterbox TTS — Sprachausgabe für Sojus";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${bootstrap}/bin/chatterbox-tts-run";
      # nix-ld ist zwar systemweit aktiv (base.nix), setzt NIX_LD_LIBRARY_PATH
      # aber nur für PAM-Login-Sessions — systemd --user-Services bekommen das
      # nicht automatisch. Pip-Torch braucht libstdc++/libgcc aus dem
      # Nix-Store explizit (bringt via nvidia-*-cu12-Wheels seine eigenen
      # CUDA-Libs mit, nur die C++-Runtime fehlt).
      Environment = [
        "LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc pkgs.zlib ]}:/run/opengl-driver/lib"
      ];
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
