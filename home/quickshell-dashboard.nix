{ config, pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ../pkgs/sys-fetcher.nix { }) ];

  home.file.".config/quickshell/nexus-dashboard/shell.qml".source = ./files/quickshell-dashboard/shell.qml;
  home.file.".config/quickshell/nexus-dashboard/Dashboard.qml".source = ./files/quickshell-dashboard/Dashboard.qml;
  home.file.".config/quickshell/nexus-dashboard/DashboardCard.qml".source = ./files/quickshell-dashboard/DashboardCard.qml;
  home.file.".config/quickshell/nexus-dashboard/ClockWidget.qml".source = ./files/quickshell-dashboard/ClockWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/WeatherWidget.qml".source = ./files/quickshell-dashboard/WeatherWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/CredentialsLoader.qml".source = ./files/quickshell-dashboard/CredentialsLoader.qml;
  home.file.".config/quickshell/nexus-dashboard/CalendarWidget.qml".source = ./files/quickshell-dashboard/CalendarWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/TasksWidget.qml".source = ./files/quickshell-dashboard/TasksWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/TaskRow.qml".source = ./files/quickshell-dashboard/TaskRow.qml;
  home.file.".config/quickshell/nexus-dashboard/NewsHubWidget.qml".source = ./files/quickshell-dashboard/NewsHubWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/DiskWidget.qml".source = ./files/quickshell-dashboard/DiskWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/UpdateWidget.qml".source = ./files/quickshell-dashboard/UpdateWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/AgentsWidget.qml".source = ./files/quickshell-dashboard/AgentsWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/SkillTreeWidget.qml".source = ./files/quickshell-dashboard/SkillTreeWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/ActivityWidget.qml".source = ./files/quickshell-dashboard/ActivityWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/LiquidSquare.qml".source = ./files/quickshell-dashboard/LiquidSquare.qml;
  home.file.".config/quickshell/nexus-dashboard/SystemUsageWidget.qml".source = ./files/quickshell-dashboard/SystemUsageWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/ClipboardWidget.qml".source = ./files/quickshell-dashboard/ClipboardWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/QuickToolsWidget.qml".source = ./files/quickshell-dashboard/QuickToolsWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/NowPlayingWidget.qml".source = ./files/quickshell-dashboard/NowPlayingWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/SojusChatWidget.qml".source = ./files/quickshell-dashboard/SojusChatWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/FocusStatBox.qml".source = ./files/quickshell-dashboard/FocusStatBox.qml;
  home.file.".config/quickshell/nexus-dashboard/FocusBarChart.qml".source = ./files/quickshell-dashboard/FocusBarChart.qml;
  home.file.".config/quickshell/nexus-dashboard/FocusTimeWidget.qml".source = ./files/quickshell-dashboard/FocusTimeWidget.qml;
}
