{ config, pkgs, lib, ... }:
let
  python = pkgs.python3.withPackages (ps: with ps; [
    torch
    torchvision
    torchaudio
    pillow
    numpy
    scipy
    onnx
    onnxruntime
    sqlalchemy
    pydantic
    pyyaml
    alembic
    requests
    aiohttp
    psutil
    imageio
    imageio-ffmpeg
    tqdm
    websockets
    soundfile
    librosa
  ]);
in
{
  system.activationScripts.comfyuiSetup = {
    text = ''
      COMFYUI_DIR=/data/comfyui
      
      if [ ! -d "$COMFYUI_DIR" ]; then
        echo "[ComfyUI] Initialisiere $COMFYUI_DIR..."
        mkdir -p "$COMFYUI_DIR"
        cd "$COMFYUI_DIR"
        ${pkgs.git}/bin/git clone https://github.com/comfyanonymous/ComfyUI.git .
        mkdir -p checkpoints loras custom_nodes outputs input
      fi
      chown -R fuchs:users "$COMFYUI_DIR"
    '';
  };

  environment.systemPackages = with pkgs; [
    python
    git
    libGL
    ffmpeg
    (writeShellScriptBin "start-comfyui" ''
      #!/usr/bin/env bash
      COMFYUI_DIR="/data/comfyui"
      
      if [ ! -d "$COMFYUI_DIR" ]; then
        echo "❌ ComfyUI nicht installiert"
        exit 1
      fi

      cd "$COMFYUI_DIR"
      echo "🌐 ComfyUI läuft auf http://localhost:8188"
      ${python}/bin/python main.py --listen 127.0.0.1 --port 8188
    '')
  ];

  environment.shellAliases = {
    comfyui-start = "start-comfyui";
    comfyui-models = "ls -lh /data/comfyui/checkpoints/";
    comfyui-outputs = "ls -lh /data/comfyui/outputs/";
  };
}
