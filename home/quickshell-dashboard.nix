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
}
