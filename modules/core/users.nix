{ config, pkgs, ... }:

{
  # Passwörter dürfen nur über NixOS verwaltet werden
  users.mutableUsers = true;

  # Benutzerdefinitionen (name, groups, shell) → hosts/nexus/host-config.nix
}
