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

    skwd-daemon = {
      url = "github:liixini/skwd-daemon";
    };

    skwd-wall = {
      url = "github:liixini/skwd-wall";
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

    # TODO: KI-Repo — eigene KI-Tooling / Automatisierungs-Module
    # ki-modules.url = "github:Entwicklerfuchs26/ki-modules";
  };

  outputs = { self, nixpkgs, home-manager, quickshell, awww, skwd-daemon, skwd-wall, agenix, sojus-core, ... }@inputs:
  let
    system = "x86_64-linux";
  in
  {
    nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs quickshell awww skwd-daemon skwd-wall; };
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
        ./modules/core/printing.nix
        ./modules/software/software.nix
        ./modules/software/gaming.nix
        ./modules/software/docker.nix
        ./modules/software/davinci.nix
        ./modules/desktop/hyprland.nix
        ./modules/ai/ollama.nix
        ./modules/ai/sojus.nix
        # Pausiert 2026-07-23: fraßen zusammen ~6,7GB von 8GB VRAM im Leerlauf
        # (RTX 2070, 8GB). Voice-Layer-Integration läuft jetzt über Hermes statt
        # sojus-pipeline.py — wieder einkommentieren sobald die Anbindung steht.
        # ./modules/ai/chatterbox-tts.nix
        # ./modules/ai/whisper-stt.nix
        ./modules/core/ldap.nix
        ./modules/software/affinity.nix
        ./home/home.nix
      ];
    };
  };
}
