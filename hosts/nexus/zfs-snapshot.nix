# ZFS-Snapshot-Automatik für nexus (21.09.2026 eingerichtet).
# Externe Backup-Platte: Seagate Backup+ Hub (3,6TB, vormals HFS+/"workflow"),
# jetzt Pool "backup-nexus" -- siehe Vikunja-Task zur Einrichtung.
{ config, lib, pkgs, ... }:
{
  # Persistenter Import der externen Backup-Platte, überlebt Reboots.
  boot.zfs.extraPools = [ "backup-nexus" ];

  # sanoid: automatische, wiederkehrende Snapshots + Aufräumen alter
  # Snapshots nach fester Aufbewahrungsregel -- kein manuelles
  # "zfs snapshot" mehr nötig.
  services.sanoid = {
    enable = true;
    templates.standard = {
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 3;
      autosnap = true;
      autoprune = true;
    };
    datasets = {
      "rpool/root" = { useTemplate = [ "standard" ]; };
      "rpool/home" = { useTemplate = [ "standard" ]; };
    };
  };

  # syncoid: tägliche Replikation der Snapshots auf die externe
  # Backup-Platte -- macht aus den lokalen Snapshots ein echtes Backup auf
  # einem physisch getrennten Datenträger, nicht nur eine Rollback-Hilfe
  # auf derselben Platte.
  services.syncoid = {
    enable = true;
    interval = "daily";
    commands = {
      "rpool/root" = { target = "backup-nexus/nexus-root"; };
      "rpool/home" = { target = "backup-nexus/nexus-home"; };
    };
  };
}
