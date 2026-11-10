# InDesign-Alternative: Scribus
{ config, lib, pkgs, ... }:
let cfg = config.nexus.kreativSuite; in
{
  config = lib.mkIf (cfg.enable && cfg.layout.enable) {
    environment.systemPackages = [ pkgs.scribus ];
  };
}
