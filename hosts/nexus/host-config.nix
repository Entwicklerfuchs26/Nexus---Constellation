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
    commands = [
      {
        command = "/run/current-system/sw/bin/shutdown";
        options = [ "NOPASSWD" ];
      }
      # nixos-rebuild dry-run: liest nur, baut nichts, ändert nichts am System
      {
        command = "/run/current-system/sw/bin/nixos-rebuild dry-run *";
        options = [ "NOPASSWD" ];
      }
      {
        command = "/run/current-system/sw/bin/nixos-rebuild dry-run";
        options = [ "NOPASSWD" ];
      }
    ];
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

  # SSSD LDAP-Konfiguration (aus modules/core/ldap.nix ausgelagert)
  services.sssd.config = ''
    [sssd]
    domains = sternenhof.space
    services = nss, pam

    [domain/sternenhof.space]
    id_provider = ldap
    auth_provider = ldap
    ldap_uri = ldap://darwin26.sternenhof.space:389
    ldap_search_base = ou=users,dc=sternenhof,dc=space
    ldap_bind_dn = cn=admin,dc=sternenhof,dc=space
    ldap_bind_authtok_type = password
    ldap_user_object_class = inetOrgPerson
    ldap_user_name = uid
    enumerate = true
    cache_credentials = true
  '';

  # Spielefestplatte (aus modules/software/gaming.nix ausgelagert)
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/5abc4798-aa86-48c6-bf31-64206749f67d";
    fsType = "ext4";
    options = [ "defaults" "nofail" "noauto" "x-systemd.automount" "x-systemd.device-timeout=5" ];
  };

  # Hauptbenutzer (aus modules/core/users.nix ausgelagert)
  # docker-Gruppe: aus modules/software/docker.nix zusammengeführt
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
      "docker"
    ];
    shell = pkgs.bash;
  };
}
