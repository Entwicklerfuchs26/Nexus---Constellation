# Overview

Dieses Repo ist die NixOS-Flake-Konfiguration für zwei Hosts:

- **nexus** — Desktop/Workstation: Hyprland als Wayland-Compositor, NVIDIA-Treiber, LDAP-Auth gegen
  `sternenhof.space`, sowie ein Material-You-Theming-System (matugen + skwd-wall), das aus dem aktuellen
  Wallpaper systemweit Farben ableitet und per Templates an Waybar, KDE, Hyprlock, GTK, Kitty, OpenRGB,
  Hyperion u. a. verteilt.
- **nous** — GMKtec EVO-X2 (AMD Ryzen AI Max+ 395 „Strix Halo", gfx1151, 128GB Unified RAM), headless,
  bewusst **reine AI-Inference-Maschine**: aktuell nur Ollama (Vulkan/RADV-Backend), später ComfyUI/TTS/STT.
  **Architekturentscheidung (20.08.2026):** Sojus/Hermes/Kaira laufen absichtlich NICHT auf nous, obwohl
  reichlich RAM/CPU frei wäre — darwin26 (wo Hermes/Kaira aktuell laufen) hat ein eigenes RAM-Problem
  (~15GB, schon eng), das dort gelöst werden sollte statt Agenten-Workloads auf die für große
  LLM-Modelle vorgesehene Maschine zu verlagern und deren Unified-Memory-Headroom zu fragmentieren.
  Details/Recherche siehe Plan-Historie in der Session vom 20.08.2026 (BIOS-Fix: "Dedicated Graphics
  Memory" war zu hoch eingestellt und hat die Hälfte des RAMs vom OS ferngehalten, siehe
  `modules/hardware/amd-strix-halo.nix`).

## Repo-Struktur (erste zwei Ebenen)

```
.
├── certs/                  Root-CA-Zertifikat (sternenhof.space)
├── dotfiles/                Theming-Engine: matugen-Templates, skwd-wall-Scripts, Install-Skript
│   ├── matugen/
│   └── skwd-wall/
├── flake.nix                Flake-Entrypoint, definiert nixosConfigurations.nexus + nixosConfigurations.nous
├── flake.lock
├── home/                     Home-Manager-Konfiguration (nur nexus, nous hat kein Home-Manager)
│   ├── files/                deployte Configs (nicht Home-Manager-verwaltet)
│   └── *.nix
├── hosts/                    Host-spezifische Konfiguration
│   ├── example/               Vorlage für weitere Hosts
│   ├── nexus/                  Hostname, UUIDs, MACs, Benutzer, Firewall
│   └── nous/                   Hostname, Benutzer, Firewall — headless, kein Desktop-Kram
├── modules/                  Wiederverwendbare NixOS-Module, siehe ai/MODULES.md
│   ├── ai/
│   ├── core/
│   ├── desktop/
│   ├── hardware/
│   ├── rgb/
│   └── software/
└── pkgs/                     Eigene Pakete (Nix-Manager, Anime-Organizer, aniworld, ...)
```

## Zuerst lesen

Für ein Grundverständnis des Systems in dieser Reihenfolge lesen:

1. `flake.nix` — Inputs, welche Module in welcher Reihenfolge eingebunden werden
2. `modules/core/base.nix` — generische Systemkonfiguration (Bootloader, Locale, Audio, Bluetooth)
3. `hosts/nexus/host-config.nix` — Host-spezifische Werte (Hostname, Benutzer, Firewall, Mounts, SSSD)

## Nicht nötig zu lesen

- `.git/` — Versionsverlauf, für Kontextverständnis irrelevant
- `dotfiles/skwd-wall/templates/` — viele kleine Template-Dateien pro Zielapp (Details siehe `ai/DOTFILES.md`)
- `home/files/` — bereits deployte/gerenderte Configs, keine Quelle der Wahrheit

## Hinweis

`secrets/` ist **nicht** Teil dieses Repos (siehe `.gitignore`) und existiert nur lokal auf dem Zielsystem.
