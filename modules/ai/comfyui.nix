# ComfyUI — On-Demand Bildgenerierung (Ziel: Pony Diffusion XL, RTX 2070 8GB)
#
# Kein systemd-Service, kein venv: nur ein Python mit withPackages + ein
# Start-Skript. Modul komplett entfernbar, indem der Import in flake.nix
# rausgenommen wird — /data/comfyui (Repo + Modelle) bleibt davon unberührt.
#
# Warum kein einfaches "pip install -r requirements.txt" bzw. venv:
# Dieser ComfyUI-Checkout hat harte Abhängigkeiten auf PyPI-Pakete, die es
# in nixpkgs nicht gibt (siehe unten, v.a. comfy-aimdo). Statt venv/pip
# packen wir genau diese Lücken als eigene buildPythonPackage-Derivationen
# (aus den offiziellen PyPI-Wheels, Hashes unten geprüft) und hängen sie an
# ein normales withPackages-Python. ComfyUI selbst (comfy/, comfy_api/,
# comfy_execution/, app/, ...) bleibt ein reiner Git-Checkout — das sind
# keine PyPI-Pakete, sondern Module direkt im Repo-Root, die main.py über
# sys.path[0] (Verzeichnis von main.py) automatisch findet. PYTHONPATH wird
# im Start-Skript trotzdem explizit gesetzt, siehe Kommentar dort.
{ config, pkgs, lib, ... }:

let
  comfyuiDir = "/data/comfyui";

  # Eigener pkgs-Satz mit cudaSupport=true, exakt das Muster aus
  # whisper-stt.nix: torch/torchvision/torchaudio brauchen echte
  # CUDA-Kernels, das aber nicht global in nixpkgs.config erzwingen (würde
  # unbeteiligte Pakete wie OBS/ffmpeg-Codecs neu bauen, siehe nvidia.nix).
  pkgsCuda = import pkgs.path {
    inherit (pkgs) system;
    config = pkgs.config // { cudaSupport = true; };
  };

  py = pkgsCuda.python3;
  pyPkgs = py.pkgs;

  # comfy-aimdo: HARTE, ungeschützte Abhängigkeit von ComfyUI selbst — kein
  # optionales Extra. comfy/model_management.py, comfy/ops.py,
  # comfy/model_patcher.py, comfy/utils.py, execution.py, main.py u.a. machen
  # alle "import comfy_aimdo.xxx" auf Modul-Ebene ohne try/except. Ohne dieses
  # Paket startet ComfyUI in dieser Version gar nicht erst (ImportError schon
  # beim Import von comfy.model_management). Es ist gleichzeitig genau das
  # Feature, das dynamisches VRAM-Management liefert und ein SDXL/Pony-Modell
  # überhaupt sauber auf 8GB laufen lässt — also kein Umweg, sondern der Punkt.
  #
  # Technisch ein reines ctypes-Paket: aimdo.so wird zur Laufzeit von
  # comfy_aimdo/control.py per ctypes.CDLL(..., mode=RTLD_NOW|RTLD_GLOBAL)
  # nachgeladen, ist also keine Python-C-Extension im klassischen Sinn. Laut
  # ELF-Analyse braucht die .so nur libc/libdl/libpthread (kein CUDA-Toolkit
  # als Build-Input nötig) — die eigentliche GPU-Arbeit läuft über den von
  # torch bereits initialisierten CUDA-Kontext. addDriverRunpath ist trotzdem
  # dabei, falls eine künftige Version doch libcuda.so.1 direkt dlopen't.
  comfy-aimdo = pyPkgs.buildPythonPackage rec {
    pname = "comfy-aimdo";
    version = "0.4.10";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/3e/63/29035f15a32c1e31723585c452c7416d6c3c00f92469e2a923a35500df49/comfy_aimdo-${version}-cp39-abi3-manylinux2010_x86_64.manylinux2014_x86_64.manylinux_2_12_x86_64.manylinux_2_17_x86_64.whl";
      sha256 = "ffae0519a8c37751e1097e8275a3450a5b8bee9aeb179b5da0c00fcb57a2cc5f";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.addDriverRunpath ];
    doCheck = false;
    pythonImportsCheck = [ "comfy_aimdo.control" ];
  };

  # comfyui-frontend-package: die kompilierte Web-UI (statisches JS/CSS-
  # Bundle). Ebenfalls harte Abhängigkeit — app/frontend_management.py ruft
  # ohne dieses Paket sys.exit(-1) auf, bevor der Server überhaupt hochkommt.
  # Reines Datenpaket, kein natives .so.
  comfyui-frontend-package = pyPkgs.buildPythonPackage rec {
    pname = "comfyui-frontend-package";
    version = "1.47.10";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/cd/72/3c87f0fb5a0c122b4e9891b4a2b354d9d3dc618ea46569c79a1f0499204b/comfyui_frontend_package-${version}-py3-none-any.whl";
      sha256 = "9a579e1cd40406a364f2207c8b480a4a9ab5b76e7478e16e927acb9a15d8d1bf";
    };
    doCheck = false;
    pythonImportsCheck = [ "comfyui_frontend_package" ];
  };

  # spandrel: optional, aber praktisch kostenlos. comfy_extras/nodes_upscale_
  # model.py importiert es NICHT geschützt, aber ComfyUIs Node-Loader fängt
  # das pro Nodegroup ab (nur "IMPORT FAILED" im Log, Rest startet normal).
  # Ohne spandrel fehlen nur die Upscale-Model-Nodes. Reines Python, alle
  # Abhängigkeiten (torch, torchvision, safetensors, numpy, einops) stehen
  # schon in nixpkgs.
  spandrel = pyPkgs.buildPythonPackage rec {
    pname = "spandrel";
    version = "0.4.2";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/74/31/411ea965835534c43d4b98d451968354876e0e867ea1fd42669e4cca0732/spandrel-${version}-py3-none-any.whl";
      sha256 = "6c93e3ecbeb0e548fd2df45a605472b34c1614287c56b51bb33cdef7ae5235b5";
    };
    propagatedBuildInputs = with pyPkgs; [
      torch
      torchvision
      safetensors
      numpy
      einops
      typing-extensions
    ];
    doCheck = false;
    pythonImportsCheck = [ "spandrel" ];
  };

  # Bewusst NICHT gepackt:
  # - comfy-kitchen: FP8/FP4-Quantisierungs-Kernels für CUDA (comfy/quant_ops.py,
  #   comfy/float.py — beide try/except, Paket ist optional). Turing (RTX 2070,
  #   Compute Capability 7.5) hat keine FP8-Tensor-Cores, das Backend würde auf
  #   dieser Karte ohnehin nie aktiv werden. Bräuchte außerdem eine echte CUDA-
  #   Erweiterung mit eigener Treiber-Verlinkung (addDriverRunpath) für nichts.
  # - comfy-angle: nur für die GLSL-Shader-Nodes (comfy_extras/nodes_glsl.py),
  #   optional, würde zusätzlich libGLESv2/libEGL + X11-Libs brauchen.
  # - comfyui-workflow-templates / comfyui-embedded-docs: beide optional
  #   (Beispiel-Workflow-Galerie bzw. eingebettete Doku-Tooltips im Frontend,
  #   app/frontend_management.py loggt nur eine Warnung ohne sie).
  #   comfyui-workflow-templates zieht zudem 6 weitere PyPI-Pakete mit
  #   Medien-Assets nach — für reinen Pony-XL-Betrieb unnötiger Ballast.

  python = py.withPackages (ps: with ps; [
    torch
    torchvision
    torchaudio
    torchsde
    numpy
    pillow
    scipy
    einops
    transformers
    tokenizers
    sentencepiece
    safetensors
    pyyaml
    alembic
    sqlalchemy
    requests
    aiohttp
    yarl
    filelock
    av
    psutil
    tqdm
    simpleeval
    blake3
    kornia
    pydantic
    pydantic-settings
    pyopengl
    comfy-aimdo
    comfyui-frontend-package
    spandrel
  ]);
in
{
  # Repo nur klonen, wenn es noch nicht existiert. Keine models/-Unterordner
  # anlegen — die bringt der Git-Checkout schon mit (folder_paths.py erwartet
  # sie unter comfyuiDir/models/checkpoints, .../loras, .../vae, ...), Ordner
  # für output/input/user/temp legt ComfyUI beim ersten Start selbst an.
  # chown läuft nur direkt nach dem Klonen, nicht bei jedem Rebuild — bei
  # mehreren GB an Checkpoints wäre ein "chown -R" auf jedem activation
  # unnötig teuer.
  system.activationScripts.comfyuiSetup = {
    text = ''
      if [ ! -d "${comfyuiDir}/.git" ]; then
        echo "[ComfyUI] Initialisiere ${comfyuiDir}..."
        mkdir -p "${comfyuiDir}"
        ${pkgs.git}/bin/git clone https://github.com/comfyanonymous/ComfyUI.git "${comfyuiDir}"
        chown -R fuchs:users "${comfyuiDir}"
      fi
    '';
  };

  environment.systemPackages = with pkgs; [
    python
    git
    libGL
    ffmpeg
    (writeShellScriptBin "start-comfyui" ''
      #!/usr/bin/env bash
      set -e
      COMFYUI_DIR="${comfyuiDir}"

      if [ ! -d "$COMFYUI_DIR/.git" ]; then
        echo "❌ ComfyUI nicht installiert (nixos-rebuild switch fehlt noch)"
        exit 1
      fi

      # ComfyUI findet seine eigenen Module (comfy, comfy_api, comfy_execution,
      # app, ...) über sys.path[0], also das Verzeichnis von main.py — das
      # passiert automatisch beim direkten Aufruf "python main.py" aus
      # COMFYUI_DIR heraus. PYTHONPATH hier trotzdem explizit setzen, robust
      # falls main.py mal über -m oder einen Symlink gestartet wird.
      export PYTHONPATH="$COMFYUI_DIR''${PYTHONPATH:+:$PYTHONPATH}"

      # Reduziert VRAM-Fragmentierung bei Modellwechseln auf der 8GB-Karte.
      export PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

      cd "$COMFYUI_DIR"
      echo "🌐 ComfyUI läuft auf http://127.0.0.1:8188"
      # --reserve-vram: GPU wird auch vom Desktop (Hyprland) genutzt, 1GB
      # Reserve lassen. Per Aufruf überschreibbar, z.B.:
      #   start-comfyui --reserve-vram 0.5
      exec ${python}/bin/python main.py \
        --listen 127.0.0.1 --port 8188 \
        --reserve-vram 1.0 \
        "$@"
    '')
  ];

  environment.shellAliases = {
    comfyui-start = "start-comfyui";
    comfyui-models = "ls -lh /data/comfyui/models/checkpoints/";
    comfyui-outputs = "ls -lh /data/comfyui/output/";
  };
}
