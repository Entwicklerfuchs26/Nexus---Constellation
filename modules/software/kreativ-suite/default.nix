# Kreativ-Suite: freie Alternativen zu den Adobe-Programmen (angelegt 05.11.2026).
#
# EIN Schalter für alles:  nexus.kreativSuite.enable = true/false;
# Komplett entfernen:      Import in flake.nix auskommentieren (oder enable = false),
#                          dann `nixos-rebuild switch` + `nix-collect-garbage`.
# Einzelne Teile:          nexus.kreativSuite.<teil>.enable = false;
#
# Schon woanders installiert (software.nix) und deshalb HIER NICHT doppelt:
#   Krita (Photoshop/Fresco), Blender (Dimension/3D), darktable (Lightroom),
#   DaVinci Resolve (Premiere/After Effects, davinci.nix).
{ config, lib, ... }:

let
  cfg = config.nexus.kreativSuite;
  teil = beschr: lib.mkEnableOption beschr // { default = true; };
in
{
  imports = [
    ./grafik.nix   # Photoshop      -> GIMP
    ./vektor.nix   # Illustrator    -> Inkscape
    ./layout.nix   # InDesign       -> Scribus
    ./video.nix    # Premiere       -> Kdenlive
    ./foto.nix     # Lightroom      -> RawTherapee (Ergänzung zu darktable)
    ./audio.nix    # Audition       -> Audacity
  ];

  options.nexus.kreativSuite = {
    enable = lib.mkEnableOption "Kreativ-Suite (freie Adobe-Alternativen)";
    grafik.enable = teil "GIMP (Pixelbearbeitung)";
    vektor.enable = teil "Inkscape (Vektorgrafik)";
    layout.enable = teil "Scribus (Seitenlayout/DTP)";
    video.enable  = teil "Kdenlive (Videoschnitt)";
    foto.enable   = teil "RawTherapee (RAW-Entwicklung)";
    audio.enable  = teil "Audacity (Audio-Bearbeitung)";
  };

  config = lib.mkIf cfg.enable { };
}
