{ pkgs, ... }:

{
  # Screen-Coach: Hotkey (Super + Taste links der 1) -> Screenshot -> KI
  # findet den Klickpunkt -> quickshell-Overlay malt Ring/Pfeil/Textblase
  # dorthin -> TTS spricht (best-effort). Das "Auge" ist heute der claude-CLI
  # und ueber $SCREEN_COACH_BRAIN austauschbar (Ziel: lokaler Sojus-VLM).
  # Der Keybind steht in home/files/hyprland.conf.

  home.packages = with pkgs; [
    grim   # Screenshot (Wayland)
    rofi   # Aufgaben-Eingabe
  ];

  home.file.".local/bin/screen-coach" = {
    source = ./files/screen-coach/screen-coach;
    executable = true;
  };
  home.file.".local/bin/screen-coach-brain-claude" = {
    source = ./files/screen-coach/screen-coach-brain-claude;
    executable = true;
  };
  home.file.".config/screen-coach/shell.qml".source =
    ./files/screen-coach/shell.qml;
}
