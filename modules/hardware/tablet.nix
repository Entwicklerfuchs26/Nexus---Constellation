{ ... }:
{
  # XP-Pen Artist 22 (2nd Gen) — XP-Pen liefert keinen nativen Linux-Treiber.
  # OpenTabletDriver deckt das Gerät ab (Configs/XP-Pen/Artist 22 (2nd Gen).json)
  # und läuft nativ unter Wayland/Hyprland.
  hardware.opentabletdriver = {
    enable = true;
    # graphical-session.target wird auf diesem System nie automatisch aktiviert
    # (siehe hyprland.conf-Kommentar bei skwd-daemon) — der systemd-User-Service
    # würde daher nie starten. Autostart stattdessen über exec-once.
    daemon.enable = false;
  };
}
