{ config, pkgs, aniworld-dl-src, aniworld-gui-src, userConfig, ... }:
{
  home-manager.users.${userConfig.username} = {
    home.username = userConfig.username;
    home.homeDirectory = "/home/${userConfig.username}";
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
       settings.user.name = userConfig.gitAuthorName;
       settings.user.email = userConfig.gitAuthorEmail;
    };
    programs.bash = {
      enable = true;
      shellAliases = {
        # --update-input user-data/sojus-core zwingend: beides sind lokale
        # path:-Flake-Inputs außerhalb des Repos, die unter pure-eval NICHT
        # automatisch neu eingelesen werden -- ohne das Flag baut nixos-
        # rebuild klaglos mit stundenaltem, unsichtbar veraltetem Stand
        # (live entdeckt 14.09.2026, gleiches Muster wie das bekannte
        # sojus-core-Problem auf darwin26).
        rebuild = "nix flake update --flake /etc/nixos/nixos-config user-data sojus-core && sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#nexus";
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
