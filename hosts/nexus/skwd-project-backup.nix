# 5-Minuten-Sicherung des aktiven Projektordners auf die externe Backup-Platte.
# Additiv + reversibel: eigener ZFS-Datensatz auf backup-nexus, rsync alle 5 min
# (ohne node_modules/dist/build -- nur Code), danach Snapshot. sanoid prunt.
# Entfernen = diese Datei aus den imports nehmen + rebuild. Nichts an rpool/home.
{ config, lib, pkgs, ... }:
let
  src = "/home/fuchs/projects/skwd-wall-sync";
  dataset = "backup-nexus/skwd-wall-sync";
  mnt = "/backup-nexus/skwd-wall-sync";
in
{
  # Eigener Datensatz als Ziel (einmalig angelegt, falls noch nicht da).
  systemd.services.skwd-backup-init = {
    description = "ensure backup dataset for skwd-wall-sync exists";
    after = [ "zfs-import.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.zfs ];
    script = ''
      zfs list ${dataset} >/dev/null 2>&1 || zfs create ${dataset}
    '';
  };

  # Alle 5 Minuten: Code spiegeln -> Snapshot ziehen.
  systemd.services.skwd-backup = {
    description = "5-min code snapshot of skwd-wall-sync to backup-nexus";
    after = [ "skwd-backup-init.service" ];
    path = [ pkgs.rsync pkgs.zfs pkgs.coreutils ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu
      zpool list backup-nexus >/dev/null 2>&1 || exit 0   # Platte ab? -> still ruhen
      rsync -a --delete \
        --exclude node_modules --exclude dist --exclude .gradle \
        --exclude android/app/build --exclude android/build \
        ${src}/ ${mnt}/current/
      zfs snapshot ${dataset}@$(date +%Y%m%d-%H%M%S)
    '';
  };
  systemd.timers.skwd-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
  };

  # Aufbewahrung: ein paar behalten. sanoid 'frequently' = 5-Min-Snapshots,
  # behalte 36 (= 3 Stunden), dazu 24 stündliche, 7 tägliche.
  services.sanoid.datasets."${dataset}" = {
    useTemplate = [ "skwd" ];
  };
  services.sanoid.templates.skwd = {
    frequently = 36;
    hourly = 24;
    daily = 7;
    autosnap = false;   # Snapshots macht der Timer oben, sanoid nur prunen
    autoprune = true;
  };
}
