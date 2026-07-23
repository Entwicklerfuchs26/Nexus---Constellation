{ config, pkgs, ... }:
{
  systemd.user.services.theme-auto-light = {
    Unit = {
      Description = "Sojus Theme Auto-Switch: Light";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/skwd-wall/scripts/toggle-theme.sh --auto light";
    };
  };

  systemd.user.timers.theme-auto-light = {
    Unit = {
      Description = "Sojus Theme Auto-Switch: Light (07:00)";
    };
    Timer = {
      OnCalendar = "07:00";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services.theme-auto-dark = {
    Unit = {
      Description = "Sojus Theme Auto-Switch: Dark";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/skwd-wall/scripts/toggle-theme.sh --auto dark";
    };
  };

  systemd.user.timers.theme-auto-dark = {
    Unit = {
      Description = "Sojus Theme Auto-Switch: Dark (21:00)";
    };
    Timer = {
      OnCalendar = "21:00";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
