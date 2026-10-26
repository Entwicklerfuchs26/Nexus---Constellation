{ config, pkgs, custom-fonts, ... }:

let
  userPackages = import ../../pkgs/user-packages.nix { inherit pkgs; };

  # Krita (Qt5) hat unter nativem Wayland einen bekannten Bug: externes
  # Drag & Drop aus Wayland-nativen GTK-Apps (z.B. Nautilus) kommt nicht an.
  # Fix: über XWayland laufen lassen, dort funktioniert das X11-DnD-Protokoll
  # zuverlässig (wird von Hyprland gebridget).
  krita-xwayland = pkgs.symlinkJoin {
    name = "krita-xwayland";
    paths = [ pkgs.krita ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/krita --set QT_QPA_PLATFORM xcb
    '';
  };

  # foto2mesh: Fotos im Ordner -> texturiertes 3D-Modell via Meshroom (CUDA, Docker).
  # Skript als File eingelesen -> kein Nix-${}-Escaping. Braucht virtualisation.docker.
  foto2mesh = pkgs.writeShellScriptBin "foto2mesh" (builtins.readFile ../../pkgs/foto2mesh.sh);
  foto2mesh-3dm = pkgs.writeShellScriptBin "3dm" ''exec ${foto2mesh}/bin/foto2mesh "$@"'';
in {
  # Vivaldi Managed Policy: Suchmaschinen-Vorschläge in der Adressleiste AUS.
  # Deklarativ + reinstall-fest (an beiden Vivaldi-Policy-Pfaden abgelegt).
  # Vivaldis EIGENE Adressfeld-Autovervollständigung (Verlauf/Lesezeichen) ist ein
  # Profil-Toggle (Einstellungen -> Adressleiste), nicht per Policy -> einmal manuell.
  environment.etc."vivaldi/policies/managed/nexus.json".text =
    builtins.toJSON { SearchSuggestEnabled = false; };
  environment.etc."opt/vivaldi/policies/managed/nexus.json".text =
    builtins.toJSON { SearchSuggestEnabled = false; };

  # flatpak
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "hyprland;gtk";
  };


  programs.firefox.enable = true;
  programs.kdeconnect.enable = true;

programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
    ];
  };

  environment.systemPackages = with pkgs; [
    # Browser
    vivaldi

    # Editor & Dokumente
    kdePackages.kate
    libreoffice
    kdePackages.okular

    # Dateiverwaltung
    nautilus
    nautilus-python
    file-roller
    kdePackages.ark
    xarchiver

    # Vorschaubilder in Nautilus (Video, Dokumente)
    ffmpegthumbnailer

    # Bildbetrachtung
    kdePackages.gwenview

    # Grafik & 3D
    blender
    # freecad – aus nixpkgs 26.11 (Rev 20260719) NICHT baubar: vtk-9.5.2 scheitert
    #   mit GCC 15 (vtkGDALRasterReader.cxx, CSLConstList->char**). Stattdessen per
    #   Flatpak installiert: org.freecad.FreeCAD. Wieder aktivieren, sobald nixpkgs vtk fixt.
    krita-xwayland
    darktable

    # Fotogrammetrie: Fotos -> 3D-Modell (Meshroom/CUDA via Docker)
    foto2mesh
    foto2mesh-3dm

    # Media
    vlc
    handbrake
    jellyfin-media-player

    # Musik & Spaß
    cava
    cmatrix

    # Kommunikation
    # electron_42 (aktuelles Default in nixpkgs) bricht den Splash->Main-Übergang;
    # Vesktop selbst verlangt nur ^40.4.0, daher hier explizit auf electron_40 gepinnt.
    (vesktop.override { electron_42 = electron_40; })


    # Cloud & Sync
    nextcloud-client

    # System
    htop
    fastfetch
    pavucontrol
    openrgb
    rpi-imager

    # VPN
    proton-vpn

    # Clipboard
    cliphist

    # Passwörter & Sicherheit
    bitwarden-desktop
    gnome-keyring
    seahorse

    # Entwicklung
    git
    wget
    curl
    nodejs
    termius
    tmux
    cloudflared

    # Wissensfestplatte
    kiwix-tools

    # Schriften (nur für systemPackages; für fontconfig → fonts.packages unten)
    pipewire
    wireplumber
    pulseaudio

    # GTK Theme & Icons
    adw-gtk3
    papirus-icon-theme
    bibata-cursors
    kdePackages.breeze
    kdePackages.plasma-integration
    papirus-folders
    gtk3
    pwvucontrol
    rofi

    # Qt Theming
    qt6Packages.qt6ct
    libsForQt5.qt5ct
    imagemagick

    shared-mime-info
    xdg-utils

    # iPhone
    libimobiledevice
    ifuse

    # Widgets
    eww

    # KI / AI
    claude-code

    # Python
    python3
    uv
  ] ++ userPackages;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    (pkgs.callPackage ../../pkgs/custom-fonts.nix { inherit custom-fonts; })
  ];

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "breeze";
  };

  # Maltego: Java-Detektor crasht wenn listFiles() null zurückgibt
  # /usr/lib/jvm braucht den JDK-Link, /opt braucht read-Berechtigung (war 0711)
  systemd.tmpfiles.rules = [
    "d /usr/lib/jvm 0755 root root -"
    "L+ /usr/lib/jvm/java-21-openjdk - - - - ${pkgs.jdk21}/lib/openjdk"
    "d /opt 0755 root root -"
  ];
}
