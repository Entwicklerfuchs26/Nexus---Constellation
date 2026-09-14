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
   Das war's — Hyprland, Waybar, skwd-wall-Theming, Dashboard etc. sind
   komplett über Home-Manager deklariert, kein separates Setup-Skript mehr
   nötig (war früher `dotfiles/install.sh`, ist jetzt überflüssig, siehe
   `home/skwd-wall.nix`).
8. Wallpaper wählen: `SUPER+T` öffnet den Wallpaper-Picker (`skwd-wall`).
   Danach generiert `matugen` automatisch die komplette Farbpalette für
   Waybar/Dashboard/Sidebar — ohne Wallpaper sieht das UI absichtlich noch
   ungefärbt/"kaputt" aus, das ist normal, keine Fehlfunktion.

## Module

Eine Übersicht aller Module gibt es in [`ai/MODULES.md`](ai/MODULES.md).

## Hinweis

- `secrets/` ist nicht im Repo enthalten (siehe `.gitignore`) und muss selbst angelegt werden.
- `/etc/nixos/user/` (echte persönliche Werte) ist ebenfalls nicht im Repo enthalten — siehe Schritt 2.

## Bekannte Stolpersteine (Community-Install-Test, 14.09.2026)

Alles unten wurde bei einer echten Neuinstallation auf frischer Hardware
gefunden und gefixt -- hier dokumentiert, damit es niemandem nochmal
stundenlang Kopfzerbrechen bereitet.

- **`sgdisk`/`zpool`/`zfs`/`mkfs.vfat` fehlen auf einem frischen NixOS ohne
  ZFS-Konfiguration.** Für einen manuellen ZFS-Root-Install temporär laden:
  `nix shell nixpkgs#gptfdisk nixpkgs#zfs nixpkgs#dosfstools nixpkgs#parted`.
  Das ZFS-**Kernelmodul** selbst braucht zusätzlich `boot.supportedFilesystems
  = [ "zfs" ]` in der laufenden Config + einen Reboot, bevor `zpool create`
  funktioniert (ein bloßes `modprobe zfs` reicht nicht, das Modul muss erst
  gebaut werden).
- **`path:`-Flake-Inputs (`sojus-core`, `user-data`) werden unter pure-eval
  NICHT automatisch neu eingelesen**, auch wenn sich die referenzierten
  Dateien ändern. Immer `nix flake update <input-name>` vor dem Build, sonst
  baut man klaglos mit einem stundenalten, unsichtbar veralteten Stand (der
  `rebuild`-Alias in `home/home.nix` macht das automatisch).
- **`nixos-install --root` kopiert KEINE persönlichen Home-Verzeichnis-Daten**
  (SSH-Keys, Repo-Checkouts, `~/.claude` etc.) — nur das deklarierte System
  wird gebaut. Diese Daten müssen händisch von der alten Installation
  rübergezogen werden (z.B. per `zpool import` + `rsync`, oder externe
  Platte read-only mounten).
- **ACL-Vererbung über nicht ausgeschlossene Elternordner:** das
  `sojusReadAccessEverywhere`-Activation-Script (`modules/ai/sojus.nix`)
  setzt Default-ACLs auf alle nicht explizit ausgeschlossenen Verzeichnisse.
  Neu angelegte Dateien in NICHT selbst ausgeschlossenen, aber innerhalb
  eines bereits verarbeiteten Elternordners liegenden Pfaden (z.B.
  `/var/lib/sssd/sssd.conf`, `/etc/ssh/ssh_host_*_key` -- Namensschema
  passt nicht zu den `id_rsa*`/`*.key`-Ausschlussmustern) erben die ACL vom
  Elternordner und brechen dadurch sshd/sssd. Sofort-Fix: `setfacl -b` auf
  Datei UND Elternordner. Echter Fix noch offen (Vikunja).
