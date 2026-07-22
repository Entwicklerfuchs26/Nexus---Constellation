# Community Installation – Nexus Constellation

Dieses Repo ist die NixOS-Flake-Konfiguration "Nexus Constellation" — ein modularer Hyprland-Desktop mit adaptivem Matugen-Theming, NVIDIA-Support und einer host-basierten Struktur, die sich auch für andere Rechner als Vorlage eignet.

## Voraussetzungen

- NixOS mit aktivierten Flakes
- Git

## Installation

1. Repo klonen:
   ```bash
   git clone https://github.com/Entwicklerfuchs26/Nexus---Constellation ~/nixos-config
   ```
2. Eigene Hardware-Config generieren:
   ```bash
   nixos-generate-config
   ```
3. Neuen Host anlegen (Vorlage kopieren):
   ```bash
   cp -r ~/nixos-config/hosts/example ~/nixos-config/hosts/MEINPC
   ```
4. `host-config.nix` im neuen Host-Ordner anpassen (Hostname, Username, IPs etc.) und die generierte `hardware-configuration.nix` einfügen.
5. In `flake.nix` den neuen Host eintragen.
6. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake ~/nixos-config#MEINPC
   ```
7. Dotfiles installieren:
   ```bash
   bash ~/nixos-config/dotfiles/install.sh
   ```

## Module

Eine Übersicht aller Module gibt es in [`ai/MODULES.md`](ai/MODULES.md).

## Hinweis

`secrets/` ist nicht im Repo enthalten (siehe `.gitignore`) und muss selbst angelegt werden.
