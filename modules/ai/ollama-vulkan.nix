# Ollama für nous (AMD Strix Halo, Vulkan/RADV-Backend) — eigenständiges Modul, nicht
# modules/ai/ollama.nix von nexus anfassen (das ist fest auf ollama-cuda/NVIDIA zugeschnitten).
#
# Backend-Wahl: Community-Benchmarks zeigen Vulkan/RADV schlägt ROCm bei normalem
# Single-Request-Decode; ROCm gewinnt nur bei Batching/langem Prompt-Prefill. Start mit Vulkan
# (nixpkgs mainline, kein externer Flake nötig), nach Benchmarking mit echtem Nutzungsprofil
# (2 parallele Requests + langer Kontext) ggf. auf ROCm umsteigen (z.B. github:hellas-ai/nix-strix-halo
# oder github:noamsto/nix-amd-ai, beide packen gfx1151 fertig via TheRock-SDK).
{ config, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      OLLAMA_NUM_PARALLEL      = "2";   # Zielprofil: bis 2 gleichzeitige Anfragen
      OLLAMA_MAX_LOADED_MODELS = "2";   # 128GB RAM bestätigt — 2 mittelgroße Modelle parallel realistisch
      OLLAMA_FLASH_ATTENTION    = "1";
      OLLAMA_CONTEXT_LENGTH     = "32768"; # für agentische Aufgaben mit vollem Kontext, ggf. höher testen
      # Ohne das hier verwirft Ollama 0.32+ die iGPU automatisch ("dropping integrated
      # GPU") und rechnet komplett auf CPU — bei Strix Halo ist die iGPU aber der Punkt.
      OLLAMA_IGPU_ENABLE        = "1";
    };
  };
}
