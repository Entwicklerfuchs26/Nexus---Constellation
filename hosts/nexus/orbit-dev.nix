# Orbit (Projektordner noch skwd-wall-sync) — Vite-Dev-Server als Boot-Dienst.
# Damit die Live-Reload-Dev-APK nach jedem Reboot http://<lan>:5173 erreicht,
# ohne dass der Server von Hand gestartet werden muss. Der Port 5173 ist bereits
# deklarativ nur auf dem LAN-Interface offen (siehe host-config.nix).
# Reversibel: diese Datei aus flake.nix-imports nehmen + rebuild (oder
# `systemctl disable --now orbit-dev`).
{ config, lib, pkgs, ... }:
let
  projectDir = "/home/fuchs/projects/skwd-wall-sync";
in
{
  systemd.services.orbit-dev = {
    description = "Orbit Vite dev server (Live-Reload fuer die Dev-APK)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "fuchs";
      WorkingDirectory = projectDir;
      # Systemweiter node (gleiche Version, die node_modules installiert hat).
      ExecStart = "/run/current-system/sw/bin/node ${projectDir}/node_modules/vite/bin/vite.js";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "HOME=/home/fuchs"
        "PATH=/run/current-system/sw/bin"
        "NODE_ENV=development"
      ];
    };
  };
}
