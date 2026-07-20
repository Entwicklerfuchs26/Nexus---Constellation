{
  description = "Nexus NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: quickshell — Wayland shell framework
    # quickshell.url = "github:quickshell-de/quickshell";

    # TODO: skwd-daemon — Wallpaper/scene daemon (skwd-wall)
    # skwd-daemon.url = "github:yourorg/skwd-daemon";

    # TODO: awww — Wayland widget system
    # awww.url = "github:elkowar/eww";

    # TODO: KI-Repo — eigene KI-Tooling / Automatisierungs-Module
    # ki-modules.url = "github:Entwicklerfuchs26/ki-modules";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        # TODO: host-spezifische Konfiguration einbinden
        # ./hosts/nexus/configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # TODO: Home-Manager-Konfiguration einbinden
          # home-manager.users.fuchs = import ./home/fuchs.nix;
        }
      ];
    };
  };
}
