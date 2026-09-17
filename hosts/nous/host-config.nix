# Host-spezifische Konfiguration für nous (GMKtec EVO-X2, AMD Ryzen AI Max+ 395)
# NICHT ins public repo committen ohne Bereinigung (Hostname, UUIDs, ...)
{ config, pkgs, ... }:

{
  networking.hostName = "nous";
  networking.useDHCP = false;
  networking.interfaces.eno1.ipv4.addresses = [{
    address = "192.168.1.25";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "192.168.1.26" ];

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Kein boot.kernelPackages-Pin wie bei nexus (linuxPackages_6_12) — nous braucht
  # Kernel >=6.16.9 für gfx1151-Support, der nixpkgs-Default ist bereits neu genug.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  zramSwap.enable = true;

  # ZFS für die per Thunderbolt angeschlossene OWC ThunderBay 4 (4x4TB,
  # RAIDZ2) -- Immich/Jellyfin/Nextcloud-Datenspeicher, wird später zu
  # darwin26 umgesteckt (Pool ist portabel: zpool export/import).
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "aee78328";
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  users.users.fuchs = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfUnITva1UT6s0l5G/UhM3pjYxz1UJMgZmp6miGY9Na nexus"
    ];
    # Passwort wurde am 20.08.2026 manuell per chpasswd gesetzt (initialPassword
    # "changeme" nur für den allerersten Boot verwendet) — nicht Nix-verwaltet,
    # bei Bedarf lokal mit `passwd` ändern.
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];

  networking.firewall.allowedTCPPorts = [ 22 11434 ];

  system.stateVersion = "26.05";
}
