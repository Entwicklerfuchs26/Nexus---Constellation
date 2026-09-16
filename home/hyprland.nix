{ config, pkgs, ... }:
{
  # force = true: Hyprland selbst erzeugt sofort einen Stub an dieser Stelle
  # sobald die Datei fehlt (live beobachtet 16.09.2026 nach manuellem
  # `rm`/`sed -i` zum Testen) -- ohne force gewinnt der Stub das Rennen
  # gegen jeden home-manager-Neustart, Aktivierung schlägt mit "would be
  # clobbered" fehl.
  home.file.".config/hypr/hyprland.conf" = { source = ./files/hyprland.conf; force = true; };
  home.file.".config/hypr/hyprlock.conf".source = ./files/hyprlock.conf;
  home.file.".config/hypr/hypridle.conf".source = ./files/hypridle.conf;
}

