{
  description = "Nexus NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
    };

    # Lokal gepatcht (Zombie-Reap-Fix für ManagedProcess, siehe vendor/skwd-daemon/PATCHES.md)
    # statt github:liixini/skwd-daemon — Rev 36f165a68611dfc55f1878ddd34491cdb6e22a44 + Patch.
    skwd-daemon = {
      url = "path:./vendor/skwd-daemon";
    };

    skwd-wall = {
      url = "github:liixini/skwd-wall";
      inputs.skwd-daemon.follows = "skwd-daemon";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sojus-core = {
      url = "path:/home/fuchs/sojus-core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Persönliche Font-Sammlung, bewusst außerhalb des Git-Repos (teils
    # kommerzielle Fonts, dürfen nicht ins öffentliche GitHub-Repo).
    custom-fonts = {
      url = "path:/etc/nixos/local-fonts";
      flake = false;
    };

    # AniDL-Scraper-Engine (AniO), bewusst außerhalb des Git-Repos — Scraper-
    # Code, nicht für das öffentliche GitHub-Repo geeignet.
    aniworld-dl-src = {
      url = "path:/etc/nixos/local-scripts/aniworld-dl";
      flake = false;
    };

    # AniWorld Downloader GUI (Tkinter + Web), aus gleichem Grund außerhalb
    # des Git-Repos.
    aniworld-gui-src = {
      url = "path:/etc/nixos/aniworld-gui";
      flake = false;
    };

    # TODO: KI-Repo — eigene KI-Tooling / Automatisierungs-Module
    # ki-modules.url = "github:Entwicklerfuchs26/ki-modules";
  };

  outputs = { self, nixpkgs, home-manager, quickshell, awww, skwd-daemon, skwd-wall, agenix, sojus-core, custom-fonts, aniworld-dl-src, aniworld-gui-src, ... }@inputs:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs quickshell awww skwd-daemon skwd-wall custom-fonts aniworld-dl-src aniworld-gui-src; };
      modules = [
        ./hosts/nexus/hardware-configuration.nix
        ./hosts/nexus/host-config.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

        skwd-wall.nixosModules.default
        agenix.nixosModules.default
        sojus-core.nixosModules.nexus

        # Module werden hier progressiv eingebunden:
        ./modules/core/base.nix
        ./modules/core/users.nix
        ./modules/hardware/nvidia.nix
        ./modules/hardware/tablet.nix
        ./modules/core/printing.nix
        ./modules/core/sftp-yuki.nix
        ./modules/software/software.nix
        ./modules/software/gaming.nix
        ./modules/software/docker.nix
        ./modules/software/davinci.nix
        ./modules/desktop/hyprland.nix
        ./modules/ai/ollama.nix
        ./modules/ai/sojus.nix
        ./modules/ai/sojus-ssh-logging.nix
        ./modules/ai/comfyui.nix
        ./modules/ai/chatterbox-tts.nix
        ./modules/core/ldap.nix
        ./modules/software/affinity.nix
        ./home/home.nix
      ];
    };

    nixosConfigurations.nous = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/nous/hardware-configuration.nix
        ./hosts/nous/host-config.nix

        ./modules/core/users.nix
        ./modules/hardware/amd-strix-halo.nix
        ./modules/ai/ollama-vulkan.nix
        ./modules/ai/llama-swap.nix
      ];
    };
  };
}
