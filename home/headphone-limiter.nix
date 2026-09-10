{ config, pkgs, ... }:
{
  home.file.".config/pipewire/pipewire.conf.d/99-headphone-limiter.conf" = {
    source = ./files/headphone-limiter/99-headphone-limiter.conf;
    force = true;
  };
}
