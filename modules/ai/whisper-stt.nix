# Whisper STT — Spracherkennung für Sojus (Voice Layer, Schritt 4)
# whisper.cpp (ggml/CUDA) statt faster-whisper/ctranslate2: Letzteres zieht bei diesem
# nixpkgs-Stand (Python 3.14) eine riesige unkassierte Kompilierkaskade nach sich
# (torch, opencv, openvino, magma). whisper.cpp mit CUDA ist exakt im
# cache.nixos-cuda.org-Cache getroffen (siehe nvidia.nix) und bringt mit whisper-server
# schon einen fertigen HTTP-Endpoint mit (POST /inference, multipart "file"-Feld).
# Reiner HTTP-Endpoint (kein Dauerlausch-VAD-Daemon) — Sojus Core entscheidet, wann
# Audio geschickt wird.
{ config, pkgs, lib, ... }:

let
  # Eigener pkgs-Satz nur für diesen Service: cudaSupport lokal auf true, ohne den
  # System-weiten pkgs (config.nixpkgs) anzufassen (siehe Kommentar in nvidia.nix).
  pkgsCuda = import pkgs.path {
    inherit (pkgs) system;
    config = pkgs.config // { cudaSupport = true; };
  };

  whisperCpp = pkgsCuda.whisper-cpp;

  # medium-Modell: guter Kompromiss zwischen Genauigkeit (u.a. Deutsch) und VRAM,
  # da sich die RTX 2070 SUPER (8GB) die Karte mit Chatterbox teilt.
  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin";
    sha256 = "6c14d5adee5f86394037b4e4e8b59f1673b6cee10e3cf0b11bbdbee79c156208";
  };
in
{
  systemd.services.whisper-stt = {
    description = "Whisper STT HTTP-Service (whisper.cpp, CUDA)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = ''
        ${whisperCpp}/bin/whisper-server \
          --model ${model} \
          --host 0.0.0.0 \
          --port 8005 \
          --language de \
          --convert \
          --tmp-dir /var/lib/whisper-stt
      '';
      Restart = "always";
      RestartSec = "10s";
      DynamicUser = true;
      StateDirectory = "whisper-stt";
      WorkingDirectory = "/var/lib/whisper-stt";
      SupplementaryGroups = [ "video" "render" ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 8005 ];
}
