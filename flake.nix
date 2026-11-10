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

    # skwd-wall v2 (26.10.2026): kompletter Rust-Rewrite (iced+wgpu+Vulkan).
    # Der Default-Branch `v2` ist ein dünner Wrapper, der die vorgebauten,
    # GPG-signierten Binär-Pakete aus dem Branch `nix` re-exportiert
    # (packages/checks/nixosModules). Kein eigener Rust-Compile.
    # Modul: services.skwd-deck.enable (Daemon = skwd-walld, Engine = skwd-paper,
    # Suche = skwd-lens). Löst die alte QML-Generation (skwd-daemon v0.1.0) ab.
    # Der alte Vendor-Fork vendor/skwd-daemon (Zombie-Reap-Patch) ist damit
    # obsolet und nicht mehr als Input eingebunden (Ordner bleibt als Referenz).
    skwd-wall = {
      url = "github:liixini/skwd-wall";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # An Anime Game Launcher (Genshin Impact u.a.) -- deklarativ auf NixOS.
    # Spieldaten liegen bereits auf /mnt/games/AnimeGameLauncher (alte Flatpak-
    # Installation); hier kommt nur das Launcher-Programm deklarativ dazu.
    # Binärcache ezkea.cachix.org siehe modules/software/gaming.nix.
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sojus-core 20.10.2026 entfernt: die nexus-MCP-Module sind nach
    # modules/ai/sojus-mcp/ kopiert (sojus-core bleibt als Repo bestehen,
    # nexus haengt nicht mehr an /home/fuchs/sojus-core).

    # Persönliche/maschinenspezifische Werte (Username, Domains, Hardware-
    # IDs) -- bewusst außerhalb des Git-Repos unter /etc/nixos/user/, aus
    # demselben Grund wie custom-fonts/aniworld-dl-src: pure-eval liest nur
    # git-getrackte Dateien, ein gitignorter Unterordner IM Repo wäre für
    # den Flake-Build unsichtbar (siehe user/config.example.nix, INSTALL.md).
    user-data = {
      url = "path:/etc/nixos/user";
      flake = false;
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

  outputs = { self, nixpkgs, home-manager, quickshell, awww, skwd-wall, agenix, custom-fonts, aniworld-dl-src, aniworld-gui-src, user-data, ... }@inputs:
  let
    system = "x86_64-linux";

    # Persönliche Werte laufen als eigener Flake-Input rein (siehe oben),
    # damit pure-eval sie trotz gitignore lesen kann. Fehlt user-data (z.B.
    # frischer Klon ohne ausgefülltes /etc/nixos/user/), soll der Fehler
    # klar auf INSTALL.md verweisen statt kryptisch "file not found".
    userConfig =
      if builtins.pathExists (user-data + "/config.nix")
      then import (user-data + "/config.nix")
      else throw "user/config.nix fehlt -- siehe user/config.example.nix und INSTALL.md (cp nach /etc/nixos/user/config.nix)";
    userHardware =
      if builtins.pathExists (user-data + "/hardware.nix")
      then import (user-data + "/hardware.nix")
      else throw "user/hardware.nix fehlt -- siehe user/hardware.example.nix und INSTALL.md (cp nach /etc/nixos/user/hardware.nix)";
  in
  let
    # Geteilt zwischen der produktiven "nexus"-Config (512GB, ext4) und dem
    # temporären ZFS-Testinstall "nexus-1tb-test" auf der neuen 1TB-Platte
    # (Config-Trennung/Community-Install-Test, 14.09.2026) -- nur die
    # Hardware-Konfiguration + ggf. zfs-extra.nix unterscheiden sich.
    nexusCommonModules = [
        ./hosts/nexus/host-config.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit userConfig userHardware; };
        }

        skwd-wall.nixosModules.default
        agenix.nixosModules.default
        ./modules/ai/sojus-mcp/nexus/default.nix

        # Module werden hier progressiv eingebunden:
        ./modules/core/base.nix
        ./modules/core/users.nix
        ./modules/core/updates.nix
        ./modules/hardware/nvidia.nix
        ./modules/hardware/tablet.nix
        ./modules/core/printing.nix
        ./modules/core/sftp-yuki.nix
        # ./modules/core/split-tunnel-vpn.nix
        # Vorübergehend deaktiviert (12.09.2026): darwin26 hat systemweit
        # pure-eval=true gesetzt, das blockiert builtins.pathExists/readFile
        # für JEDEN Pfad außerhalb der Flake-Inputs -- das Modul liest
        # vpn-userdata/* aber genau so beim Bauen, war deshalb nie wirklich
        # aktiv (Bug live auf darwin26 entdeckt, nicht nexus-spezifisch,
        # aber nexus dürfte dieselbe Einstellung/dasselbe Problem haben).
        # Müsste auf Laufzeit-Lesen (systemd ConditionPathExists + Shell-
        # Skripte statt Nix-Eval) umgebaut werden -- Jonas hat entschieden,
        # das erstmal zurückzustellen statt jetzt umzubauen. Modul-Code
        # bleibt unverändert liegen, nur der Import ist raus.
        ./modules/software/software.nix
        ./modules/software/gaming.nix
        ./modules/software/docker.nix
        ./modules/software/davinci.nix
        ./modules/software/claude-desktop.nix
        ./modules/desktop/hyprland.nix
        ./modules/ai/ollama.nix
        ./modules/ai/sojus.nix
        ./modules/ai/sojus-ssh-logging.nix
        ./modules/ai/comfyui.nix
        ./modules/ai/chatterbox-tts.nix
        ./modules/core/ldap.nix
        ./modules/software/affinity.nix
        ./modules/software/kreativ-suite   # Adobe-Alternativen, Schalter: nexus.kreativSuite.enable
        { nexus.kreativSuite.enable = true; }   # <- auf false setzen = Suite weg
        ./modules/software/artcraft-suite   # ArtCraft (Rust-Adobe-Nachbau, Alpha), Schalter: nexus.artcraft.enable
        { nexus.artcraft.enable = true; }   # <- auf false setzen = ArtCraft weg
        ./home/home.nix
    ];
  in
  {
    # "nexus" = die aktuell aktive/primäre Maschine (seit 14.09.2026: die
    # 1TB-ZFS-Platte). WICHTIG: dieser Name muss immer zur tatsächlich
    # gebooteten Hardware passen, sonst baut/switcht man versehentlich auf
    # die falsche Festplatten-Konfiguration (genau das ist am 14.09.2026
    # passiert -- ein alter Klon ohne diese Umbenennung hat "nexus" auf die
    # ext4-Config gebaut während real schon ZFS lief, Ergebnis: kaputte
    # GUI/Treiber-Mismatch nach dem Switch).
    nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs quickshell awww skwd-wall custom-fonts aniworld-dl-src aniworld-gui-src userConfig userHardware; };
      modules = [
        ./hosts/nexus/hardware-configuration-1tb.nix
        ./hosts/nexus/zfs-extra.nix
        ./hosts/nexus/zfs-snapshot.nix
        ./hosts/nexus/skwd-project-backup.nix
        ./hosts/nexus/orbit-dev.nix
        ./hosts/nexus/wireguard-animus.nix
      ] ++ nexusCommonModules;
    };

    # Alte 512GB-ext4-Installation -- bleibt als Fallback erhalten, ist aber
    # NICHT mehr "nexus". Explizit anwählen: --flake ...#nexus-512-fallback
    nixosConfigurations.nexus-512-fallback = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs quickshell awww skwd-wall custom-fonts aniworld-dl-src aniworld-gui-src userConfig userHardware; };
      modules = [ ./hosts/nexus/hardware-configuration.nix ] ++ nexusCommonModules;
    };
  };
}
