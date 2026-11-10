# Photoshop-Alternative: GIMP 3 (Krita ist bereits in software.nix)
{ config, lib, pkgs, ... }:
let cfg = config.nexus.kreativSuite; in
{
  config = lib.mkIf (cfg.enable && cfg.grafik.enable) {
    environment.systemPackages = [ pkgs.gimp ];
  };
}
