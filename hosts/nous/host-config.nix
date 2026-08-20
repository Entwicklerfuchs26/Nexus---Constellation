# Host-spezifische Konfiguration für nous (GMKtec EVO-X2, AMD Ryzen AI Max+ 395)
# NICHT ins public repo committen ohne Bereinigung (Hostname, UUIDs, ...)
{ config, pkgs, ... }:

{
  networking.hostName = "nous";
  networking.networkmanager.enable = true;

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

  users.users.fuchs = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfUnITva1UT6s0l5G/UhM3pjYxz1UJMgZmp6miGY9Na nexus"
    ];
    initialPassword = "changeme";
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
