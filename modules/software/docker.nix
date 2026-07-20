{ config, pkgs, ... }:

{
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    autoPrune.dates = "weekly";
  };

  # users.users.<username>.extraGroups = [ "docker" ] → hosts/nexus/host-config.nix

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
