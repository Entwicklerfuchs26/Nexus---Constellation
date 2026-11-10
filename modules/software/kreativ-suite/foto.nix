# Lightroom-Alternative: RawTherapee (darktable ist bereits in software.nix)
{ config, lib, pkgs, ... }:
let cfg = config.nexus.kreativSuite; in
{
  config = lib.mkIf (cfg.enable && cfg.foto.enable) {
    environment.systemPackages = [ pkgs.rawtherapee ];
  };
}
