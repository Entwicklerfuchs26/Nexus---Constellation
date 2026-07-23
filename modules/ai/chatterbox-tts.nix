# Chatterbox TTS — Sprachausgabe für Sojus (Voice Layer, Schritt 4)
# Nutzt das bereits vorhandene devnen/Chatterbox-TTS-Server-Setup unter
# /home/fuchs/Chatterbox-TTS-Server (dort schon per docker-compose gebaut,
# Modell/Sprache/Stimme in dessen config.yaml gepflegt — hier NICHT duplizieren).
{ config, pkgs, ... }:

let
  projectDir = "/home/fuchs/Chatterbox-TTS-Server";
in
{
  virtualisation.oci-containers.backend = "docker";

  # Bind-Mount-Zielverzeichnisse mit korrektem Owner anlegen, bevor Docker
  # sie sonst root:root erzeugt (Docker legt fehlende Source-Dirs sonst selbst an).
  systemd.tmpfiles.rules = [
    "d ${projectDir}/outputs 0755 fuchs users -"
    "d ${projectDir}/logs 0755 fuchs users -"
    "d ${projectDir}/model_cache 0755 fuchs users -"
    "d /home/fuchs/.cache/huggingface 0755 fuchs users -"
  ];

  virtualisation.oci-containers.containers.chatterbox-tts = {
    image = "chatterbox-tts-server-chatterbox-tts-server:latest";
    # Image existiert nur lokal (selbst gebaut) — niemals versuchen zu pullen.
    pull = "never";
    autoStart = true;

    ports = [ "8004:8004" ];

    volumes = [
      "${projectDir}/config.yaml:/app/config.yaml"
      "${projectDir}/voices:/app/voices"
      "${projectDir}/reference_audio:/app/reference_audio"
      "${projectDir}/outputs:/app/outputs"
      "${projectDir}/logs:/app/logs"
      "${projectDir}/model_cache:/app/model_cache"
      "/home/fuchs/.cache/huggingface:/app/hf_cache"
    ];

    environment = {
      HF_HUB_ENABLE_HF_TRANSFER = "1";
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,utility";
    };

    # NICHT --gpus=all: scheitert auf diesem System mit "AMD CDI spec not found"
    # (Docker versucht CDI-Auflösung über alle Vendor-Prefixe, bricht dabei an AMD ab,
    # obwohl gar keine AMD-GPU da ist). Manuell getestet, --device löst das sauber.
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
  };

  # Im Heimnetz erreichbar für Sojus Core auf darwin26 (192.168.1.26)
  networking.firewall.allowedTCPPorts = [ 8004 ];
}
