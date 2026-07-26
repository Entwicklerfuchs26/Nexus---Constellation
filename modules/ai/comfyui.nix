{ config, pkgs, lib, ... }:
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
    python3
    git
    gcc
    pkg-config
    libffi
    openssl
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
      fi
      
      source "$VENV_DIR/bin/activate"
      echo "📦 Installiere/aktualisiere Dependencies..."
      pip install --upgrade pip setuptools wheel
      pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
      pip install pillow numpy scipy onnx onnxruntime sqlalchemy pydantic
      pip install -q -r requirements.txt 2>/dev/null || true

      echo "🌐 ComfyUI läuft auf http://localhost:8188"
      python main.py --listen 127.0.0.1 --port 8188
    '')
  ];

  environment.shellAliases = {
    comfyui-start = "start-comfyui";
    comfyui-models = "ls -lh /data/comfyui/checkpoints/";
    comfyui-outputs = "ls -lh /data/comfyui/outputs/";
  };
}
