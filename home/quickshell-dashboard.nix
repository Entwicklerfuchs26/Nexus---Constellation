{ config, pkgs, ... }:
{
  home.file.".config/quickshell/nexus-dashboard/shell.qml".source = ./files/quickshell-dashboard/shell.qml;
  home.file.".config/quickshell/nexus-dashboard/Dashboard.qml".source = ./files/quickshell-dashboard/Dashboard.qml;
  home.file.".config/quickshell/nexus-dashboard/DashboardCard.qml".source = ./files/quickshell-dashboard/DashboardCard.qml;
  home.file.".config/quickshell/nexus-dashboard/DonutRing.qml".source = ./files/quickshell-dashboard/DonutRing.qml;
  home.file.".config/quickshell/nexus-dashboard/ClockWidget.qml".source = ./files/quickshell-dashboard/ClockWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/WeatherWidget.qml".source = ./files/quickshell-dashboard/WeatherWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/SystemMonitorWidget.qml".source = ./files/quickshell-dashboard/SystemMonitorWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/CredentialsLoader.qml".source = ./files/quickshell-dashboard/CredentialsLoader.qml;
  home.file.".config/quickshell/nexus-dashboard/CalendarWidget.qml".source = ./files/quickshell-dashboard/CalendarWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/TasksWidget.qml".source = ./files/quickshell-dashboard/TasksWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/TaskRow.qml".source = ./files/quickshell-dashboard/TaskRow.qml;
  home.file.".config/quickshell/nexus-dashboard/NewsHubWidget.qml".source = ./files/quickshell-dashboard/NewsHubWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/NetworkWidget.qml".source = ./files/quickshell-dashboard/NetworkWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/DiskWidget.qml".source = ./files/quickshell-dashboard/DiskWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/UpdateWidget.qml".source = ./files/quickshell-dashboard/UpdateWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/AgentsWidget.qml".source = ./files/quickshell-dashboard/AgentsWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/SkillTreeWidget.qml".source = ./files/quickshell-dashboard/SkillTreeWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/ActivityWidget.qml".source = ./files/quickshell-dashboard/ActivityWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/ClipboardWidget.qml".source = ./files/quickshell-dashboard/ClipboardWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/QuickToolsWidget.qml".source = ./files/quickshell-dashboard/QuickToolsWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/NowPlayingWidget.qml".source = ./files/quickshell-dashboard/NowPlayingWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/SojusChatWidget.qml".source = ./files/quickshell-dashboard/SojusChatWidget.qml;
}
