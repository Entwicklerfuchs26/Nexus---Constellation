{ config, pkgs, ... }:

{
  # Community-Binary-Cache für CUDA-Pakete (cache.nixos.org baut keine CUDA-Varianten).
  # cudaSupport selbst wird NICHT global gesetzt — das würde den gesamten System-pkgs-Satz
  # umstellen und unbeteiligte Pakete wie OBS/ffmpeg-Codecs neu bauen. Stattdessen importiert
  # whisper-stt.nix sich einen eigenen, lokal auf cudaSupport=true gestellten pkgs-Satz.
  # Details: https://wiki.nixos.org/wiki/CUDA
  nix.settings = {
    substituters = [ "https://cache.nixos-cuda.org" ];
    trusted-public-keys = [ "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=" ];
  };

  # NVIDIA Treiber aktivieren
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Stabiler proprietärer Treiber
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Persistenzmodus (09.11.2026): Treiber bleibt geladen, kein Neu-Initialisieren
  # zwischen GPU-Jobs (kürzere Startzeit für CUDA/ComfyUI).
  hardware.nvidia.nvidiaPersistenced = true;

  # Power-Limit auf das Karten-Maximum (RTX 2070 SUPER: Standard 215 W, max 240 W laut
  # nvidia-smi). Innerhalb der Herstellergrenze, setzt sich bei jedem Boot neu.
  # "-" vor dem Befehl: schlägt es fehl, bricht der Boot NICHT ab.
  systemd.services.nvidia-power-limit = {
    description = "NVIDIA Power-Limit auf Maximum";
    wantedBy = [ "multi-user.target" ];
    after = [ "nvidia-persistenced.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "-${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 240";
    };
  };

  # Wayland mit NVIDIA sauber konfigurieren
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Umgebungsvariablen für NVIDIA und Wayland
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
