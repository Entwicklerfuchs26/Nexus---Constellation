{ config, pkgs, ... }:
{
  home.packages = [ pkgs.python3 ];

  home.file.".local/bin/focustime_stats.py" = {
    source = ./files/focustime/focustime_stats.py;
    executable = true;
  };
  home.file.".local/bin/focustime_daemon.py" = {
    source = ./files/focustime/focustime_daemon.py;
    executable = true;
  };
  home.file.".local/bin/get_stats.py" = {
    source = ./files/focustime/get_stats.py;
    executable = true;
  };

  systemd.user.services.focustime-daemon = {
    Unit = {
      Description = "FocusTime App-Nutzungs-Tracking (Nexus Dashboard)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "%h/.local/bin/focustime_daemon.py";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "PATH=/run/current-system/sw/bin:/run/wrappers/bin:/home/fuchs/.local/bin"
        "QS_STATE_FOCUSTIME=%h/.local/state/focustime"
        "QS_RUN_FOCUSTIME=/tmp/focustime"
      ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
