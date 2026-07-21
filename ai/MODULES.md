# Module

Alle Module werden zentral in `flake.nix` in die `nixosConfigurations.nexus`-Modulliste eingebunden.
Host-spezifische Werte (Hostname, UUIDs, Benutzerliste, Firewall-Ports) leben bewusst nicht in den
Modulen selbst, sondern in `hosts/nexus/host-config.nix`.

| Modul | Zweck |
|---|---|
| `modules/core/base.nix` | generische Systemkonfiguration, kein Hardware-spezifisches |
| `modules/core/users.nix` | aktiviert `mutableUsers`; konkrete Benutzer stehen in `host-config.nix` |
| `modules/core/printing.nix` | CUPS-Drucker (Epson-Treiber) + Avahi/mDNS |
| `modules/core/ldap.nix` | SSSD-Grundaktivierung für LDAP-Login; Domain-Details in `host-config.nix` |
| `modules/hardware/nvidia.nix` | proprietärer NVIDIA-Treiber, Wayland-Umgebungsvariablen |
| `modules/desktop/hyprland.nix` | Hyprland-Compositor, SDDM, deutsches Tastaturlayout, Bluetooth-UI |
| `modules/software/software.nix` | Flatpak, XDG-Portale, Firefox, KDE-Connect, OBS, allgemeine Nutzerpakete |
| `modules/software/gaming.nix` | Steam, GameMode, Proton/MangoHud/Prism-Launcher |
| `modules/software/docker.nix` | Docker + NVIDIA-Container-Toolkit |
| `modules/software/davinci.nix` | DaVinci Resolve (unfree-Freigabe) + FFmpeg-Konvertierungsskript |
| `modules/software/affinity.nix` | Wine-Abhängigkeiten für Affinity (ElementalWarriorWine) |
| `modules/ai/ollama.nix` | lokaler Ollama-Server (CUDA), im Heimnetz erreichbar |
| `modules/ai/sojus.nix` | Sojus-Agent-Tooling, u. a. `safe-rebuild`-Skript für autonome Rebuilds |
