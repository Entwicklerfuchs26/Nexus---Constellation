{ config, pkgs, lib, quickshell, awww, skwd-daemon, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = false;
  };

services.displayManager.sddm = {
  enable = true;
  wayland.enable = true;
  theme = "sddm-astronaut-theme";
};
services.displayManager.defaultSession = "hyprland";

  services.xserver = {
    enable = true;
    xkb.layout = "de";
    xkb.variant = "";
  };

  console.keyMap = "de";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    linux-wallpaperengine
    hyprlock
    hypridle
    awww.packages.${pkgs.system}.default
    waybar
    nwg-displays
    wofi
    kitty
    swaynotificationcenter
    libnotify
    wl-clipboard
    brightnessctl
    playerctl
    mpvpaper
    wlogout
    networkmanagerapplet
    xdg-desktop-portal-hyprland
    grim
    slurp
    grimblast
    hyprpicker
    yt-dlp
    mpv
    socat
    polkit_gnome
    quickshell.packages.x86_64-linux.default
    qt6.qtmultimedia
    kdePackages.sddm-kcm
    sddm-astronaut
    kdePackages.kirigami
    kdePackages.qqc2-breeze-style
    qt6.qtimageformats
    # ComponentBubble im Sojus Chat (SojusChatWidget.qml) — rendert von Hermes
    # generierte React/Recharts-Grafiken lokal per WebEngineView. Live unter
    # Hyprland+NVIDIA(RTX 2070, Treiber 595.84) getestet, läuft stabil ohne
    # GPU-Crashes; QTWEBENGINE_DISABLE_SANDBOX unten ist auf NixOS der
    # übliche Workaround, weil der Chromium-Sandbox-Helper hier nicht
    # setuid-root installiert ist (kein Sicherheitsproblem für uns, da nur
    # lokal generierter file://-Inhalt ohne Netzwerkzugriff geladen wird).
    qt6.qtwebengine
  ];

environment.sessionVariables = {
  QML2_IMPORT_PATH = "${pkgs.kdePackages.kirigami}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtwebengine}/lib/qt-6/qml";
  XDG_CURRENT_DESKTOP = "Hyprland";
  QTWEBENGINE_DISABLE_SANDBOX = "1";
};

environment.etc."sddm.conf.d/theme.conf".text = ''
  [Theme]
  Current=sddm-astronaut-theme
  ThemeDir=/run/current-system/sw/share/sddm/themes
  CursorTheme=Bibata-Modern-Classic
  CursorSize=24
'';

environment.etc."sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf".text = ''
  [General]
  Background="Backgrounds/astronaut.png"
  DimBackground="0.3"
  PartialBlur="true"
  FormPosition="center"
  HourFormat="HH:mm"
  DateFormat="dddd d. MMMM"
  Font="JetBrains Mono"
  RoundCorners="20"
  ForceLastUser="true"
  PasswordFocus="true"
  HideCompletePassword="true"
  TranslateLogin="Anmelden"
  TranslateReboot="Neustart"
  TranslateShutdown="Herunterfahren"
  TranslateSuspend="Ruhezustand"
'';


programs.skwd-wall.enable = true;

}
