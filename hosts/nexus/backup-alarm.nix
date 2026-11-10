# Backup-Alarm (10.11.2026): rote, bleibende Desktop-Meldung (swaync, "critical"),
# wenn die ZFS-Sicherung auf backup-nexus fehlschlägt oder veraltet ist.
# Anlass: /home wurde 20 Tage lang nicht gesichert (abgebrochener Transfer) und
# niemand hat es bemerkt. Handy-Push folgt, sobald es eine Push-Funktion gibt.
{ config, lib, pkgs, userConfig, ... }:
let
  user = userConfig.username;

  # alarm TITEL TEXT -> Journal + rote Meldung auf dem Desktop (bleibt bis weggeklickt)
  alarm = pkgs.writeShellScript "backup-alarm" ''
    title="$1"
    body="$2"
    echo "BACKUP-ALARM: $title -- $body" | ${pkgs.systemd}/bin/systemd-cat -p err -t backup-alarm
    uid=$(${pkgs.coreutils}/bin/id -u ${user})
    ${pkgs.util-linux}/bin/runuser -u ${user} -- \
      ${pkgs.coreutils}/bin/env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
      ${pkgs.libnotify}/bin/notify-send -u critical -t 0 -a Backup "$title" "$body" || true
  '';

  # Läuft die Sicherung überhaupt, und ist sie frisch? (max. 48 h alt)
  check = pkgs.writeShellScript "backup-alarm-check" ''
    export PATH=${lib.makeBinPath [ pkgs.zfs pkgs.coreutils ]}
    health=$(zpool list -H -o health backup-nexus 2>/dev/null || true)
    if [ "$health" != "ONLINE" ]; then
      ${alarm} "BACKUP-PLATTE FEHLT" "Pool backup-nexus ist nicht online (Status: ''${health:-nicht gefunden}). Platte angeschlossen? Es wird NICHT gesichert."
      exit 0
    fi
    for ds in nexus-home nexus-root; do
      newest=$(zfs list -H -p -t snapshot -d 1 -o creation -s creation backup-nexus/$ds | tail -1)
      age_days=$(( ( $(date +%s) - ''${newest:-0} ) / 86400 ))
      if [ "$age_days" -ge 2 ]; then
        ${alarm} "BACKUP VERALTET: $ds" "Letzte Sicherung von $ds ist $age_days Tage alt. Bei einem Plattenausfall gehen die Daten seitdem verloren. Log: journalctl -u syncoid-rpool-''${ds#nexus-}.service"
      fi
    done
  '';
in
{
  # Vorlage: wird von OnFailure= der Sync-Dienste gestartet (%i = Name des fehlgeschlagenen Dienstes)
  systemd.services."backup-alarm-fail@" = {
    description = "Backup-Alarm für %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${alarm} \"BACKUP FEHLGESCHLAGEN\" \"%i ist fehlgeschlagen. Deine Daten sind evtl. NICHT gesichert. Log: journalctl -u %i\"";
    };
  };

  systemd.services.syncoid-rpool-home.onFailure = [ "backup-alarm-fail@syncoid-rpool-home.service" ];
  systemd.services.syncoid-rpool-root.onFailure = [ "backup-alarm-fail@syncoid-rpool-root.service" ];

  systemd.services.backup-alarm-check = {
    description = "Prüft, ob die ZFS-Sicherung frisch ist";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = check;
    };
  };
  systemd.timers.backup-alarm-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";
      OnCalendar = "*-*-* 12:00:00";
      Persistent = true;
    };
  };
}
