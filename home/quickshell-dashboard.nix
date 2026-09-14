{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.callPackage ../pkgs/sys-fetcher.nix { })
    # SojusChatWidget: websocat haelt die WS-Verbindung zum sojus-api-Backend
    # (Quickshell/Qt hat kein natives WebSocket-QML-Element), zenity liefert
    # den Datei-Picker fuer den Anhang-Upload.
    pkgs.websocat
    pkgs.zenity
  ];

  home.file.".config/quickshell/nexus-dashboard/shell.qml".source = ./files/quickshell-dashboard/shell.qml;
  home.file.".config/quickshell/nexus-dashboard/Dashboard.qml".source = ./files/quickshell-dashboard/Dashboard.qml;
  home.file.".config/quickshell/nexus-dashboard/DashboardCard.qml".source = ./files/quickshell-dashboard/DashboardCard.qml;
  # .text statt .source: enthält einen absoluten /home/fuchs-Pfad, per
  # replaceStrings generisch für den tatsächlichen Home-Ordner gemacht.
  home.file.".config/quickshell/nexus-dashboard/CredentialsLoader.qml".text =
    builtins.replaceStrings [ "/home/fuchs" ] [ config.home.homeDirectory ]
      (builtins.readFile ./files/quickshell-dashboard/CredentialsLoader.qml);
  home.file.".config/quickshell/nexus-dashboard/CalendarWidget.qml".source = ./files/quickshell-dashboard/CalendarWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/VikunjaTasksWidget.qml".source = ./files/quickshell-dashboard/VikunjaTasksWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/VikunjaTaskRow.qml".source = ./files/quickshell-dashboard/VikunjaTaskRow.qml;
  home.file.".config/quickshell/nexus-dashboard/NewsHubWidget.qml".source = ./files/quickshell-dashboard/NewsHubWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/DiskWidget.qml".source = ./files/quickshell-dashboard/DiskWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/UpdateWidget.qml".source = ./files/quickshell-dashboard/UpdateWidget.qml;
  home.file.".config/quickshell/nexus-dashboard/AgentsWidget.qml".source = ./files/quickshell-dashboard/AgentsWidget.qml;
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
