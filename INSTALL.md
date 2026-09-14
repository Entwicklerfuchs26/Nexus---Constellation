# Community Installation – Nexus Constellation

Dieses Repo ist die NixOS-Flake-Konfiguration "Nexus Constellation" — ein modularer Hyprland-Desktop mit adaptivem Matugen-Theming, NVIDIA-Support und einer host-basierten Struktur, die sich auch für andere Rechner als Vorlage eignet.

## Voraussetzungen

- NixOS mit aktivierten Flakes
- Git

## Installation

1. Repo klonen:
   ```bash
   git clone https://github.com/Entwicklerfuchs26/Nexus---Constellation /etc/nixos/nixos-config
   ```
2. **Persönliche Werte anlegen** — liegen bewusst außerhalb des Repos unter
   `/etc/nixos/user/`, damit sie nie versehentlich committet werden:
   ```bash
   mkdir -p /etc/nixos/user
   cp /etc/nixos/nixos-config/user/config.example.nix   /etc/nixos/user/config.nix
   cp /etc/nixos/nixos-config/user/hardware.example.nix /etc/nixos/user/hardware.nix
   ```
   Beide Dateien öffnen und ausfüllen (Username, Name, E-Mail, Hostname,
   ggf. Domain/LDAP/SFTP/Hardware-Werte — Kommentare in den Dateien erklären
   jedes Feld). Ohne diese zwei Dateien schlägt der Build mit einer klaren
   Fehlermeldung fehl, die genau hierher zurückverweist.
3. Eigene Hardware-Config generieren:
   ```bash
   nixos-generate-config
   ```
4. Neuen Host anlegen (Vorlage kopieren):
   ```bash
   cp -r /etc/nixos/nixos-config/hosts/example /etc/nixos/nixos-config/hosts/MEINPC
   ```
   `hostName` in `/etc/nixos/user/config.nix` muss zu `MEINPC` passen.
5. Generierte `hardware-configuration.nix` in `hosts/MEINPC/` einfügen, `host-config.nix` bei Bedarf an die eigene Hardware anpassen (Kommentare im Beispiel erklären was optional ist).
6. In `flake.nix` den neuen Host eintragen (Kopie des `nexus`-Blocks unter `nixosConfigurations`, Pfade auf `hosts/MEINPC` anpassen).
7. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#MEINPC
   ```
8. Restliche Dotfiles installieren (skwd-wall/matugen-Skripte, die noch nicht deklarativ über Home-Manager laufen):
   ```bash
   bash /etc/nixos/nixos-config/dotfiles/install.sh
   ```

## Module

Eine Übersicht aller Module gibt es in [`ai/MODULES.md`](ai/MODULES.md).

## Hinweis

- `secrets/` ist nicht im Repo enthalten (siehe `.gitignore`) und muss selbst angelegt werden.
- `/etc/nixos/user/` (echte persönliche Werte) ist ebenfalls nicht im Repo enthalten — siehe Schritt 2.
