{ config, pkgs, lib, ... }:
let
  pythonWithDeps = pkgs.python310.withPackages (ps: with ps; [
    pip setuptools wheel
  ]);

in {
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
    '';
  };

  environment.systemPackages = with pkgs; [
    python310
    git
    gcc
    pkg-config
    libffi
    openssl
    cudaPackages.cudatoolkit
    cudaPackages.nccl
    libGL
    (writeShellScriptBin "start-comfyui" ''
      #!/usr/bin/env bash
      COMFYUI_DIR="/data/comfyui"
      VENV_DIR="$COMFYUI_DIR/venv"
      
      if [ ! -d "$COMFYUI_DIR" ]; then
        echo "❌ ComfyUI nicht installiert"
        exit 1
      fi

      cd "$COMFYUI_DIR"
      
      if [ ! -d "$VENV_DIR" ]; then
        echo "📦 Erstelle venv..."
        python3 -m venv "$VENV_DIR"
        source "$VENV_DIR/bin/activate"
        pip install --upgrade pip
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
        pip install pillow numpy scipy onnx onnxruntime
      else
        source "$VENV_DIR/bin/activate"
      fi

      echo "🌐 ComfyUI: http://localhost:8188"
      python main.py --listen 127.0.0.1 --port 8188
    '')
  ];

  environment.shellAliases = {
    comfyui-start = "start-comfyui";
    comfyui-models = "ls -lh /data/comfyui/checkpoints/";
    comfyui-outputs = "ls -lh /data/comfyui/outputs/";
  };
}
