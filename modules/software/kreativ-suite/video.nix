# Premiere-Alternative: Kdenlive (DaVinci Resolve liegt in davinci.nix)
{ config, lib, pkgs, ... }:
let cfg = config.nexus.kreativSuite; in
{
  config = lib.mkIf (cfg.enable && cfg.video.enable) {
    environment.systemPackages = [ pkgs.kdePackages.kdenlive ];
  };
}
