# Nautilus/GTK-Desktop-Einstellungen, 1:1 von der alten 512GB-Installation
# übernommen (per dconf-Profile-Trick ausgelesen, 15.09.2026) und diesmal
# reproduzierbar deklariert statt nur im Nutzerprofil gewachsen.
{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    whitesur-icon-theme
    whitesur-gtk-theme
    whitesur-cursors
    papirus-icon-theme
    tela-icon-theme
    tela-circle-icon-theme
    layan-gtk-theme
    noto-fonts
    hack-font
  ];

  fonts.fontconfig.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "WhiteSur-cursors";
      cursor-size = 24;
      icon-theme = "WhiteSur-dark";
      font-name = "Noto Sans 10";
      document-font-name = "Noto Sans 10";
      monospace-font-name = "Hack 10";
      toolbar-style = "text";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "icon:minimize,maximize,close";
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "small-plus";
    };
    "org/gnome/nautilus/list-view" = {
      default-zoom-level = "medium";
      use-tree-view = true;
    };
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      show-create-link = true;
    };
    "org/gnome/nautilus/window-state" = {
      maximized = true;
    };

    "org/gtk/settings/file-chooser" = {
      show-hidden = true;
      show-size-column = true;
      show-type-column = true;
      sort-directories-first = false;
      sort-column = "name";
      sort-order = "ascending";
      location-mode = "path-bar";
      date-format = "regular";
      type-format = "category";
    };
    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = true;
    };
  };

  # GTK-Sidebar-Lesezeichen. Die generischen (Desktop/Documents/...) passen
  # für jeden Nutzer; die persönlichen (Nextcloud/Projekte/Yuki-Mount) sind
  # 1:1 von der alten Platte übernommen -- zeigen erst was an sobald die
  # jeweiligen Ordner/Mounts wieder existieren, sind bis dahin harmlos
  # ausgegraut. Bei Bedarf hier anpassen/entfernen.
  home.file.".config/gtk-3.0/bookmarks".text = ''
    file://${config.home.homeDirectory}/Desktop Desktop
    file://${config.home.homeDirectory}/Documents Documents
    file://${config.home.homeDirectory}/Downloads Downloads
    file://${config.home.homeDirectory}/Pictures Pictures
    file://${config.home.homeDirectory}/Videos Videos
    file:///etc/nixos nixos
    file:/// /
    file://${config.home.homeDirectory}/Nextcloud Nextcloud
    file://${config.home.homeDirectory}/.local/share/PrismLauncher/instances Prism
    file:///tmp/iphone iphone
    file://${config.home.homeDirectory}/projects/WP_Wietes_Feld WP_Wietes_Feld
    file:///mnt/yuki Yuki (Minecraft Server)
  '';
}
