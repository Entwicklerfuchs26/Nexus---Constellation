# AMD Strix Halo (Ryzen AI Max+ 395 / Radeon 8060S, gfx1151) — Unified-Memory-Setup für nous.
# Ollama läuft über Vulkan/RADV (siehe modules/ai/ollama-vulkan.nix). ROCm ist als Backend-
# Alternative für llama.cpp inzwischen möglich (gfx1151 seit 2026 in nixpkgs' Standard-ROCm-
# Targets, über cache.nixos.org vorgebaut) — s. llama-server-rocm in modules/ai/llama-swap.nix,
# bisher nur zum Benchmarken, nicht im aktiven Serving-Pfad.
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

  # RADV splittet GTT-Speicher standardmäßig in mehrere Heaps (device-local + host-visible,
  # als Workaround für Spiele mit schlechtem VRAM-Management). Auf einer APU mit Unified
  # Memory ist das unnötig und sorgt dafür, dass Vulkan-Clients (u.a. Ollama, das gesplittete
  # Heaps nicht sauber handhabt — offener Bug ollama/ollama#15302) nur die kleinere Hälfte
  # (~64GB statt ~120GB) sehen. Ein Heap erzwingen:
  environment.etc."drirc".text = ''
    <driconf>
      <device>
        <application name="Default">
          <option name="radv_enable_unified_heap_on_apu" value="true" />
        </application>
      </device>
    </driconf>
  '';
}
