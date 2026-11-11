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
  #
  # Umstellung 11.11.2026: Die Historie liegt NUR auf der Backup-Platte. Auf der
  # internen SSD (rpool) bleiben nur 2 Tages-Snapshots als Basis für die
  # inkrementelle Sicherung -- vorher hielten 3 Monate Snapshots ~205 GB fest.
  # Syncoid repliziert die täglichen Snapshots, sanoid räumt sie auf backup-nexus
  # nach der längeren Regel auf.
  services.sanoid = {
    enable = true;
    templates.lokal = {
      hourly = 0;
      daily = 2;
      weekly = 0;
      monthly = 0;
      autosnap = true;
      autoprune = true;
    };
    # Nur aufräumen, nicht selbst snapshotten (die Snapshots kommen per syncoid).
    # weekly/monthly: nur damit schon vorhandene alte Stände dort natürlich auslaufen.
    templates.backup = {
      hourly = 0;
      daily = 90;
      weekly = 8;
      monthly = 12;
      autosnap = false;
      autoprune = true;
    };
    datasets = {
      "rpool/root" = { useTemplate = [ "lokal" ]; };
      "rpool/home" = { useTemplate = [ "lokal" ]; };
      "backup-nexus/nexus-root" = { useTemplate = [ "backup" ]; };
      "backup-nexus/nexus-home" = { useTemplate = [ "backup" ]; };
    };
  };

  # syncoid: tägliche Replikation der Snapshots auf die externe
  # Backup-Platte -- macht aus den lokalen Snapshots ein echtes Backup auf
  # einem physisch getrennten Datenträger, nicht nur eine Rollback-Hilfe
  # auf derselben Platte.
  services.syncoid = {
    enable = true;
    interval = "daily";
    # "destroy" auf dem Ziel: ohne das scheitert syncoid beim Aufräumen eigener alter
    # Sync-Snapshots ("cannot destroy: permission denied") und beim Verwerfen eines
    # abgebrochenen Transfers (zfs receive -A) -- Ursache für die 20 Tage ohne /home-Backup.
    localTargetAllow = [ "change-key" "compression" "create" "mount" "mountpoint" "receive" "rollback" "destroy" ];
    commands = {
      "rpool/root" = { target = "backup-nexus/nexus-root"; };
      "rpool/home" = { target = "backup-nexus/nexus-home"; };
    };
  };
}
