# AMD Strix Halo (Ryzen AI Max+ 395 / Radeon 8060S, gfx1151) — Unified-Memory-Setup für nous.
# Ollama läuft über Vulkan/RADV (siehe modules/ai/ollama-vulkan.nix), kein ROCm nötig für den
# Standardfall — nixpkgs' eigenes ROCm hat noch keinen gfx1151-Target.
{ config, pkgs, lib, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ vulkan-loader mesa ];
  };

  # GTT-Größe für Unified-Memory-Compute. Bestätigtes RAM: 128GB (BIOS "Dedicated Graphics
  # Memory" am 20.08. von zu hoch auf 2GB Minimum gesenkt, vorher war die Hälfte des RAMs
  # dauerhaft vom OS ferngehalten). GTT ist eine Obergrenze, keine Vorab-Reservierung — das
  # OS bekommt nur belegt, was tatsächlich für geladene Modelle gebraucht wird.
  boot.kernelParams = [
    "amdgpu.gttsize=131072"
    "ttm.pages_limit=31457280"
  ];

  # IOMMU bewusst NICHT deaktivieren (Community-Guides raten davon ab, außer für reines
  # Desktop-Gaming-Benchmarking — hier irrelevant, nous ist headless).
}
