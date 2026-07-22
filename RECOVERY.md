# Disaster Recovery – Nexus

## Voraussetzungen

- Age-Key und Secrets müssen **extern** gesichert sein (USB-Stick, Passwortmanager). Ohne diese Sicherung sind verschlüsselte Secrets nach einem Festplattencrash **nicht wiederherstellbar** — `secrets/` ist nicht im Repo (siehe `.gitignore`).

## Schritte bei Festplattencrash

1. NixOS frisch installieren.
2. Repo klonen:
   ```bash
   git clone https://github.com/Entwicklerfuchs26/Nexus---Constellation /etc/nixos/nixos-config
   ```
3. Hardware-Config generieren und übernehmen:
   ```bash
   nixos-generate-config --root /mnt
   ```
   Die erzeugte `hardware-configuration.nix` nach `hosts/nexus/` kopieren.
4. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#nexus
   ```
5. Dotfiles installieren:
   ```bash
   bash /etc/nixos/nixos-config/dotfiles/install.sh
   ```
6. Secrets wiederherstellen (Age-Key von externem Speicher einspielen, Secrets entschlüsseln).

## Hinweis

Die skwd-wall Config wird durch `install.sh` automatisch nach `~/.config/skwd-wall/` kopiert.
