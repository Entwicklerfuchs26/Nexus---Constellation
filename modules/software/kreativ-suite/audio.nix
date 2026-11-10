# Audition-Alternative: Audacity
{ config, lib, pkgs, ... }:
let cfg = config.nexus.kreativSuite; in
{
  config = lib.mkIf (cfg.enable && cfg.audio.enable) {
    environment.systemPackages = [ pkgs.audacity ];
  };
}
