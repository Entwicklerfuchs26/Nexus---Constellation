{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    aw-server-rust
    aw-watcher-afk
    aw-watcher-window
  ];

  systemd.user.services.aw-server = {
    Unit = {
      Description = "ActivityWatch server (Rust)";
    };
    Service = {
      ExecStart = "${pkgs.aw-server-rust}/bin/aw-server";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.aw-watcher-afk = {
    Unit = {
      Description = "ActivityWatch AFK watcher";
      After = [ "aw-server.service" ];
    };
    Service = {
      ExecStart = "${pkgs.aw-watcher-afk}/bin/aw-watcher-afk";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.aw-watcher-window = {
    Unit = {
      Description = "ActivityWatch window watcher";
      After = [ "aw-server.service" ];
    };
    Service = {
      ExecStart = "${pkgs.aw-watcher-window}/bin/aw-watcher-window";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
