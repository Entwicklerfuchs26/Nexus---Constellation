# ArtCraft-Suite: Open-Source-Nachbau der Adobe-Programme in Rust (storytold/*craft).
# Status der Projekte: FRÜHE ALPHA / Beta -> zum Ausprobieren, nicht für Produktivarbeit.
#
# EIN Schalter für alles:  nexus.artcraft.enable = true/false;
# Komplett entfernen:      enable = false (oder Import in flake.nix raus),
#                          `nixos-rebuild switch`, dann `nix-collect-garbage -d`.
# Einzelne Apps:           nexus.artcraft.apps.<name>.enable = false;
# Update:                  neue Version + sha256 unten eintragen (Hashes stehen bei
#                          GitHub unter Releases -> Asset -> "sha256:...").
{ config, lib, pkgs, ... }:

let
  cfg = config.nexus.artcraft;
  mk = pkgs.callPackage ./package.nix { };

  # name = { version, sha256 (hex der linux-x86_64.tar.gz), desc }
  apps = {
    photocraft  = { version = "0.20.2"; sha256 = "09e013d68d8313eb0b1cd6f24612f5b5fd0d993fffe3a7c12cecdfe5cd131a46"; desc = "ArtCraft PhotoCraft (Photoshop-Alternative)"; };
    vectorcraft = { version = "0.21.1"; sha256 = "383bba06fbde7cb87c7e137937ad516a9a585491c5a927d8631ee54bbf1d4e93"; desc = "ArtCraft VectorCraft (Illustrator-Alternative)"; };
    lightcraft  = { version = "0.18.1"; sha256 = "078f8e4fef6ca88afa257a70228630b14e21380cea58031fbb5c5a1942b406f0"; desc = "ArtCraft LightCraft (Lightroom-Alternative)"; };
    pdfcraft    = { version = "0.18.2"; sha256 = "323bad7b373392076461e2cad5db63b22f47a032ba005a6c4a35f3483d05dae4"; desc = "ArtCraft PdfCraft (Acrobat-Alternative)"; };
    filmcraft   = { version = "0.17.1"; sha256 = "397ae9fece559b37863b4b076af46a63b6e4387c35f781709e4efad14fe71ebe"; desc = "ArtCraft FilmCraft (Premiere-Alternative)"; };
    designcraft = { version = "0.17.2"; sha256 = "b92e9067db11b8de1bb348232c0955d32469366fa3952d5dd96c18ca180a28ce"; desc = "ArtCraft DesignCraft (InDesign-Alternative)"; };
    effectcraft = { version = "0.21.1"; sha256 = "ec39afa51fb0a2c0b58a8c1102325e2355016fe754563d24075fa29b3e1c5315"; desc = "ArtCraft EffectCraft (After-Effects-Alternative)"; };
    soundcraft  = { version = "0.17.1"; sha256 = "e7ac140bb9fd69ade4dd02643af8e5d4c14a5c82cd670b2030e52688febb3cb4"; desc = "ArtCraft SoundCraft (Audition-Alternative)"; };
  };
in
{
  options.nexus.artcraft = {
    enable = lib.mkEnableOption "ArtCraft-Suite (Open-Source-Adobe-Nachbau, Alpha)";
    apps = lib.mapAttrs (n: a:
      { enable = lib.mkEnableOption a.desc // { default = true; }; }) apps;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mapAttrsToList
      (n: a: mk ({ pname = n; } // a))
      (lib.filterAttrs (n: _: cfg.apps.${n}.enable) apps);
  };
}
