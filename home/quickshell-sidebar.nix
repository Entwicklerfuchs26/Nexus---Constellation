{ config, pkgs, ... }:
{
  home.file.".config/quickshell/nexus-sidebar/shell.qml".source = ./files/quickshell-sidebar/shell.qml;
  home.file.".config/quickshell/nexus-sidebar/Sidebar.qml".source = ./files/quickshell-sidebar/Sidebar.qml;
  home.file.".config/quickshell/nexus-sidebar/SidebarButton.qml".source = ./files/quickshell-sidebar/SidebarButton.qml;
}
