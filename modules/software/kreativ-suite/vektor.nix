# Illustrator-Alternative: Inkscape
{ config, lib, pkgs, ... }:
let cfg = config.nexus.kreativSuite; in
{
  config = lib.mkIf (cfg.enable && cfg.vektor.enable) {
    environment.systemPackages = [ pkgs.inkscape-with-extensions ];
  };
}
