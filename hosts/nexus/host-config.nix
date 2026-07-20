# Host-spezifische Konfiguration – NICHT ins public repo committen ohne Bereinigung
# (Hostname, MACs, UUIDs, interne Domains, Zertifikatspfade)
{ config, pkgs, ... }:

{
  networking.hostName = "nexus";

  networking.interfaces.enp5s0 = {
    wakeOnLan.enable = true;
  };

  security.sudo.extraRules = [{
    users = [ "fuchs" ];
    commands = [{
      command = "/run/current-system/sw/bin/shutdown";
      options = [ "NOPASSWD" ];
    }];
  }];

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  # Sternenhof Root-CA – Pfad muss auf lokale certs/ im Config-Repo zeigen
  # security.pki.certificateFiles = [ ./certs/sternenhof-ca-2026.crt ];

  networking.hosts = {
    "192.168.1.26" = [
      "cloud.sternenhof.space"
      "n8n.sternenhof.space"
      "media.sternenhof.space"
      "photos.sternenhof.space"
      "tasks.sternenhof.space"
      "home.sternenhof.space"
      "ntfy.sternenhof.space"
      "zugang.sternenhof.space"
      "darwin26.sternenhof.space"
      "sojus.sternenhof.space"
    ];
  };

  # Bose Bluetooth-Headset: A2DP-Profil erzwingen
  services.pipewire.wireplumber.extraConfig."51-bluez-bose-a2dp" = {
    "monitor.bluez.rules" = [
      {
        matches = [
          { "device.name" = "bluez_card.7C_96_D2_77_56_7E"; }
        ];
        actions = {
          update-props = {
            "bluez5.auto-connect" = [ "a2dp_sink" ];
            "device.profile" = "a2dp-sink";
          };
        };
      }
    ];
  };

  # 1 TB Datenfestplatte (ext4)
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/299df179-7040-42b8-a6f0-548247cc82f6";
    fsType = "ext4";
    options = [ "defaults" "nofail" "x-systemd.automount" ];
  };

  networking.firewall.allowedTCPPorts = [ 8080 8081 8888 7777 ];

  # Hauptbenutzer (aus modules/core/users.nix ausgelagert)
  users.users.fuchs = {
    isNormalUser = true;
    description = "Entwicklerfuchs";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "bluetooth"
      "i2c"
    ];
    shell = pkgs.bash;
  };
}
