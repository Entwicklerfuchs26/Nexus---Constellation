{ config, pkgs, ... }:
{
  home.file.".config/quickshell/nexus-sidebar/shell.qml".source = ./files/quickshell-sidebar/shell.qml;
  home.file.".config/quickshell/nexus-sidebar/Sidebar.qml".source = ./files/quickshell-sidebar/Sidebar.qml;
  home.file.".config/quickshell/nexus-sidebar/SidebarButton.qml".source = ./files/quickshell-sidebar/SidebarButton.qml;
  home.file.".config/quickshell/nexus-sidebar/CredentialsLoader.qml".source = ./files/quickshell-sidebar/CredentialsLoader.qml;
  home.file.".config/quickshell/nexus-sidebar/MediaPanel.qml".source = ./files/quickshell-sidebar/MediaPanel.qml;
  home.file.".config/quickshell/nexus-sidebar/AppleMusicTab.qml".source = ./files/quickshell-sidebar/AppleMusicTab.qml;
  home.file.".config/quickshell/nexus-sidebar/JellyfinTab.qml".source = ./files/quickshell-sidebar/JellyfinTab.qml;
  home.file.".config/quickshell/nexus-sidebar/YouTubeTab.qml".source = ./files/quickshell-sidebar/YouTubeTab.qml;
  home.file.".config/quickshell/nexus-sidebar/AniListTab.qml".source = ./files/quickshell-sidebar/AniListTab.qml;
  home.file.".config/quickshell/nexus-sidebar/MpvControls.qml".source = ./files/quickshell-sidebar/MpvControls.qml;
}
