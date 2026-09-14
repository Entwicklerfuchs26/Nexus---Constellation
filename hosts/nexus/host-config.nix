# Host-Konfiguration für nexus. Alle persönlichen/maschinenspezifischen
# Werte kommen aus userConfig/userHardware (siehe /etc/nixos/user/,
# eingebunden als Flake-Input "user-data" in flake.nix) -- diese Datei
# selbst ist community-tauglich und kann committet werden.
{ config, lib, pkgs, userConfig, userHardware, ... }:

{
  networking.hostName = userConfig.hostName;

  # ZFS-Kernelmodul verfügbar machen (für den 1TB-Umzug -- braucht das
  # Modul auf dem LAUFENDEN System, nicht nur im Zielsystem, sonst schlägt
  # `zpool create` mit "ZFS modules cannot be auto-loaded" fehl, siehe
  # INSTALL.md/Vikunja #ZFS-Umzug 14.09.2026). Harmlos additiv, root bleibt
  # ext4 -- kann drinbleiben.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = userHardware.zfsHostId;

  networking.interfaces.${userHardware.networkInterface} = {
    wakeOnLan.enable = true;
  };

  security.sudo.extraRules = [{
    users = [ userConfig.username ];
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
  security.pki.certificateFiles = [ ../../certs/sternenhof-ca-2026.crt ];

  networking.hosts = lib.optionalAttrs (userConfig.baseDomain != "") {
    "${userConfig.homeserverIp}" = map (sub: "${sub}.${userConfig.baseDomain}") [
      "cloud"
      "n8n"
      "media"
      "photos"
      "tasks"
      "home"
      "ntfy"
      "zugang"
      "darwin26"
      "sojus"
      "comfyui"
    ];
  };

  # Bluetooth-Headset: A2DP-Profil erzwingen (nur falls konfiguriert)
  services.pipewire.wireplumber.extraConfig = lib.optionalAttrs (userHardware.bluetooth ? boseHeadsetMac) {
    "51-bluez-headset-a2dp" = {
      "monitor.bluez.rules" = [
        {
          matches = [
            { "device.name" = "bluez_card.${userHardware.bluetooth.boseHeadsetMac}"; }
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
  };

  # 1 TB Datenfestplatte (ext4)
  # Kein x-systemd.automount mehr: der autofs-Stub liess Steams bwrap-Sandbox
  # abstuerzen ("No such device"), sobald die Platte nicht angeschlossen war
  # (sie versucht /mnt komplett zu binden und stolpert dabei ueber den
  # haengenden Mountpoint). Bei angeschlossener Platte manuell mounten:
  # sudo mount /mnt/data
  fileSystems."/mnt/data" = lib.mkIf (userHardware.disks ? dataUuid) {
    device = "/dev/disk/by-uuid/${userHardware.disks.dataUuid}";
    fsType = "ext4";
    options = [ "defaults" "nofail" "noauto" ];
  };

  networking.firewall.allowedTCPPorts = [ 8080 8081 8888 7777 ];

  # SSSD LDAP-Konfiguration (aus modules/core/ldap.nix ausgelagert)
  services.sssd.config = lib.mkIf userConfig.ldap.enable ''
    [sssd]
    domains = ${userConfig.ldap.domain}
    services = nss, pam

    [domain/${userConfig.ldap.domain}]
    id_provider = ldap
    auth_provider = ldap
    ldap_uri = ${userConfig.ldap.uri}
    ldap_search_base = ${userConfig.ldap.searchBase}
    ldap_bind_dn = ${userConfig.ldap.bindDn}
    ldap_bind_authtok_type = password
    ldap_user_object_class = inetOrgPerson
    ldap_user_name = uid
    enumerate = true
    cache_credentials = true
  '';

  # Spielefestplatte (aus modules/software/gaming.nix ausgelagert)
  fileSystems."/mnt/games" = lib.mkIf (userHardware.disks ? gamesUuid) {
    device = "/dev/disk/by-uuid/${userHardware.disks.gamesUuid}";
    fsType = "ext4";
    options = [ "defaults" "nofail" "noauto" "x-systemd.automount" "x-systemd.device-timeout=5" ];
  };

  # Samba-Freigabe für Netzwerk-Scan (Epson "Scan to Folder"): Drucker legt
  # gescannte Dateien direkt in ~/Documents ab. Passwort separat per
  # `sudo smbpasswd -a <username>` setzen (nicht das Login-PW).
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = userConfig.hostName;
        "netbios name" = userConfig.hostName;
        "security" = "user";
        "map to guest" = "never";
      };
      scans = {
        "path" = "/home/${userConfig.username}/Documents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = userConfig.username;
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # Hauptbenutzer (aus modules/core/users.nix ausgelagert)
  # docker-Gruppe: aus modules/software/docker.nix zusammengeführt
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.fullName;
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
