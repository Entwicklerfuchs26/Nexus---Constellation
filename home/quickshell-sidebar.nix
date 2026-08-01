{ config, pkgs, ... }:
{
  home.file.".config/quickshell/nexus-sidebar/shell.qml".source = ./files/quickshell-sidebar/shell.qml;
  home.file.".config/quickshell/nexus-sidebar/Sidebar.qml".source = ./files/quickshell-sidebar/Sidebar.qml;
  home.file.".config/quickshell/nexus-sidebar/SidebarButton.qml".source = ./files/quickshell-sidebar/SidebarButton.qml;
  home.file.".config/quickshell/nexus-sidebar/CredentialsLoader.qml".source = ./files/quickshell-sidebar/CredentialsLoader.qml;
  home.file.".config/quickshell/nexus-sidebar/MediaPanel.qml".source = ./files/quickshell-sidebar/MediaPanel.qml;
  home.file.".config/quickshell/nexus-sidebar/MpvControls.qml".source = ./files/quickshell-sidebar/MpvControls.qml;
  home.file.".config/quickshell/nexus-sidebar/EqualizerTab.qml".source = ./files/quickshell-sidebar/EqualizerTab.qml;
  home.file.".config/quickshell/nexus-sidebar/EqSlider.qml".source = ./files/quickshell-sidebar/EqSlider.qml;
  home.file.".config/quickshell/nexus-sidebar/NowPlayingHeader.qml".source = ./files/quickshell-sidebar/NowPlayingHeader.qml;
}
