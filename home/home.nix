{ config, pkgs, aniworld-dl-src, aniworld-gui-src, ... }:
{
  home-manager.users.fuchs = {
    home.username = "fuchs";
    home.homeDirectory = "/home/fuchs";
    home.stateVersion = "25.11";
    home.sessionVariables = {
      PATH = "$HOME/.local/bin:$PATH";
    };
    imports = [
      ./hyprland.nix
      ./waybar.nix
      ./kitty.nix
      ./matugen.nix
      ./desktop.nix
      ./rofi.nix
      ./mimeapps.nix
      ./theme-schedule.nix
      ./quickshell-sidebar.nix
      ./quickshell-dashboard.nix
      ./activitywatch.nix
      ./focustime.nix
      ./nexus-eq.nix
      ./headphone-limiter.nix
      ./chatterbox-tts.nix
    ];
    home.packages = with pkgs; [
      vivaldi
      obsidian
      vscode
      matugen
      mission-center
      (pkgs.callPackage ../pkgs/aniworld-dl.nix { inherit aniworld-dl-src; })
      (pkgs.callPackage ../pkgs/anime-organizer.nix { })
      (pkgs.callPackage ../pkgs/nix-manager.nix { })
      (pkgs.callPackage ../pkgs/aniworld-gui.nix { inherit aniworld-gui-src; })
      (pkgs.callPackage ../pkgs/aniworld-web.nix { inherit aniworld-gui-src; })
    ];
    programs.git = {
      enable = true;
       settings.user.name = "Entwicklerfuchs26";
       settings.user.email = "jonas@hofpause.info";
    };
    programs.bash = {
      enable = true;
      shellAliases = {
        rebuild = "sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#nexus";
        update = "sudo nix flake update /etc/nixos";
        config = "cd /etc/nixos";
        ssh = "TERM=xterm-256color ssh -t";
      };
      initExtra = ''
        if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
          export TERM=xterm-256color
       fi
      '';
    };
  };
}
