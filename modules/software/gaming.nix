{ config, pkgs, inputs, ... }:

{
  # An Anime Game Launcher (Genshin Impact) deklarativ -- Modul kommt aus dem
  # aagl-Flake-Input. Die vorhandene Spielinstallation liegt auf
  # /mnt/games/AnimeGameLauncher und wird nach dem Rebuild per Symlink/Config
  # angebunden (siehe NEXUS-Doku / Memory).
  imports = [ inputs.aagl.nixosModules.default ];

  # Steam aktivieren
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };

  # GameMode - optimiert CPU beim Spielen
  programs.gamemode.enable = true;

  # An Anime Game Launcher. Ohne den Binärcache würde der Launcher inkl.
  # Abhängigkeiten lokal gebaut -- ezkea.cachix.org liefert ihn fertig.
  nix.settings = {
    substituters = [ "https://ezkea.cachix.org" ];
    trusted-public-keys = [ "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI=" ];
  };
  programs.anime-game-launcher.enable = true;

  # Gaming Pakete
  environment.systemPackages = with pkgs; [
    # Proton für Windows-Spiele
    protonup-qt

    # MangoHud - FPS Anzeige im Spiel
    mangohud

    # Minecraft Launcher
    prismlauncher
  ];

  # fileSystems."/mnt/games" → hosts/nexus/host-config.nix (UUID-gebunden)
}
