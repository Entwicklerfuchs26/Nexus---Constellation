{ config, pkgs, userConfig, ... }:
{
  # Auslastungs-Widget (eww "sysmon": CPU/RAM/GPU/VRAM/Netzwerk) am
  # 16.09.2026 endgültig entfernt -- war ein permanentes Desktop-Overlay,
  # nicht mehr gewünscht. eww.yuck/eww.scss.templ entsprechend bereinigt,
  # die drei Helper-Skripte (cpu.sh/net-rx.sh/net-tx.sh) hatten keinen
  # anderen Verwender und wurden gelöscht.
  home.file.".config/eww/eww.yuck" = { source = ./files/eww/eww.yuck; force = true; };

  # .text statt .source: enthält den persönlichen ntfy.sh-Kanalnamen, per
  # replaceStrings generisch gemacht.
  home.file.".local/bin/AniDL" = {
    text = builtins.replaceStrings [ "ntfy.sh/Nexus-NixOS_fuchs" ] [ "ntfy.sh/${userConfig.ntfyChannel}" ]
      (builtins.readFile ./files/anidl.sh);
    executable = true;
  };

  home.file.".local/bin/DL" = {
    text = builtins.replaceStrings [ "ntfy.sh/Nexus-NixOS_fuchs" ] [ "ntfy.sh/${userConfig.ntfyChannel}" ]
      (builtins.readFile ./files/dl.sh);
    executable = true;
  };

  home.file.".local/bin/media-picker" = {
    source = ./files/media-picker.sh;
    executable = true;
  };

  home.file.".local/bin/media-toggle" = {
    source = ./files/media-toggle.sh;
    executable = true;
  };

  home.file.".local/bin/ambient-toggle" = {
    source = ./files/ambient-toggle.sh;
    executable = true;
  };

  home.file.".local/bin/skill-tree-launcher" = {
    source = ./files/skill-tree-launcher.sh;
    executable = true;
  };

  home.file.".local/bin/ambient-waybar" = {
    source = ./files/ambient-waybar.sh;
    executable = true;
  };

  home.file.".local/bin/workspace-label" = {
    source = ./files/workspace-label.sh;
    executable = true;
  };

  home.file.".local/bin/workspace-label-set" = {
    source = ./files/workspace-label-set.sh;
    executable = true;
  };

  home.file.".local/bin/workspace-label-clear" = {
    source = ./files/workspace-label-clear.sh;
    executable = true;
  };

  home.file.".local/bin/bt-menu" = {
    source = ./files/bt-menu.sh;
    executable = true;
  };

  home.file.".local/bin/net-menu" = {
    source = ./files/net-menu.sh;
    executable = true;
  };

  home.file.".local/bin/ambient-daemon" = {
    source = ./files/ambient-daemon.py;
    executable = true;
  };

  home.file.".local/bin/claude-boot-reminder" = {
    source = ./files/claude-boot-reminder.sh;
    executable = true;
  };

  home.file.".config/wlogout/style.css.templ".source = ./files/wlogout-style.css.templ;
  home.file.".config/wlogout/icons/lock.png".source = ./files/wlogout-icons/lock.png;
  home.file.".config/wlogout/icons/logout.png".source = ./files/wlogout-icons/logout.png;
  home.file.".config/wlogout/icons/suspend.png".source = ./files/wlogout-icons/suspend.png;
  home.file.".config/wlogout/icons/reboot.png".source = ./files/wlogout-icons/reboot.png;
  home.file.".config/wlogout/icons/shutdown.png".source = ./files/wlogout-icons/shutdown.png;
  home.file.".config/wlogout/icons/hibernate.png".source = ./files/wlogout-icons/hibernate.png;
  home.file.".config/nwg-dock-hyprland/style.css.templ".source = ./files/nwg-dock-style.css.templ;
  home.file.".config/nwg-dock-hyprland/pinned" = {
    source = ./files/nwg-dock-pinned;
    force = true;
  };
  home.file.".config/OpenRGB/OpenRGB.json".source = ./files/OpenRGB.json;
  home.file.".config/gtk-3.0/settings.ini".source = ./files/gtk3-settings.ini;
  home.file.".config/gtk-4.0/settings.ini".source = ./files/gtk4-settings.ini;
  home.file.".icons/default/index.theme".source = ./files/cursor-index.theme;
  home.file.".config/qt5ct/qt5ct.conf".source = ./files/qt5ct.conf;

  xdg.desktopEntries.aniworld-gui = {
    name = "AniWorld Downloader";
    genericName = "Anime Downloader";
    comment = "Anime von AniWorld suchen und herunterladen";
    exec = "aniworld-gui";
    icon = "/etc/nixos/aniworld-gui/icon.png";
    terminal = false;
    categories = [ "AudioVideo" "Network" ];
  };

  # Persönlicher App-Shortcut für ein eigenes Projekt -- für andere Nutzer
  # ohne Bedeutung, Pfad anpassen oder diesen Eintrag einfach löschen.
  xdg.desktopEntries.magie-schmied-expo = {
    name = "Magie-Schmied Expo";
    genericName = "Expo Dev Server";
    comment = "Startet den Expo-Dev-Server fuer Magie-Schmied in kitty";
    exec = "kitty --directory ${config.home.homeDirectory}/projects/magie-schmied/mobile -e npx expo start";
    icon = "utilities-terminal";
    terminal = false;
    categories = [ "Development" ];
  };

  # Bluetooth-Kopfhörer: AVRCP-Tasten (Play/Pause/Skip/Lautstärke am Touchpad)
  # kommen über BlueZ an, ohne mpris-proxy landen sie bei keinem Player.
  systemd.user.services.mpris-proxy = {
    Unit = {
      Description = "Bluetooth AVRCP <-> MPRIS Bridge (Kopfhörer-Touchsteuerung)";
      After = [ "graphical-session.target" "bluetooth.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      Restart = "always";
      RestartSec = "1s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.ambient-daemon = {
    Unit = {
      Description = "Hyperion Ambient Light Daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "%h/.local/bin/ambient-daemon";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = "PATH=/run/current-system/sw/bin:/run/wrappers/bin:%h/.local/bin";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # War bisher von Hand unter ~/bin/ + ~/.config/systemd/user/ abgelegt (nicht
  # Nix-verwaltet) -- P2-Aufraeumrunde (sojus-core Plan 06.09.2026): jetzt
  # deklarativ wie alle anderen Skripte hier. Deaktiviert sich nach dem ersten
  # Trigger selbst (s. Skript), WantedBy sorgt aber dafuer, dass ein Rebuild
  # es nicht versehentlich wieder scharfschaltet -- das war auch beim alten,
  # von Hand gepflegten Unit schon so gewollt (einmaliger Hinweis pro echtem
  # Neustart-Zyklus, nicht pro Boot fuer immer).
  systemd.user.services.claude-boot-reminder = {
    Unit = {
      Description = "Claude Boot-Reminder — einmaliger Status-Check nach dem Login";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.local/bin/claude-boot-reminder";
      Environment = "DISPLAY=:0";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
